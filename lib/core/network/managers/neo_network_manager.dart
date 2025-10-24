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

  Future<void> init({required bool enableSslPinning}) async {
    _enableSslPinning = enableSslPinning;
    await _initHttpClient();
    await getTemporaryTokenForNotLoggedInUser();
  }

  Future<Map<String, String>> _getDefaultHeaders(NeoHttpCall? neoCall) async {
    print('[NNM] ===== GETTING DEFAULT HEADERS =====');
    
    print('[NNM] Getting dynamic headers...');
    final dynamicHeaders = await NeoDynamicHeaders(neoSharedPrefs: neoSharedPrefs, secureStorage: secureStorage).getHeaders();
    print('[NNM] Dynamic headers: $dynamicHeaders');
    
    print('[NNM] Checking MTLS...');
    print('[NNM] MTLS enabled: $_isMtlsEnabled');
    print('[NNM] Sign for MTLS: ${neoCall?.signForMtls ?? false}');
    
    final mtlsHeaders = _isMtlsEnabled && (neoCall?.signForMtls ?? false) ? await _mtlsHeaders.getHeaders(neoCall?.body ?? {}) : {};
    print('[NNM] MTLS headers: $mtlsHeaders');
    
    print('[NNM] Getting constant headers...');
    final constantHeaders = await NeoConstantHeaders(
      neoSharedPrefs: neoSharedPrefs,
      secureStorage: secureStorage,
      defaultHeaders: defaultHeaders,
    ).getHeaders();
    print('[NNM] Constant headers: $constantHeaders');
    
    final allHeaders = <String, String>{}
      ..addAll(Map<String, String>.from(dynamicHeaders))
      ..addAll(Map<String, String>.from(mtlsHeaders))
      ..addAll(Map<String, String>.from(constantHeaders));
    
    print('[NNM] Final default headers: $allHeaders');
    return allHeaders;
  }

  Future<Map<String, String>> _getDefaultPostHeaders(NeoHttpCall neoCall) async {
    print('[NNM] ===== GETTING DEFAULT POST HEADERS =====');
    print('[NNM] Getting base default headers...');
    final baseHeaders = await _getDefaultHeaders(neoCall);
    print('[NNM] Base headers: $baseHeaders');
    
    final postHeaders = <String, String>{}
      ..addAll(baseHeaders)
      ..addAll({
        NeoNetworkHeaderKey.user: UuidUtil.generateUUID(), // STOPSHIP: Delete it
        NeoNetworkHeaderKey.behalfOfUser: UuidUtil.generateUUID(), // STOPSHIP: Delete it
      });
    
    print('[NNM] Final POST headers: $postHeaders');
    return postHeaders;
  }

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
    print('[NNM] ===== STARTING REQUEST =====');
    print('[NNM] Endpoint: ${neoCall.endpoint}');
    print('[NNM] Body: ${neoCall.body}');
    print('[NNM] Headers: ${neoCall.headerParameters}');
    print('[NNM] Path Parameters: ${neoCall.pathParameters}');
    print('[NNM] Query Providers: ${neoCall.queryProviders}');

    if (neoCall.endpoint != _Constants.endpointGetToken && !neoCall.endpoint.startsWith('vnext-')) {
      print('[NNM] Checking token validity...');
      await _tokenLock.protect(() async {
        final refreshToken = await _getRefreshToken();
        print('[NNM] Refresh token exists: ${refreshToken != null}');
        print('[NNM] Refresh token expired: $isRefreshTokenExpired');

        if (refreshToken == null || isRefreshTokenExpired) {
          print('[NNM] No valid refresh token, checking 2FA...');
          if (await _isTwoFactorAuthenticated) {
            print('[NNM] 2FA authenticated, calling invalid token error');
            await _onInvalidTokenError();
            return NeoResponse.error(const NeoError(responseCode: HttpStatus.forbidden), responseHeaders: {});
          } else {
            print('[NNM] Getting temporary token for not logged in user');
            await getTemporaryTokenForNotLoggedInUser(currentCall: neoCall);
          }
        }

        final token = await _getToken();
        print('[NNM] Token exists: ${token != null}');
        print('[NNM] Token expired: $isTokenExpired');
        if (token == null) {
          print('[NNM] No token, waiting for ongoing token request...');
          await _waitForOngoingTokenRequest();
          print('[NNM] Getting temporary token after wait');
          await getTemporaryTokenForNotLoggedInUser(currentCall: neoCall);
        } else if (isTokenExpired) {
          print('[NNM] Token expired, refreshing...');
          await _waitForOngoingTokenRequest();
          await _refreshTokenIfExpired();
        }
      });
    } else if (neoCall.endpoint.startsWith('vnext-')) {
      print('[NNM] Skipping token check for vNext endpoint: ${neoCall.endpoint}');
    }

    if (_isMtlsEnabled) {
      print('[NNM] MTLS enabled, setting MTLS status...');
      await httpClientConfig.setMtlsStatusForHttpCall(neoCall, _mtlsHelper, secureStorage);
    }
    
    print('[NNM] Getting service URL...');
    final fullPath = httpClientConfig.getServiceUrlByKey(
      neoCall.endpoint,
      enableMtls: neoCall.enableMtls,
      parameters: neoCall.pathParameters,
      useHttps: neoCall.useHttps,
    );
    print('[NNM] Full path: $fullPath');
    
    final method = httpClientConfig.getServiceMethodByKey(neoCall.endpoint);
    print('[NNM] HTTP method: $method');
    
    if (fullPath == null || method == null) {
      print('[NNM] ERROR: Full path or method is null');
      return NeoResponse.error(const NeoError(), responseHeaders: {});
    }

    print('[NNM] Making HTTP request...');
    NeoResponse response;
    try {
      switch (method) {
        case HttpMethod.get:
          print('[NNM] Executing GET request');
          response = await _requestGet(fullPath, neoCall);
        case HttpMethod.post:
          print('[NNM] Executing POST request');
          response = await _requestPost(fullPath, neoCall);
        case HttpMethod.delete:
          print('[NNM] Executing DELETE request');
          response = await _requestDelete(fullPath, neoCall);
        case HttpMethod.put:
          print('[NNM] Executing PUT request');
          response = await _requestPut(fullPath, neoCall);
        case HttpMethod.patch:
          print('[NNM] Executing PATCH request');
          response = await _requestPatch(fullPath, neoCall);
      }
      print('[NNM] Request completed successfully');
      return response;
    } catch (e) {
      print('[NNM] EXCEPTION during request: $e');
      print('[NNM] Exception type: ${e.runtimeType}');
      if (e is TimeoutException) {
        print('[NNM] Timeout exception occurred');
        _neoLogger?.logError("[NeoNetworkManager]: Service call timeout! Endpoint: ${neoCall.endpoint}");
        return NeoResponse.error(const NeoError(responseCode: HttpStatus.requestTimeout), responseHeaders: {});
      } else if (e is HandshakeException) {
        print('[NNM] Handshake exception occurred');
        _neoLogger?.logConsole("[NeoNetworkManager]: Handshake exception! Endpoint: ${neoCall.endpoint}");
        return NeoResponse.error(const NeoError(), responseHeaders: {});
      } else {
        print('[NNM] Generic exception occurred');
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
    print('[NNM] ===== POST REQUEST =====');
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    print('[NNM] POST URL: $fullPathWithQueries');
    
    print('[NNM] Getting default POST headers...');
    final defaultHeaders = await _getDefaultPostHeaders(neoCall);
    print('[NNM] Default headers: $defaultHeaders');
    
    final finalHeaders = defaultHeaders..addAll(neoCall.headerParameters);
    print('[NNM] Final headers: $finalHeaders');
    
    final bodyJson = json.encode(neoCall.body);
    print('[NNM] POST body JSON: $bodyJson');
    
    print('[NNM] Making HTTP POST call...');
    final response = await httpClient!
        .post(
          Uri.parse(fullPathWithQueries),
          headers: finalHeaders,
          body: bodyJson,
        )
        .timeout(timeoutDuration);
    
    print('[NNM] POST response received');
    print('[NNM] Response status: ${response.statusCode}');
    print('[NNM] Response headers: ${response.headers}');
    print('[NNM] Response body: ${response.body}');
    
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
    print('[NNM] ===== GETTING FULL PATH WITH QUERIES =====');
    print('[NNM] Full path: $fullPath');
    print('[NNM] Query providers count: ${queryProviders.length}');
    
    final Map<String, dynamic> queryParameters = queryProviders.fold(
      {},
      (previousValue, element) {
        print('[NNM] Processing query provider: ${element.queryParameters}');
        return previousValue..addAll(element.queryParameters);
      },
    );
    
    print('[NNM] Final query parameters: $queryParameters');
    
    if (queryParameters.isEmpty) {
      print('[NNM] No query parameters, returning original path');
      return fullPath;
    }

    // Convert dynamic values to strings for Uri.replace
    print('[NNM] Query parameters types: ${queryParameters.map((k, v) => MapEntry(k, v.runtimeType))}');
    print('[NNM] Converting query parameters to strings...');
    
    final Map<String, String> stringQueryParameters = queryParameters.map(
      (key, value) {
        print('[NNM] Converting $key: $value (${value.runtimeType}) -> ${value.toString()}');
        return MapEntry(key, value.toString());
      },
    );
    
    print('[NNM] String query parameters: $stringQueryParameters');

    final uri = Uri.parse(fullPath);
    final finalUrl = uri.replace(queryParameters: stringQueryParameters).toString();
    print('[NNM] Final URL with queries: $finalUrl');
    
    return finalUrl;
  }

  Future<NeoResponse> _createResponse(http.Response response, NeoHttpCall call) async {
    print('[NNM] ===== CREATING RESPONSE =====');
    print('[NNM] Raw response status: ${response.statusCode}');
    print('[NNM] Raw response body: ${response.body}');
    print('[NNM] Raw response headers: ${response.headers}');
    
    Map<String, dynamic>? responseJSON;
    try {
      print('[NNM] Decoding response body...');
      const utf8Decoder = Utf8Decoder();
      final responseString = utf8Decoder.convert(response.bodyBytes);
      print('[NNM] Decoded response string: $responseString');
      
      final decodedResponse = json.decode(responseString);
      print('[NNM] JSON decoded response: $decodedResponse');
      
      if (decodedResponse is Map<String, dynamic>) {
        responseJSON = decodedResponse;
        print('[NNM] Response is Map<String, dynamic>');
      } else {
        responseJSON = {_Constants.wrapperResponseKey: decodedResponse};
        print('[NNM] Response wrapped in data key');
      }
      print('[NNM] Final response JSON: $responseJSON');
    } catch (e) {
      print('[NNM] JSON decode error: $e');
      responseJSON = {};
    }

    _logResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('[NNM] SUCCESS response (${response.statusCode})');
      onRequestSucceed?.call(call.endpoint, call.requestId);
      return NeoResponse.success(responseJSON, statusCode: response.statusCode, responseHeaders: response.headers);
    } else if (response.statusCode == _Constants.responseCodeUnauthorized) {
      print('[NNM] UNAUTHORIZED response (401)');
      if (call.endpoint == _Constants.endpointGetToken) {
        final error = NeoError.fromJson(responseJSON);
        _neoLogger?.logError("[NeoNetworkManager]: Token service error!");
        return _handleErrorResponse(error, call, response);
      } else {
        await refreshToken();
        return _retryLastCall(call, response);
      }
    } else {
      print('[NNM] ERROR response (${response.statusCode})');
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
        print('[NNM] Error handling exception: $e');
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
}
