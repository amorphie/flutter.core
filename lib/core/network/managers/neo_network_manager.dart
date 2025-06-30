/*
 * neo_core
 *
 * Created on 19/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';
import 'package:mutex/mutex.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/headers/mtls_headers.dart';
import 'package:neo_core/core/network/headers/neo_constant_headers.dart';
import 'package:neo_core/core/network/headers/neo_dynamic_headers.dart';
import 'package:neo_core/core/network/helpers/mtls_helper.dart';
import 'package:neo_core/core/network/models/http_auth_response.dart';
import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';
import 'package:neo_core/core/util/token_util.dart';
import 'package:neo_core/core/util/uuid_util.dart';
import 'package:neo_core/neo_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_io/io.dart';

abstract class _Constants {
  static const int responseCodeUnauthorized = 401;
  static const String wrapperResponseKey = "data";
  static const String endpointGetToken = "get-token";
  static const String requestKeyClientId = "client_id";
  static const String requestKeyClientSecret = "client_secret";
  static const String requestKeyGrantType = "grant_type";
  static const String requestValueGrantTypeRefreshToken = "refresh_token";
  static const String requestValueGrantTypeClientCredentials = "client_credentials";
  static const String requestKeyRefreshToken = "refresh_token";
  static const String requestKeyScopes = "scopes";
  static const List<String> requestValueScopes = ["retail-customer"];
}

enum NeoNetworkManagerLogScale { none, simplified, all }

class NeoNetworkManager {
  final HttpClientConfig httpClientConfig;
  final NeoCoreSecureStorage secureStorage;
  final NeoSharedPrefs neoSharedPrefs;
  final String workflowClientId;
  final String workflowClientSecret;
  final List<String> sslCertificateFilePaths;
  final Function(String endpoint, String? requestId)? onRequestSucceed;
  final Function(NeoError neoError, String requestId)? onRequestFailed;
  final Function()? onInvalidTokenError;
  final NeoNetworkManagerLogScale logScale;
  final Map<String, String> defaultHeaders;
  final Duration timeoutDuration;

  late final bool _enableSslPinning;

  bool get _isMtlsEnabled => !kIsWeb && httpClientConfig.config.enableMtls;

  DateTime? _tokenExpirationTime;
  DateTime? _refreshTokenExpirationTime;
  HttpAuthResponse? _lastAuthResponse;

  final _tokenLock = Mutex();
  Completer? _tokenLockCompleter;

  bool get isTokenExpired => _tokenExpirationTime != null && DateTime.now().isAfter(_tokenExpirationTime!);

  bool get isRefreshTokenExpired =>
      _refreshTokenExpirationTime != null && DateTime.now().isAfter(_refreshTokenExpirationTime!);

  http.Client? httpClient;

  late final MtlsHelper _mtlsHelper = MtlsHelper();
  late final MtlsHeaders _mtlsHeaders = MtlsHeaders(secureStorage: secureStorage);

  NeoNetworkManager({
    required this.httpClientConfig,
    required this.secureStorage,
    required this.neoSharedPrefs,
    required this.workflowClientId,
    required this.workflowClientSecret,
    this.sslCertificateFilePaths = const [],
    this.onRequestSucceed,
    this.onRequestFailed,
    this.onInvalidTokenError,
    this.logScale = NeoNetworkManagerLogScale.simplified,
    this.defaultHeaders = const {},
    this.timeoutDuration = const Duration(minutes: 1),
  });

  NeoLogger? get _neoLogger => GetIt.I.getIfReady<NeoLogger>();

  int? get tokenExpiresInSeconds => _lastAuthResponse?.expiresInSeconds;

  late final NeoConstantHeaders neoConstantHeaders = NeoConstantHeaders(
    neoSharedPrefs: neoSharedPrefs,
    secureStorage: secureStorage,
    defaultHeaders: defaultHeaders,
  );

  Future<void> init({required bool enableSslPinning}) async {
    _enableSslPinning = enableSslPinning;
    await _initHttpClient();
    await getTemporaryTokenForNotLoggedInUser();
  }

  Future<Map<String, String>> _getDefaultHeaders(NeoHttpCall? neoCall) async {
    return await NeoDynamicHeaders(neoSharedPrefs: neoSharedPrefs, secureStorage: secureStorage).getHeaders()
      ..addAll(
        _isMtlsEnabled && (neoCall?.signForMtls ?? false) ? await _mtlsHeaders.getHeaders(neoCall?.body ?? {}) : {},
      )
      ..addAll(
        await NeoConstantHeaders(
          neoSharedPrefs: neoSharedPrefs,
          secureStorage: secureStorage,
          defaultHeaders: defaultHeaders,
        ).getHeaders(),
      );
  }

  Future<Map<String, String>> _getDefaultPostHeaders(NeoHttpCall neoCall) async => <String, String>{}
    ..addAll(await _getDefaultHeaders(neoCall))
    ..addAll({
      NeoNetworkHeaderKey.user: UuidUtil.generateUUID(), // STOPSHIP: Delete it
      NeoNetworkHeaderKey.behalfOfUser: UuidUtil.generateUUID(), // STOPSHIP: Delete it
    });

  Future<SecurityContext?> get _getSecurityContext async {
    if (sslCertificateFilePaths.isEmpty) {
      return null;
    }

    final securityContext = SecurityContext();

    await Future.forEach(sslCertificateFilePaths, (filePath) async {
      final sslCertificate = await rootBundle.load(filePath);
      securityContext.setTrustedCertificatesBytes(sslCertificate.buffer.asInt8List());
    });

    return securityContext;
  }

  Future<NeoResponse> call(NeoHttpCall neoCall) async {
    if (neoCall.endpoint != _Constants.endpointGetToken) {
      await _tokenLock.protect(() async {
        final refreshToken = await _getRefreshToken();

        if (refreshToken == null || isRefreshTokenExpired) {
          if (await _isTwoFactorAuthenticated) {
            await _onInvalidTokenError();
            return NeoResponse.error(const NeoError(responseCode: HttpStatus.forbidden), responseHeaders: {});
          } else {
            await getTemporaryTokenForNotLoggedInUser(currentCall: neoCall);
          }
        }

        final token = await _getToken();
        if (token == null) {
          await _waitForOngoingTokenRequest();
          await getTemporaryTokenForNotLoggedInUser(currentCall: neoCall);
        } else if (isTokenExpired) {
          await _waitForOngoingTokenRequest();
          await _refreshTokenIfExpired();
        }
      });
    }

    if (_isMtlsEnabled) {
      await httpClientConfig.setMtlsStatusForHttpCall(neoCall, _mtlsHelper, secureStorage);
    }
    final fullPath = httpClientConfig.getServiceUrlByKey(
      neoCall.endpoint,
      enableMtls: neoCall.enableMtls,
      parameters: neoCall.pathParameters,
      useHttps: neoCall.useHttps,
    );
    final method = httpClientConfig.getServiceMethodByKey(neoCall.endpoint);
    if (fullPath == null || method == null) {
      return NeoResponse.error(const NeoError(), responseHeaders: {});
    }

    final span = Sentry.startTransaction(
      neoCall.endpoint,
      'http.client',
      description: 'HTTP $method ${neoCall.endpoint}',
    );

    NeoResponse response;
    try {
      switch (method) {
        case HttpMethod.get:
          response = await _requestGet(fullPath, neoCall);
        case HttpMethod.post:
          response = await _requestPost(fullPath, neoCall);
        case HttpMethod.delete:
          response = await _requestDelete(fullPath, neoCall);
        case HttpMethod.put:
          response = await _requestPut(fullPath, neoCall);
        case HttpMethod.patch:
          response = await _requestPatch(fullPath, neoCall);
      }
      unawaited(
        span.finish(
          status:
              response.isSuccess ? const SpanStatus.ok() : SpanStatus.fromHttpStatusCode(response.asError.statusCode),
        ),
      );
      return response;
    } catch (e) {
      if (e is TimeoutException) {
        _neoLogger?.logError("[NeoNetworkManager]: Service call timeout! Endpoint: ${neoCall.endpoint}");
        unawaited(span.finish(status: const SpanStatus.deadlineExceeded()));
        return NeoResponse.error(const NeoError(responseCode: HttpStatus.requestTimeout), responseHeaders: {});
      } else if (e is HandshakeException) {
        _neoLogger?.logConsole("[NeoNetworkManager]: Handshake exception! Endpoint: ${neoCall.endpoint}");
        unawaited(span.finish(status: const SpanStatus.internalError()));
        return NeoResponse.error(const NeoError(), responseHeaders: {});
      } else {
        _neoLogger?.logError("[NeoNetworkManager]: Service call failed! Endpoint: ${neoCall.endpoint}");
        unawaited(span.finish(status: const SpanStatus.internalError()));
        return NeoResponse.error(const NeoError(), responseHeaders: {});
      }
    }
  }

  Future<void> _waitForOngoingTokenRequest() async {
    if (_tokenLockCompleter != null) {
      await _tokenLockCompleter!.future;
    }
  }

  Future<NeoResponse> _requestGet(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await httpClient!
        .get(
          Uri.parse(fullPathWithQueries),
          headers: (await _getDefaultHeaders(neoCall))..addAll(neoCall.headerParameters),
        )
        .timeout(timeoutDuration);
    return _createResponse(response, neoCall);
  }

  Future<NeoResponse> _requestPost(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await httpClient!
        .post(
          Uri.parse(fullPathWithQueries),
          headers: (await _getDefaultPostHeaders(neoCall))..addAll(neoCall.headerParameters),
          body: json.encode(neoCall.body),
        )
        .timeout(timeoutDuration);
    return _createResponse(response, neoCall);
  }

  Future<NeoResponse> _requestDelete(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await httpClient!
        .delete(
          Uri.parse(fullPathWithQueries),
          headers: (await _getDefaultHeaders(neoCall))..addAll(neoCall.headerParameters),
          body: json.encode(neoCall.body),
        )
        .timeout(timeoutDuration);
    return _createResponse(response, neoCall);
  }

  Future<NeoResponse> _requestPut(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await httpClient!
        .put(
          Uri.parse(fullPathWithQueries),
          headers: (await _getDefaultPostHeaders(neoCall))..addAll(neoCall.headerParameters),
          body: json.encode(neoCall.body),
        )
        .timeout(timeoutDuration);
    return _createResponse(response, neoCall);
  }

  Future<NeoResponse> _requestPatch(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await httpClient!
        .patch(
          Uri.parse(fullPathWithQueries),
          headers: (await _getDefaultPostHeaders(neoCall))..addAll(neoCall.headerParameters),
          body: json.encode(neoCall.body),
        )
        .timeout(timeoutDuration);
    return _createResponse(response, neoCall);
  }

  String _getFullPathWithQueries(String fullPath, List<HttpQueryProvider> queryProviders) {
    final Map<String, dynamic> queryParameters = queryProviders.fold(
      {},
      (previousValue, element) => previousValue..addAll(element.queryParameters),
    );
    if (queryParameters.isEmpty) {
      return fullPath;
    }

    final uri = Uri.parse(fullPath);
    return uri.replace(queryParameters: queryParameters).toString();
  }

  Future<NeoResponse> _createResponse(http.Response response, NeoHttpCall call) async {
    Map<String, dynamic>? responseJSON;
    try {
      const utf8Decoder = Utf8Decoder();
      final responseString = utf8Decoder.convert(response.bodyBytes);
      final decodedResponse = json.decode(responseString);
      if (decodedResponse is Map<String, dynamic>) {
        responseJSON = decodedResponse;
      } else {
        responseJSON = {_Constants.wrapperResponseKey: decodedResponse};
      }
    } catch (_) {
      responseJSON = {};
    }

    _logResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      onRequestSucceed?.call(call.endpoint, call.requestId);
      return NeoResponse.success(responseJSON, statusCode: response.statusCode, responseHeaders: response.headers);
    } else if (response.statusCode == _Constants.responseCodeUnauthorized) {
      if (call.endpoint == _Constants.endpointGetToken) {
        final error = NeoError.fromJson(responseJSON);
        _neoLogger?.logError("[NeoNetworkManager]: Token service error!");
        return _handleErrorResponse(error, call, response);
      } else {
        await refreshToken();
        return _retryLastCall(call, response);
      }
    } else {
      try {
        responseJSON.addAll({'body': response.body});
        final hasErrorCode = responseJSON.containsKey("errorCode");
        if (!hasErrorCode) {
          responseJSON.addAll({'errorCode': response.statusCode});
        }
        return _handleErrorResponse(NeoError.fromJson(responseJSON), call, response);
      } on MissingRequiredKeysException {
        final error = NeoError(responseCode: response.statusCode);
        return _handleErrorResponse(error, call, response);
      } catch (e) {
        _neoLogger?.logError(
          "[NeoNetworkManager]: Service call failed! Status code: ${response.statusCode}.Endpoint: ${call.endpoint}",
        );
        return _handleErrorResponse(NeoError(responseCode: response.statusCode), call, response);
      }
    }
  }

  Future<NeoResponse> _handleErrorResponse(NeoError error, NeoHttpCall call, http.Response response) async {
    if (error.isInvalidTokenError) {
      await _onInvalidTokenError();
    } else {
      onRequestFailed?.call(error, call.requestId ?? call.endpoint);
    }
    return NeoResponse.error(error, responseHeaders: response.headers);
  }

  Future<void> _onInvalidTokenError() async {
    await secureStorage.deleteTokensWithRelatedData();
    onInvalidTokenError?.call();
  }

  Future<NeoResponse> _retryLastCall(NeoHttpCall neoHttpCall, http.Response response) async {
    if (neoHttpCall.retryCount == null) {
      neoHttpCall.setRetryCount(httpClientConfig.getRetryCountByKey(neoHttpCall.endpoint));
    }
    if (_canRetryRequest(neoHttpCall)) {
      neoHttpCall.decreaseRetryCount();
      return call(neoHttpCall);
    } else {
      return NeoResponse.error(const NeoError(), responseHeaders: response.headers);
    }
  }

  bool _canRetryRequest(NeoHttpCall call) {
    return (call.retryCount ?? 0) > 0;
  }

  Future<NeoResponse> refreshToken() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken != null) {
      return _refreshAuthDetailsByUsingRefreshToken(refreshToken);
    }
    return NeoResponse.error(const NeoError(), responseHeaders: {});
  }

  Future<NeoResponse> _refreshAuthDetailsByUsingRefreshToken(String refreshToken) async {
    final response = await call(
      NeoHttpCall(
        endpoint: _Constants.endpointGetToken,
        body: {
          _Constants.requestKeyGrantType: _Constants.requestValueGrantTypeRefreshToken,
          _Constants.requestKeyRefreshToken: refreshToken,
        },
      ),
    );
    if (response.isSuccess) {
      final authResponse = HttpAuthResponse.fromJson(response.asSuccess.data);
      await setTokensByAuthResponse(authResponse);
    }
    return response;
  }

  /// Returns true if two factor authenticated
  Future<bool> setTokensByAuthResponse(HttpAuthResponse authResponse, {bool? isMobUnapproved}) async {
    _lastAuthResponse = authResponse;
    final tokenExpirationDurationInSeconds = max(0, (authResponse.expiresInSeconds) - 60);
    _tokenExpirationTime = DateTime.now().add(Duration(seconds: tokenExpirationDurationInSeconds));
    final refreshTokenExpirationDurationInSeconds = max(0, (authResponse.refreshTokenExpiresInSeconds) - 60);
    _refreshTokenExpirationTime = DateTime.now().add(Duration(seconds: refreshTokenExpirationDurationInSeconds));
    final isTwoFactorAuth = await secureStorage.setAuthToken(authResponse.token, isMobUnapproved: isMobUnapproved);
    await secureStorage.write(key: NeoCoreParameterKey.secureStorageRefreshToken, value: authResponse.refreshToken);
    return isTwoFactorAuth;
  }

  Future<bool> getTemporaryTokenForNotLoggedInUser({NeoHttpCall? currentCall}) async {
    // Prevent infinite call loop
    if (currentCall?.endpoint == _Constants.endpointGetToken || await _isTwoFactorAuthenticated) {
      return false;
    }
    final authToken = await _getToken();
    if (authToken != null && authToken.isNotEmpty && !isTokenExpired) {
      return true;
    }
    _tokenLockCompleter = Completer<void>();

    final response = await call(
      NeoHttpCall(
        endpoint: _Constants.endpointGetToken,
        body: {
          _Constants.requestKeyClientId: workflowClientId,
          _Constants.requestKeyClientSecret: workflowClientSecret,
          _Constants.requestKeyGrantType: _Constants.requestValueGrantTypeClientCredentials,
          _Constants.requestKeyScopes: _Constants.requestValueScopes,
        },
      ),
    );
    if (response.isSuccess) {
      final authResponse = HttpAuthResponse.fromJson(response.asSuccess.data);
      await setTokensByAuthResponse(authResponse);
      _tokenLockCompleter?.complete();
      _tokenLockCompleter = null;
      return true;
    } else {
      _tokenLockCompleter?.complete();
      _tokenLockCompleter = null;
      return false;
    }
  }

  Future<bool> get _isTwoFactorAuthenticated async {
    final token = await _getToken();
    if (token == null) {
      return false;
    }

    return TokenUtil.is2FAToken(token);
  }

  Future<String?> _getToken() => secureStorage.read(NeoCoreParameterKey.secureStorageAuthToken);

  Future<String?> _getRefreshToken() => secureStorage.read(NeoCoreParameterKey.secureStorageRefreshToken);

  Future<void> _refreshTokenIfExpired() async {
    if (isTokenExpired) {
      _tokenLockCompleter = Completer<void>();
      await refreshToken();
      _tokenLockCompleter?.complete();
      _tokenLockCompleter = null;
    }
  }

  Future<void> updateSecurityContext() async {
    await _initHttpClient();
  }

  Future<void> _initHttpClient() async {
    if (kIsWeb) {
      httpClient = _wrapWithSentryHttpClient(http.Client());
      return;
    }

    final userAgent = (await _getDefaultHeaders(null))[NeoNetworkHeaderKey.userAgent];
    SecurityContext? securityContext = _enableSslPinning ? await _getSecurityContext : null;
    securityContext = await _addMtlsCertificateToSecurityContext(securityContext);

    final client = HttpClient(context: securityContext)..userAgent = userAgent;

    if (_enableSslPinning) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => false;
    }

    httpClient = _wrapWithSentryHttpClient(IOClient(client));
  }

  SentryHttpClient _wrapWithSentryHttpClient(http.Client client) {
    return SentryHttpClient(
      client: client,
      failedRequestStatusCodes: [SentryStatusCode.range(400, 599)],
    );
  }

  Future<SecurityContext?> _addMtlsCertificateToSecurityContext(SecurityContext? securityContext) async {
    final result = await Future.wait([
      secureStorage.read(NeoCoreParameterKey.secureStorageCustomerId),
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
    ]);

    final userReference = result[0];
    final deviceId = result[1];
    final clientKeyTag = "$deviceId$userReference";

    final clientCertificate = await _mtlsHelper.getCertificate(clientKeyTag: clientKeyTag);
    final privateKey = await _mtlsHelper.getServerPrivateKey(clientKeyTag: clientKeyTag);
    final bool isMtlsEnabled = _isMtlsEnabled && clientCertificate != null && privateKey != null;

    if (isMtlsEnabled) {
      final context = securityContext ?? SecurityContext();
      return context
        ..useCertificateChainBytes(utf8.encode(clientCertificate))
        ..usePrivateKeyBytes(utf8.encode(privateKey));
    }
    return securityContext;
  }

  void _logResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    final logLevel = isSuccess ? Level.trace : Level.warning;
    switch (logScale) {
      case NeoNetworkManagerLogScale.all:
        _neoLogger?.logConsole(
          "[NeoNetworkManager] Response code: ${response.statusCode}.\nURL: ${response.request?.url}\nBody: ${response.body}",
          logLevel: logLevel,
        );
      case NeoNetworkManagerLogScale.simplified:
        _neoLogger?.logConsole(
          "[NeoNetworkManager] Response code: ${response.statusCode}.\nURL: ${response.request?.url}",
          logLevel: logLevel,
        );
      case NeoNetworkManagerLogScale.none:
    }
  }
}
