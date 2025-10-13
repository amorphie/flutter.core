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

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:jose/jose.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';
import 'package:mutex/mutex.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/headers/mtls_headers.dart';
import 'package:neo_core/core/network/headers/neo_constant_headers.dart';
import 'package:neo_core/core/network/headers/neo_dynamic_headers.dart';
import 'package:neo_core/core/network/helpers/mtls_helper.dart';
import 'package:neo_core/core/network/interceptors/neo_response_interceptor.dart';
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
import 'package:universal_io/io.dart';

abstract class _Constants {
  static const int responseCodeUnauthorized = 401;
  static const String wrapperResponseKey = "data";
  static const String endpointGetToken = "get-token";
  static const String requestKeyClientId = "client_id";
  static const String requestKeyClientSecret = "client_secret";
  static const String requestKeyGrantType = "grant_type";
  static const String requestValueGrantTypeRefreshToken = "refresh_token";
  static const String requestValueGrantTypeBurganCredential = "urn:ietf:params:oauth:grant-type:burgan-credential";
  static const String requestValueGrantTypeClientCredential = "client_credential";
  static const String requestKeyRefreshToken = "refresh_token";
  static const String requestKeyScopes = "scopes";
  static const List<String> requestValueScopes = ["retail-customer"];
  static const String requestValueGrantTypeRefreshTokenLiteral = "refresh_token";
  static const String requestValueGrantTypeCertificateAssertion =
      "urn:ietf:params:oauth:grant-type:burgan-certificate-assertion";
  static const String requestKeyClientAssertion = "client_assertion";
  static const List<String> requestValueScopesOpenId = ["openid"];
  static const String responseKeyErrorCode = "errorCode";
  static const String authStatus1FA = "1FA";
  static const String jwtClaimIss = "iss";
  static const String jwtClaimSub = "sub";
  static const String jwtClaimAud = "aud";
  static const String jwtClaimJti = "jti";
  static const String jwtClaimNbf = "nbf";
  static const String jwtClaimExp = "exp";
  static const String jwtClaimDeviceId = "device_id";
  static const String jwtClaimInstallationId = "installation_id";
  static const String jwtClaimRefreshToken = "refresh_token";
  static const String jwtAudience = "BurganIam";
  static const String jwtAlgorithm = "RS256";
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
      return response;
    } catch (e) {
      if (e is TimeoutException) {
        _neoLogger?.logError("[NeoNetworkManager]: Service call timeout! Endpoint: ${neoCall.endpoint}");
        return NeoResponse.error(const NeoError(responseCode: HttpStatus.requestTimeout), responseHeaders: {});
      } else if (e is HandshakeException) {
        _neoLogger?.logConsole("[NeoNetworkManager]: Handshake exception! Endpoint: ${neoCall.endpoint}");
        return NeoResponse.error(const NeoError(), responseHeaders: {});
      } else {
        _neoLogger?.logError("[NeoNetworkManager]: Service call failed! Endpoint: ${neoCall.endpoint}");
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
      var decodedResponse = json.decode(responseString);
      decodedResponse = await NeoResponseInterceptor(
        body: decodedResponse,
        response: response,
        secureStorage: secureStorage,
        mtlsHelper: _mtlsHelper,
      ).intercept();
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
        final hasErrorCode = responseJSON.containsKey(_Constants.responseKeyErrorCode);
        if (!hasErrorCode) {
          responseJSON.addAll({_Constants.responseKeyErrorCode: response.statusCode});
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
        body: await _isExistUser
            ? {
                _Constants.requestKeyGrantType: _Constants.requestValueGrantTypeRefreshTokenLiteral,
                _Constants.requestKeyClientAssertion: await _createJwtTokenForAccessRequest(isRefreshToken: true),
                _Constants.requestKeyScopes: _Constants.requestValueScopesOpenId,
              }
            : {
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

  Future<bool> getTemporaryTokenForNotLoggedInUser({NeoHttpCall? currentCall, bool error = false}) async {
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
      await _isExistUser
          ? error
              ? _clientCredentialHttpCall()
              : await _onefaCredentialHttpCall()
          : await _notLoggedInUserCredentialHttpCall(),
    );
    if (response.isSuccess) {
      final authResponse = HttpAuthResponse.fromJson(response.asSuccess.data);
      await setTokensByAuthResponse(authResponse);
      _tokenLockCompleter?.complete();
      _tokenLockCompleter = null;
      return true;
    } else {
      if (!error && await _isExistUser) {
        await getTemporaryTokenForNotLoggedInUser(currentCall: currentCall, error: true);
      }
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
      httpClient = http.Client();
      return;
    }

    final userAgent = (await _getDefaultHeaders(null))[NeoNetworkHeaderKey.userAgent];
    SecurityContext? securityContext = _enableSslPinning ? await _getSecurityContext : null;
    securityContext = await _addMtlsCertificateToSecurityContext(securityContext);

    final client = HttpClient(context: securityContext)..userAgent = userAgent;

    if (_enableSslPinning) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => false;
    }

    httpClient = IOClient(client);
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

  Future<bool> get _isExistUser async {
    final customerId = await secureStorage.read(NeoCoreParameterKey.secureStorageCustomerId);
    final authStatus = neoSharedPrefs.read(NeoCoreParameterKey.sharedPrefsAuthStatus);

    return (customerId != null && customerId.isNotEmpty) ||
        (authStatus != null && authStatus == _Constants.authStatus1FA);
  }

  Future<String> _createJwtTokenForAccessRequest({bool isRefreshToken = false, String? jti}) async {
    final customerId = await secureStorage.read(NeoCoreParameterKey.secureStorageCustomerId);
    final installationId = await secureStorage.read(NeoCoreParameterKey.secureStorageInstallationId);
    final deviceId = await secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId);

    final serverPrivateKey = await MtlsHelper().getServerPrivateKey(clientKeyTag: "$deviceId$customerId");
    final now = DateTime.now().toUtc();

    // Claims (RFC 7523 uyumlu)
    final claims = {
      _Constants.jwtClaimIss: workflowClientId,
      _Constants.jwtClaimSub: customerId,
      _Constants.jwtClaimAud: _Constants.jwtAudience,
      _Constants.jwtClaimJti: jti ?? UuidUtil.generateUUID(),
      _Constants.jwtClaimNbf: now.millisecondsSinceEpoch ~/ 1000,
      _Constants.jwtClaimExp: now.add(const Duration(minutes: 2)).millisecondsSinceEpoch ~/ 1000,
      _Constants.jwtClaimDeviceId: deviceId,
      _Constants.jwtClaimInstallationId: installationId,
    };

    if (isRefreshToken) {
      claims[_Constants.jwtClaimRefreshToken] = await _getRefreshToken();
    }

    // RSA key yükle
    final keyStore = JsonWebKeyStore();

    final jwk = JsonWebKey.fromPem(serverPrivateKey!);

    keyStore.addKey(jwk);

    // JWT oluştur

    final builder = JsonWebSignatureBuilder()
      ..jsonContent = claims
      ..addRecipient(jwk, algorithm: _Constants.jwtAlgorithm);

    final jws = builder.build();

    // İmzalı JWT string

    return jws.toCompactSerialization();
  }

  Future<String?> _fingerPrintAlgorithm(String jti) async {
    final deviceId = await secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId);
    final installationId = await secureStorage.read(NeoCoreParameterKey.secureStorageInstallationId);
    if (deviceId == null || installationId == null) {
      return null;
    }

    // Combine JTI + ClientId + DeviceId + InstallationId
    final combinedString = jti + workflowClientId + deviceId + installationId;

    // Convert to bytes and calculate SHA-256 hash
    final bytes = utf8.encode(combinedString);
    final digest = sha256.convert(bytes);

    // Convert to Base64URL encoding
    final base64Encoded = base64.encode(digest.bytes);

    return base64Encoded;
  }

  Future<NeoHttpCall> _notLoggedInUserCredentialHttpCall() async {
    final jti = UuidUtil.generateUUID();

    return NeoHttpCall(
      endpoint: _Constants.endpointGetToken,
      body: {
        _Constants.jwtClaimJti: jti,
        _Constants.requestKeyClientId: workflowClientId,
        _Constants.jwtClaimInstallationId: await secureStorage.read(NeoCoreParameterKey.secureStorageInstallationId),
        _Constants.jwtClaimDeviceId: await secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
        _Constants.requestKeyGrantType: _Constants.requestValueGrantTypeBurganCredential,
        _Constants.requestKeyScopes: _Constants.requestValueScopes,
      },
      headerParameters: {
        NeoNetworkHeaderKey.fingerprint: (await _fingerPrintAlgorithm(jti)) ?? "",
      },
    );
  }

  Future<NeoHttpCall> _onefaCredentialHttpCall() async {
    final jti = UuidUtil.generateUUID();

    return NeoHttpCall(
      endpoint: _Constants.endpointGetToken,
      body: {
        _Constants.requestKeyGrantType: _Constants.requestValueGrantTypeCertificateAssertion,
        _Constants.requestKeyClientAssertion: await _createJwtTokenForAccessRequest(jti: jti),
        _Constants.requestKeyScopes: _Constants.requestValueScopesOpenId,
      },
    );
  }

  NeoHttpCall _clientCredentialHttpCall() {
    return NeoHttpCall(
      endpoint: _Constants.endpointGetToken,
      body: {
        _Constants.requestKeyClientId: workflowClientId,
        _Constants.requestKeyClientSecret: workflowClientSecret,
        _Constants.requestKeyGrantType: _Constants.requestValueGrantTypeClientCredential,
        _Constants.requestKeyScopes: _Constants.requestValueScopes,
      },
    );
  }
}
