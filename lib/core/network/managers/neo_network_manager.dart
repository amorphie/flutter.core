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

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/http_auth_response.dart';
import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/util/device_util/models/neo_device_info.dart';
import 'package:neo_core/neo_core.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';

abstract class _Constants {
  static const int responseCodeUnauthorized = 401;
  static const String wrapperResponseKey = "data";
  static const String endpointGetToken = "get-token";
  static const String headerValueContentType = "application/json";
  static const String headerValueApplication = "burgan-mobile-app";
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

class NeoNetworkManager {
  final HttpClientConfig httpClientConfig;
  final NeoCoreSecureStorage secureStorage;
  final NeoSharedPrefs neoSharedPrefs;
  final String workflowClientId;
  final String workflowClientSecret;
  final String? sslCertificateFilePath;
  final bool enableSslPinning;
  final Function(String endpoint, String? requestId)? onRequestSucceed;
  final Function(NeoError neoError, String requestId)? onRequestFailed;
  late final NeoLogger _neoLogger = GetIt.I.get();

  NeoNetworkManager({
    required this.httpClientConfig,
    required this.secureStorage,
    required this.neoSharedPrefs,
    required this.workflowClientId,
    required this.workflowClientSecret,
    required this.enableSslPinning,
    this.sslCertificateFilePath,
    this.onRequestSucceed,
    this.onRequestFailed,
  });

  Future<Map<String, String>> get _defaultHeaders async {
    final results = await Future.wait([
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
      secureStorage.read(NeoCoreParameterKey.secureStorageTokenId),
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceInfo),
      _authHeader,
    ]);

    final deviceId = results[0] as String? ?? "";
    final tokenId = results[1] as String? ?? "";
    final deviceInfo = results[2] != null ? NeoDeviceInfo.decode(results[2] as String? ?? "") : null;
    final authHeader = results[3] as Map<String, String>? ?? {};

    return {
      NeoNetworkHeaderKey.contentType: _Constants.headerValueContentType,
      NeoNetworkHeaderKey.acceptLanguage: _languageCode,
      NeoNetworkHeaderKey.contentLanguage: _languageCode,
      NeoNetworkHeaderKey.application: _Constants.headerValueApplication,
      NeoNetworkHeaderKey.deviceId: deviceId,
      NeoNetworkHeaderKey.tokenId: tokenId,
      NeoNetworkHeaderKey.requestId: const Uuid().v1(),
      NeoNetworkHeaderKey.deviceInfo: deviceInfo?.model ?? "",
      NeoNetworkHeaderKey.deviceModel: deviceInfo?.model ?? "",
      NeoNetworkHeaderKey.deviceVersion: deviceInfo?.version ?? "",
      NeoNetworkHeaderKey.devicePlatform: deviceInfo?.platform ?? "",
      NeoNetworkHeaderKey.deployment: deviceInfo?.platform ?? "",
    }..addAll(authHeader);
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
      NeoNetworkHeaderKey.user: const Uuid().v1(), // STOPSHIP: Delete it
      NeoNetworkHeaderKey.behalfOfUser: const Uuid().v1(), // STOPSHIP: Delete it
    });

  Future<SecurityContext?> get _getSecurityContext async {
    if (sslCertificateFilePath == null) {
      return null;
    }
    final sslCertificate = await rootBundle.load(sslCertificateFilePath!);
    final securityContext = SecurityContext()..setTrustedCertificatesBytes(sslCertificate.buffer.asInt8List());
    return securityContext;
  }

  // TODO: Return result object to improve error handling
  Future<Map<String, dynamic>> call(NeoHttpCall neoCall) async {
    final fullPath = httpClientConfig.getServiceUrlByKey(
      neoCall.endpoint,
      parameters: neoCall.pathParameters,
      useHttps: neoCall.useHttps,
    );
    final method = httpClientConfig.getServiceMethodByKey(neoCall.endpoint);
    if (fullPath == null || method == null) {
      // TODO: Throw custom exception
      throw NeoException(error: const NeoError());
    }
    await _getTemporaryTokenForNotLoggedInUser(neoCall);
    final http = await _getSSLPinningClient();

    switch (method) {
      case HttpMethod.get:
        return _requestGet(http, fullPath, neoCall);
      case HttpMethod.post:
        return _requestPost(http, fullPath, neoCall);
      case HttpMethod.delete:
        return _requestDelete(http, fullPath, neoCall);
      case HttpMethod.put:
        return _requestPut(http, fullPath, neoCall);
      case HttpMethod.patch:
        return _requestPatch(http, fullPath, neoCall);
    }
  }

  Future<Map<String, dynamic>> _requestGet(http.Client http, String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await http.get(
      Uri.parse(fullPathWithQueries),
      headers: (await _defaultHeaders)..addAll(neoCall.headerParameters),
    );
    return _createResponseMap(response, neoCall);
  }

  Future<Map<String, dynamic>> _requestPost(http.Client http, String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await http.post(
      Uri.parse(fullPathWithQueries),
      headers: (await _defaultPostHeaders)..addAll(neoCall.headerParameters),
      body: json.encode(neoCall.body),
    );
    return _createResponseMap(response, neoCall);
  }

  Future<Map<String, dynamic>> _requestDelete(http.Client http, String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await http.delete(
      Uri.parse(fullPathWithQueries),
      headers: (await _defaultHeaders)..addAll(neoCall.headerParameters),
      body: json.encode(neoCall.body),
    );
    return _createResponseMap(response, neoCall);
  }

  Future<Map<String, dynamic>> _requestPut(http.Client http, String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await http.put(
      Uri.parse(fullPathWithQueries),
      headers: await _defaultPostHeaders,
      body: json.encode(neoCall.body),
    );
    return _createResponseMap(response, neoCall);
  }

  Future<Map<String, dynamic>> _requestPatch(http.Client http, String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await http.patch(
      Uri.parse(fullPathWithQueries),
      headers: await _defaultPostHeaders,
      body: json.encode(neoCall.body),
    );
    return _createResponseMap(response, neoCall);
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

  Future<Map<String, dynamic>> _createResponseMap(http.Response response, NeoHttpCall call) async {
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
    debugPrint("[NeoNetworkManager] Response code: ${response.statusCode}. Body: ${response.body}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      onRequestSucceed?.call(call.endpoint, call.requestId);
      return responseJSON;
    } else if (response.statusCode == _Constants.responseCodeUnauthorized) {
      if (call.endpoint == _Constants.endpointGetToken) {
        final error = NeoError(responseCode: response.statusCode);
        _neoLogger.logError("[NeoNetworkManager]: Token service error!");
        throw NeoException(error: error);
      }
      if (await secureStorage.read(NeoCoreParameterKey.secureStorageRefreshToken) != null) {
        final isTokenRefreshed = await _refreshAuthDetailsByUsingRefreshToken();
        if (isTokenRefreshed) {
          return _retryLastCall(call);
        } else {
          final error = NeoError(responseCode: response.statusCode);
          _neoLogger.logError("[NeoNetworkManager]: Token refresh service error!");
          throw NeoException(error: error);
        }
      } else {
        await _getTemporaryTokenForNotLoggedInUser(call);
        return _retryLastCall(call);
      }
    } else {
      try {
        responseJSON.addAll({'body': response.body});
        final hasErrorCode = responseJSON.containsKey("errorCode");
        if (!hasErrorCode) {
          responseJSON.addAll({'errorCode': response.statusCode});
        }
        final error = NeoError.fromJson(responseJSON);
        throw NeoException(error: error);
      } on MissingRequiredKeysException {
        final error = NeoError(responseCode: response.statusCode);
        throw NeoException(error: error);
      } catch (e) {
        _neoLogger.logError(
          "[NeoNetworkManager]: Service call failed! Status code: ${response.statusCode}.Endpoint: ${call.endpoint}",
        );
        if (e is NeoException) {
          onRequestFailed?.call(e.error, call.requestId ?? call.endpoint);
          rethrow;
        } else {
          final error = NeoError(responseCode: response.statusCode);
          onRequestFailed?.call(error, call.requestId ?? call.endpoint);
          throw NeoException(error: error);
        }
      }
    }
  }

  Future<Map<String, dynamic>> _retryLastCall(NeoHttpCall neoHttpCall) async {
    if (neoHttpCall.retryCount == null) {
      neoHttpCall.setRetryCount(httpClientConfig.getRetryCountByKey(neoHttpCall.endpoint));
    }
    if (_canRetryRequest(neoHttpCall)) {
      neoHttpCall.decreaseRetryCount();
      return call(neoHttpCall);
    } else {
      throw NeoException(error: const NeoError());
    }
  }

  bool _canRetryRequest(NeoHttpCall call) {
    return (call.retryCount ?? 0) > 0;
  }

  Future<bool> _refreshAuthDetailsByUsingRefreshToken() async {
    try {
      final responseJson = await call(
        NeoHttpCall(
          endpoint: _Constants.endpointGetToken,
          body: {
            _Constants.requestKeyGrantType: _Constants.requestValueGrantTypeRefreshToken,
            _Constants.requestKeyRefreshToken: await secureStorage.read(NeoCoreParameterKey.secureStorageRefreshToken),
          },
        ),
      );
      final authResponse = HttpAuthResponse.fromJson(responseJson);
      await Future.wait([
        secureStorage.setAuthToken(authResponse.token),
        secureStorage.write(key: NeoCoreParameterKey.secureStorageRefreshToken, value: authResponse.refreshToken),
      ]);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _getTemporaryTokenForNotLoggedInUser(NeoHttpCall currentCall) async {
    // Prevent infinite call loop
    if (currentCall.endpoint == _Constants.endpointGetToken) {
      return;
    }
    try {
      final authToken = await secureStorage.read(NeoCoreParameterKey.secureStorageAuthToken);
      if (authToken != null && authToken.isNotEmpty) {
        return;
      }

      final responseJson = await call(
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
      final authResponse = HttpAuthResponse.fromJson(responseJson);
      await Future.wait([
        secureStorage.setAuthToken(authResponse.token),
        secureStorage.write(key: NeoCoreParameterKey.secureStorageRefreshToken, value: authResponse.refreshToken),
      ]);
    } catch (_) {
      _neoLogger.logError("[NeoNetworkManager]: Temporary token (for not logged in user) service error!");
    }
  }

  Future<http.Client> _getSSLPinningClient() async {
    if (!enableSslPinning) {
      return http.Client();
    }
    final HttpClient client = HttpClient(context: await _getSecurityContext)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => false;
    return IOClient(client);
  }
}
