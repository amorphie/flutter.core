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
import 'package:neo_core/core/network/models/http_auth_response.dart';
import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/util/device_util/models/neo_device_info.dart';
import 'package:neo_core/core/util/uuid_util.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:neo_core/neo_core.dart';
import 'package:universal_io/io.dart';

abstract class _Constants {
  static const int responseCodeUnauthorized = 401;
  static const String wrapperResponseKey = "data";
  static const String endpointGetToken = "get-token";
  static const String headerValueContentType = "application/json";
  static const String requestKeyClientId = "client_id";
  static const String requestKeyClientSecret = "client_secret";
  static const String requestKeyGrantType = "grant_type";
  static const String requestValueGrantTypeRefreshToken = "refresh_token";
  static const String requestValueGrantTypeClientCredentials = "client_credentials";
  static const String requestKeyRefreshToken = "refresh_token";
  static const String requestKeyScopes = "scopes";
  static const List<String> requestValueScopes = ["retail-customer"];
  static const String languageCodeEn = "en";
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
  late final NeoLogger _neoLogger = GetIt.I.get();
  final NeoNetworkManagerLogScale logScale;
  final Map<String, String> defaultHeaders;
  final Duration timeoutDuration;

  late final bool _enableSslPinning;
  DateTime? _tokenExpirationTime;
  Completer? _refreshTokenCompleter;
  final _refreshTokenMutex = Mutex();

  bool get _isTokenExpired => _tokenExpirationTime != null && DateTime.now().isAfter(_tokenExpirationTime!);

  late final http.Client httpClient;

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

  /// Read NeoWorkflowManager with try catch, because it depends on NeoNetworkManager
  NeoWorkflowManager? get _neoWorkflowManager {
    try {
      return GetIt.I.get<NeoWorkflowManager>();
    } catch (e) {
      return null;
    }
  }

  Future<void> init({required bool enableSslPinning}) async {
    _enableSslPinning = enableSslPinning;
    await _initHttpClient();
    await getTemporaryTokenForNotLoggedInUser();
  }

  Future<Map<String, String>> get _defaultHeaders async {
    final results = await Future.wait([
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
      secureStorage.read(NeoCoreParameterKey.secureStorageInstallationId),
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceInfo),
      _authHeader,
      PackageUtil().getAppVersionWithBuildNumber(),
    ]);

    final deviceId = results[0] as String? ?? "";
    final installationId = results[1] as String? ?? "";
    final deviceInfo = results[2] != null ? NeoDeviceInfo.decode(results[2] as String? ?? "") : null;
    final authHeader = results[3] as Map<String, String>? ?? {};
    final appVersion = results[4] as String? ?? "";

    final userAgentHeader = kIsWeb
        ? <String, String>{}
        : {
            NeoNetworkHeaderKey.userAgent: "${deviceInfo?.platform ?? "-"}/"
                "${defaultHeaders[NeoNetworkHeaderKey.application]}/"
                "$appVersion/"
                "${deviceInfo?.version ?? "-"}/"
                "${deviceInfo?.model ?? "-"}",
          };

    return {
      NeoNetworkHeaderKey.contentType: _Constants.headerValueContentType,
      NeoNetworkHeaderKey.acceptLanguage: _languageCode,
      NeoNetworkHeaderKey.contentLanguage: _languageCode,
      NeoNetworkHeaderKey.applicationVersion: appVersion,
      NeoNetworkHeaderKey.deviceId: deviceId,
      NeoNetworkHeaderKey.installationId: installationId,
      NeoNetworkHeaderKey.tokenId: installationId, // TODO: Delete tokenId after the backend changes are done
      NeoNetworkHeaderKey.requestId: UuidUtil.generateUUIDWithoutHyphen(),
      NeoNetworkHeaderKey.deviceInfo: deviceInfo?.model ?? "",
      NeoNetworkHeaderKey.deviceModel: deviceInfo?.model ?? "",
      NeoNetworkHeaderKey.deviceVersion: deviceInfo?.version ?? "",
      NeoNetworkHeaderKey.devicePlatform: deviceInfo?.platform ?? "",
      NeoNetworkHeaderKey.deployment: deviceInfo?.platform ?? "",
      NeoNetworkHeaderKey.instanceId: _neoWorkflowManager?.instanceId ?? "",
      NeoNetworkHeaderKey.workflowName: _neoWorkflowManager?.getWorkflowName() ?? "",
    }
      ..addAll(authHeader)
      ..addAll(userAgentHeader)
      ..addAll(defaultHeaders);
  }

  String get _languageCode {
    final languageCodeReadResult = neoSharedPrefs.read(NeoCoreParameterKey.sharedPrefsLanguageCode);
    final String languageCode = languageCodeReadResult != null ? languageCodeReadResult as String : "";

    if (languageCode == _Constants.languageCodeEn) {
      return "$languageCode-US";
    } else {
      return '$languageCode-${languageCode.toUpperCase()}';
    }
  }

  Future<Map<String, String>> get _authHeader async {
    final authToken = await secureStorage.read(NeoCoreParameterKey.secureStorageAuthToken);
    return authToken == null ? {} : {NeoNetworkHeaderKey.authorization: 'Bearer $authToken'};
  }

  Future<Map<String, String>> get _defaultPostHeaders async => <String, String>{}
    ..addAll(await _defaultHeaders)
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
    final fullPath = httpClientConfig.getServiceUrlByKey(
      neoCall.endpoint,
      parameters: neoCall.pathParameters,
      useHttps: neoCall.useHttps,
    );
    final method = httpClientConfig.getServiceMethodByKey(neoCall.endpoint);
    if (fullPath == null || method == null) {
      return NeoResponse.error(const NeoError());
    }
    await getTemporaryTokenForNotLoggedInUser(currentCall: neoCall);
    if (neoCall.endpoint != _Constants.endpointGetToken) {
      await _refreshTokenIfExpired();
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
        _neoLogger.logError("[NeoNetworkManager]: Service call timeout! Endpoint: ${neoCall.endpoint}");
        return NeoResponse.error(const NeoError(responseCode: HttpStatus.requestTimeout));
      } else {
        _neoLogger.logError("[NeoNetworkManager]: Service call failed! Endpoint: ${neoCall.endpoint}");
        return NeoResponse.error(const NeoError());
      }
    }
  }

  Future<NeoResponse> _requestGet(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await httpClient
        .get(
          Uri.parse(fullPathWithQueries),
          headers: (await _defaultHeaders)..addAll(neoCall.headerParameters),
        )
        .timeout(timeoutDuration);
    return _createResponse(response, neoCall);
  }

  Future<NeoResponse> _requestPost(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await httpClient
        .post(
          Uri.parse(fullPathWithQueries),
          headers: (await _defaultPostHeaders)..addAll(neoCall.headerParameters),
          body: json.encode(neoCall.body),
        )
        .timeout(timeoutDuration);
    return _createResponse(response, neoCall);
  }

  Future<NeoResponse> _requestDelete(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await httpClient
        .delete(
          Uri.parse(fullPathWithQueries),
          headers: (await _defaultHeaders)..addAll(neoCall.headerParameters),
          body: json.encode(neoCall.body),
        )
        .timeout(timeoutDuration);
    return _createResponse(response, neoCall);
  }

  Future<NeoResponse> _requestPut(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await httpClient
        .put(
          Uri.parse(fullPathWithQueries),
          headers: (await _defaultPostHeaders)..addAll(neoCall.headerParameters),
          body: json.encode(neoCall.body),
        )
        .timeout(timeoutDuration);
    return _createResponse(response, neoCall);
  }

  Future<NeoResponse> _requestPatch(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await httpClient
        .patch(
          Uri.parse(fullPathWithQueries),
          headers: (await _defaultPostHeaders)..addAll(neoCall.headerParameters),
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
      return NeoResponse.success(responseJSON);
    } else if (response.statusCode == _Constants.responseCodeUnauthorized) {
      if (call.endpoint == _Constants.endpointGetToken) {
        final error = NeoError.fromJson(responseJSON);
        _neoLogger.logError("[NeoNetworkManager]: Token service error!");
        return _handleErrorResponse(error, call);
      }
      final refreshToken = await _getRefreshToken();
      if (refreshToken != null) {
        final result = await _refreshAuthDetailsByUsingRefreshToken(refreshToken);
        if (result.isSuccess) {
          return _retryLastCall(call);
        } else {
          _neoLogger.logError("[NeoNetworkManager]: Token refresh service error!");
          return result.asError;
        }
      } else {
        final bool isTokenRetrieved = await getTemporaryTokenForNotLoggedInUser(currentCall: call);
        if (isTokenRetrieved) {
          return _retryLastCall(call);
        } else {
          return NeoResponse.error(const NeoError());
        }
      }
    } else {
      try {
        responseJSON.addAll({'body': response.body});
        final hasErrorCode = responseJSON.containsKey("errorCode");
        if (!hasErrorCode) {
          responseJSON.addAll({'errorCode': response.statusCode});
        }
        return _handleErrorResponse(NeoError.fromJson(responseJSON), call);
      } on MissingRequiredKeysException {
        final error = NeoError(responseCode: response.statusCode);
        return _handleErrorResponse(error, call);
      } catch (e) {
        _neoLogger.logError(
          "[NeoNetworkManager]: Service call failed! Status code: ${response.statusCode}.Endpoint: ${call.endpoint}",
        );
        return _handleErrorResponse(NeoError(responseCode: response.statusCode), call);
      }
    }
  }

  Future<NeoResponse> _handleErrorResponse(NeoError error, NeoHttpCall call) async {
    if (error.isInvalidTokenError) {
      await secureStorage.deleteTokensWithRelatedData();
      onInvalidTokenError?.call();
    } else {
      onRequestFailed?.call(error, call.requestId ?? call.endpoint);
    }
    return NeoResponse.error(error);
  }

  Future<NeoResponse> _retryLastCall(NeoHttpCall neoHttpCall) async {
    if (neoHttpCall.retryCount == null) {
      neoHttpCall.setRetryCount(httpClientConfig.getRetryCountByKey(neoHttpCall.endpoint));
    }
    if (_canRetryRequest(neoHttpCall)) {
      neoHttpCall.decreaseRetryCount();
      return call(neoHttpCall);
    } else {
      return NeoResponse.error(const NeoError());
    }
  }

  bool _canRetryRequest(NeoHttpCall call) {
    return (call.retryCount ?? 0) > 0;
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
    } else {
      await secureStorage.deleteTokensWithRelatedData();
      onInvalidTokenError?.call();
    }
    return response;
  }

  /// Returns true if two factor authenticated
  Future<bool> setTokensByAuthResponse(HttpAuthResponse authResponse, {bool? isMobUnapproved}) async {
    final tokenExpirationDurationInSeconds = max(0, (authResponse.expiresInSeconds) - 60);
    _tokenExpirationTime = DateTime.now().add(Duration(seconds: tokenExpirationDurationInSeconds));
    final isTwoFactorAuth = await secureStorage.setAuthToken(authResponse.token, isMobUnapproved: isMobUnapproved);
    await secureStorage.write(key: NeoCoreParameterKey.secureStorageRefreshToken, value: authResponse.refreshToken);
    return isTwoFactorAuth;
  }

  Future<bool> getTemporaryTokenForNotLoggedInUser({NeoHttpCall? currentCall}) async {
    // Prevent infinite call loop
    if (currentCall?.endpoint == _Constants.endpointGetToken || _isTwoFactorAuthenticated) {
      return false;
    }
    final authToken = await secureStorage.read(NeoCoreParameterKey.secureStorageAuthToken);
    if (authToken != null && authToken.isNotEmpty) {
      return true;
    }

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
      return true;
    } else {
      return false;
    }
  }

  bool get _isTwoFactorAuthenticated => neoSharedPrefs.read(NeoCoreParameterKey.sharedPrefsAuthStatus) == "2FA";

  Future<String?> _getRefreshToken() => secureStorage.read(NeoCoreParameterKey.secureStorageRefreshToken);

  Future<void> _refreshTokenIfExpired() async {
    if (_isTokenExpired) {
      if (_refreshTokenCompleter != null) {
        await _refreshTokenCompleter!.future;
        return;
      }
      await _refreshTokenMutex.protect(() async {
        _refreshTokenCompleter = Completer<void>();
        try {
          final refreshToken = await _getRefreshToken();
          if (refreshToken != null) {
            await _refreshAuthDetailsByUsingRefreshToken(refreshToken);
          } else {
            onInvalidTokenError?.call();
          }
        } finally {
          _refreshTokenCompleter!.complete();
          _refreshTokenCompleter = null;
        }
      });
    }
  }

  Future<void> _initHttpClient() async {
    if (kIsWeb) {
      httpClient = http.Client();
      return;
    }

    final userAgent = (await _defaultHeaders)[NeoNetworkHeaderKey.userAgent];
    final client = HttpClient(context: _enableSslPinning ? await _getSecurityContext : null)..userAgent = userAgent;

    if (_enableSslPinning) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => false;
    }

    httpClient = IOClient(client);
  }

  void _logResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    final logLevel = isSuccess ? Level.trace : Level.warning;
    switch (logScale) {
      case NeoNetworkManagerLogScale.all:
        _neoLogger.logConsole(
          "[NeoNetworkManager] Response code: ${response.statusCode}.\nURL: ${response.request?.url}\nBody: ${response.body}",
          logLevel: logLevel,
        );
      case NeoNetworkManagerLogScale.simplified:
        _neoLogger.logConsole(
          "[NeoNetworkManager] Response code: ${response.statusCode}.\nURL: ${response.request?.url}",
          logLevel: logLevel,
        );
      case NeoNetworkManagerLogScale.none:
    }
  }
}
