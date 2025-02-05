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

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';
import 'package:mutex/mutex.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/interceptors/constant_headers_request_interceptor.dart';
import 'package:neo_core/core/network/interceptors/dynamic_headers_request_interceptor.dart';
import 'package:neo_core/core/network/interceptors/unauthorized_response_interceptor.dart';
import 'package:neo_core/core/network/models/http_auth_response.dart';
import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/util/uuid_util.dart';
import 'package:neo_core/neo_core.dart';
import 'package:universal_io/io.dart';

abstract class _Constants {
  static const int responseCodeUnauthorized = 401;
  static const String wrapperResponseKey = "data";
  static const String endpointGetToken = "get-token";
  static const String endpointElastic = "elastic";
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
  late final NeoLogger _neoLogger = GetIt.I.get();
  final NeoNetworkManagerLogScale logScale;
  final Map<String, String> defaultHeaders;
  final Duration timeoutDuration;

  late final bool _enableSslPinning;
  DateTime? _tokenExpirationTime;
  Completer? _refreshTokenCompleter;
  final _refreshTokenMutex = Mutex();

  bool get _isTokenExpired => _tokenExpirationTime != null && DateTime.now().isAfter(_tokenExpirationTime!);

  final httpClient = Dio();

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

  Future<void> init({required bool enableSslPinning}) async {
    _enableSslPinning = enableSslPinning;
    await _initHttpClient();
    await getTemporaryTokenForNotLoggedInUser();
  }

  Map<String, String> get _defaultPostHeaders => <String, String>{}..addAll({
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
      return NeoResponse.error(const NeoError(), HttpStatus.badRequest);
    }
    await getTemporaryTokenForNotLoggedInUser(currentCall: neoCall);

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
        return NeoResponse.error(const NeoError(responseCode: HttpStatus.requestTimeout), HttpStatus.requestTimeout);
      } else {
        _neoLogger.logError("[NeoNetworkManager]: Service call failed! Endpoint: ${neoCall.endpoint}");
        return NeoResponse.error(const NeoError(), HttpStatus.badRequest);
      }
    }
  }

  Future<NeoResponse> _requestGet(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    try {
      final response = await httpClient
          .get(
            fullPathWithQueries,
            options: Options(
              extra: {NeoHttpCall.extraKey: neoCall},
              responseType: ResponseType.bytes,
              headers: neoCall.headerParameters,
            ),
          )
          .timeout(timeoutDuration);

      return _createResponse(response, neoCall);
    } on DioException catch (e) {
      return _handleDioTimeoutException(e, neoCall);
    }
  }

  Future<NeoResponse> _requestPost(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    try {
      final response = await httpClient
          .post(
            fullPathWithQueries,
            data: json.encode(neoCall.body),
            options: Options(
              extra: {NeoHttpCall.extraKey: neoCall},
              responseType: ResponseType.bytes,
              headers: _defaultPostHeaders..addAll(neoCall.headerParameters),
            ),
          )
          .timeout(timeoutDuration);

      return _createResponse(response, neoCall);
    } on DioException catch (e) {
      return _handleDioTimeoutException(e, neoCall);
    }
  }

  NeoResponse _handleDioTimeoutException(DioException e, NeoHttpCall neoCall) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      if (neoCall.endpoint != _Constants.endpointElastic) {
        _neoLogger.logError("[NeoNetworkManager]: Service call timeout! Endpoint: ${neoCall.endpoint}");
      }
      return NeoResponse.error(const NeoError(responseCode: HttpStatus.requestTimeout), HttpStatus.requestTimeout);
    } else {
      if (neoCall.endpoint != _Constants.endpointElastic) {
        _neoLogger.logError("[NeoNetworkManager]: Service call failed! Endpoint: ${neoCall.endpoint}");
      }
      return NeoResponse.error(const NeoError(), HttpStatus.badRequest);
    }
  }

  Future<NeoResponse> _requestDelete(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    try {
      final response = await httpClient
          .delete(
            fullPathWithQueries,
            data: json.encode(neoCall.body),
            options: Options(
              extra: {NeoHttpCall.extraKey: neoCall},
              responseType: ResponseType.bytes,
              headers: neoCall.headerParameters,
            ),
          )
          .timeout(timeoutDuration);

      return _createResponse(response, neoCall);
    } on DioException catch (e) {
      return _handleDioTimeoutException(e, neoCall);
    }
  }

  Future<NeoResponse> _requestPut(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    try {
      final response = await httpClient
          .put(
            fullPathWithQueries,
            data: json.encode(neoCall.body),
            options: Options(
              extra: {NeoHttpCall.extraKey: neoCall},
              responseType: ResponseType.bytes,
              headers: _defaultPostHeaders..addAll(neoCall.headerParameters),
            ),
          )
          .timeout(timeoutDuration);

      return _createResponse(response, neoCall);
    } on DioException catch (e) {
      return _handleDioTimeoutException(e, neoCall);
    }
  }

  Future<NeoResponse> _requestPatch(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    try {
      final response = await httpClient
          .patch(
            fullPathWithQueries,
            data: json.encode(neoCall.body),
            options: Options(
              extra: {NeoHttpCall.extraKey: neoCall},
              responseType: ResponseType.bytes,
              headers: _defaultPostHeaders..addAll(neoCall.headerParameters),
            ),
          )
          .timeout(timeoutDuration);

      return _createResponse(response, neoCall);
    } on DioException catch (e) {
      return _handleDioTimeoutException(e, neoCall);
    }
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

  Future<NeoResponse> _createResponse(Response response, NeoHttpCall call) async {
    Map<String, dynamic>? responseJSON;
    try {
      final responseString = const Utf8Decoder().convert(response.data);
      final decodedResponse = json.decode(responseString);
      if (decodedResponse is Map<String, dynamic>) {
        responseJSON = decodedResponse;
      } else {
        responseJSON = {_Constants.wrapperResponseKey: decodedResponse};
      }
    } catch (e) {
      responseJSON = {_Constants.wrapperResponseKey: response.data};
    }

    _logResponse(response);
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      onRequestSucceed?.call(call.endpoint, call.requestId);
      return NeoResponse.success(responseJSON, statusCode);
    } else {
      try {
        responseJSON.addAll({'body': response.data});
        final hasErrorCode = responseJSON.containsKey("errorCode");
        if (!hasErrorCode) {
          responseJSON.addAll({'errorCode': statusCode});
        }
        return _handleErrorResponse(NeoError.fromJson(responseJSON), call);
      } on MissingRequiredKeysException {
        final error = NeoError(responseCode: statusCode);
        return _handleErrorResponse(error, call);
      } catch (e) {
        _neoLogger.logError(
          "[NeoNetworkManager]: Service call failed! Status code: $statusCode.Endpoint: ${call.endpoint}",
        );
        return _handleErrorResponse(NeoError(responseCode: statusCode), call);
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
    return NeoResponse.error(error, error.responseCode);
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

  Future<void> _initHttpClient() async {
    if (kIsWeb) {
      return;
    }

    final userAgent = defaultHeaders[NeoNetworkHeaderKey.userAgent];
    final client = HttpClient(context: _enableSslPinning ? await _getSecurityContext : null)..userAgent = userAgent;

    if (_enableSslPinning) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => false;
    }

    httpClient.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () => client);
    httpClient.interceptors.addAll([
      ConstantHeadersRequestInterceptor(
        defaultHeaders: defaultHeaders,
        secureStorage: secureStorage,
        neoSharedPrefs: neoSharedPrefs,
      ),
      DynamicHeadersRequestInterceptor(secureStorage: secureStorage),
      UnauthorizedResponseInterceptor(
        secureStorage: secureStorage,
        onInvalidTokenError: onInvalidTokenError,
        onRequestSucceed: onRequestSucceed,
        onRequestFailed: onRequestFailed,
      ),
    ]);
  }

  void _logResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final logLevel = isSuccess ? Level.trace : Level.warning;
    switch (logScale) {
      case NeoNetworkManagerLogScale.all:
        _neoLogger.logConsole(
          "[NeoNetworkManager] Response code: ${response.statusCode}.\nURL: ${response.requestOptions.uri.path}\nBody: ${response.data}",
          logLevel: logLevel,
        );
      case NeoNetworkManagerLogScale.simplified:
        _neoLogger.logConsole(
          "[NeoNetworkManager] Response code: ${response.statusCode}.\nURL: ${response.requestOptions.uri.path}",
          logLevel: logLevel,
        );
      case NeoNetworkManagerLogScale.none:
    }
  }
}
