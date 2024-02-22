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
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/network/models/http_auth_response.dart';
import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/neo_core.dart';
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
}

class NeoNetworkManager {
  final NeoCoreSecureStorage secureStorage;
  final HttpClientConfig httpClientConfig;
  final String workflowClientId;
  final String workflowClientSecret;
  final Function? onRequestSucceed;
  final Function? onRequestFailed;

  NeoNetworkManager({
    required this.httpClientConfig,
    required this.secureStorage,
    required this.workflowClientId,
    required this.workflowClientSecret,
    this.onRequestSucceed,
    this.onRequestFailed,
  });

  Future<Map<String, String>> get _defaultHeaders async {
    final results = await Future.wait([
      secureStorage.getLanguageCode(),
      secureStorage.getDeviceId(),
      secureStorage.getTokenId(),
      secureStorage.getDeviceInfo(),
      _authHeader,
    ]);

    final languageCode = results[0] as String? ?? "";
    final deviceId = results[1] as String? ?? "";
    final tokenId = results[2] as String? ?? "";
    final deviceInfo = results[3] as String? ?? "";
    final authHeader = results[4] as Map<String, String>? ?? {};

    return {
      NeoNetworkHeaderKey.contentType: _Constants.headerValueContentType,
      NeoNetworkHeaderKey.acceptLanguage: '$languageCode-${languageCode.toUpperCase()}',
      NeoNetworkHeaderKey.application: _Constants.headerValueApplication,
      NeoNetworkHeaderKey.deployment: DeviceUtil().getPlatformName(),
      NeoNetworkHeaderKey.deviceId: deviceId,
      NeoNetworkHeaderKey.tokenId: tokenId,
      NeoNetworkHeaderKey.requestId: const Uuid().v1(),
      NeoNetworkHeaderKey.deviceInfo: deviceInfo,
    }..addAll(authHeader);
  }

  Future<Map<String, String>> get _authHeader async {
    final authToken = await secureStorage.getAuthToken();
    return authToken == null ? {} : {NeoNetworkHeaderKey.authorization: 'Bearer $authToken'};
  }

  Future<Map<String, String>> get _defaultPostHeaders async => <String, String>{}
    ..addAll(await _defaultHeaders)
    ..addAll({
      NeoNetworkHeaderKey.user: const Uuid().v1(), // STOPSHIP: Delete it
      NeoNetworkHeaderKey.behalfOfUser: const Uuid().v1(), // STOPSHIP: Delete it
    });

  Future<Map<String, dynamic>> call(NeoHttpCall neoCall) async {
    final fullPath = httpClientConfig.getServiceUrlByKey(
      neoCall.endpoint,
      parameters: neoCall.pathParameters,
      useHttps: neoCall.useHttps,
    );
    final method = httpClientConfig.getServiceMethodByKey(neoCall.endpoint);
    if (fullPath == null || method == null) {
      // TODO: Throw custom exception
      throw NeoException(error: NeoError.defaultError());
    }
    await _getTemporaryTokenForNotLoggedInUser(neoCall);

    switch (method) {
      case HttpMethod.get:
        return _requestGet(fullPath, neoCall);
      case HttpMethod.post:
        return _requestPost(fullPath, neoCall);
      case HttpMethod.delete:
        return _requestDelete(fullPath, neoCall);
      case HttpMethod.put:
        return _requestPut(fullPath, neoCall);
      case HttpMethod.patch:
        return _requestPatch(fullPath, neoCall);
    }
  }

  Future<Map<String, dynamic>> _requestGet(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await http.get(
      Uri.parse(fullPathWithQueries),
      headers: (await _defaultHeaders)..addAll(neoCall.headerParameters),
    );
    return _createResponseMap(response, neoCall);
  }

  Future<Map<String, dynamic>> _requestPost(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await http.post(
      Uri.parse(fullPathWithQueries),
      headers: (await _defaultPostHeaders)..addAll(neoCall.headerParameters),
      body: json.encode(neoCall.body),
    );
    return _createResponseMap(response, neoCall);
  }

  Future<Map<String, dynamic>> _requestDelete(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await http.delete(
      Uri.parse(fullPathWithQueries),
      headers: (await _defaultHeaders)..addAll(neoCall.headerParameters),
      body: json.encode(neoCall.body),
    );
    return _createResponseMap(response, neoCall);
  }

  Future<Map<String, dynamic>> _requestPut(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await http.put(
      Uri.parse(fullPathWithQueries),
      headers: await _defaultPostHeaders,
      body: json.encode(neoCall.body),
    );
    return _createResponseMap(response, neoCall);
  }

  Future<Map<String, dynamic>> _requestPatch(String fullPath, NeoHttpCall neoCall) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, neoCall.queryProviders);
    final response = await http.patch(
      Uri.parse(fullPathWithQueries),
      headers: await _defaultPostHeaders,
      body: json.encode(neoCall.body),
    );
    return _createResponseMap(response, neoCall);
  }

  String _getFullPathWithQueries(String fullPath, List<HttpQueryProvider> queryProviders) {
    if (queryProviders.isEmpty) {
      return fullPath;
    }
    String fullPathWithQueries = fullPath;
    fullPathWithQueries += "?";
    for (final provider in queryProviders) {
      provider.queryParameters.forEach((key, value) {
        fullPathWithQueries += "$key=$value";
      });
      if (queryProviders.indexOf(provider) != queryProviders.length - 1) {
        fullPathWithQueries += "&";
      }
    }
    return fullPathWithQueries;
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
      onRequestSucceed?.call();
      return responseJSON;
    } else if (response.statusCode == _Constants.responseCodeUnauthorized) {
      if (call.endpoint == _Constants.endpointGetToken) {
        onRequestFailed?.call();
        throw NeoException(error: NeoError.defaultError());
      }
      if (await secureStorage.getRefreshToken() != null) {
        final isTokenRefreshed = await _refreshAuthDetailsByUsingRefreshToken();
        if (isTokenRefreshed) {
          return _retryLastCall(call);
        } else {
          onRequestFailed?.call();
          throw NeoException(error: NeoError.defaultError());
        }
      } else {
        await _getTemporaryTokenForNotLoggedInUser(call);
        return _retryLastCall(call);
      }
    } else {
      onRequestFailed?.call();
      try {
        final error = NeoError.fromJson(responseJSON);
        throw NeoException(error: error);
      } on MissingRequiredKeysException {
        final error = NeoError(responseCode: response.statusCode.toString());
        throw NeoException(error: error);
      } catch (e) {
        if (e is NeoException) {
          rethrow;
        }
        throw NeoException(error: const NeoError(responseCode: "-1"));
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
      throw NeoException(error: NeoError.defaultError());
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
            _Constants.requestKeyRefreshToken: await secureStorage.getRefreshToken(),
          },
        ),
      );
      final authResponse = HttpAuthResponse.fromJson(responseJson);
      await Future.wait([
        secureStorage.setAuthToken(authResponse.token),
        secureStorage.setRefreshToken(authResponse.refreshToken),
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
      final authToken = await secureStorage.getAuthToken();
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
        secureStorage.setRefreshToken(authResponse.refreshToken),
      ]);
    } catch (_) {
      // No-op
    }
  }
}
