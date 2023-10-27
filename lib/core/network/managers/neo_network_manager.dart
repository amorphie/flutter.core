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

import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/network/models/http_auth_response.dart';
import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/neo_core.dart';
import 'package:uuid/uuid.dart';

abstract class _Constants {
  static const int responseCodeUnauthorized = 401;
}

class NeoNetworkManager {
  NeoNetworkManager._();

  static NeoNetworkManager shared = NeoNetworkManager._();
  static HttpClientConfig? _httpClientConfig;
  static NeoHttpCall? _lastCall;

  static Map<String, String> get _defaultHeaders {
    final sharedPreferencesHelper = NeoCoreSharedPreferences.shared;
    final languageCode = sharedPreferencesHelper.getLanguageCode().orEmpty;
    final authToken = sharedPreferencesHelper.getAuthToken();

    return {
      'Accept-Language': '$languageCode-${languageCode.toUpperCase()}',
      'X-Application': 'burgan-mobile-app',
      'X-Deployment': DeviceUtil().getPlatformName(),
      'X-Device-Id': sharedPreferencesHelper.getDeviceId().orEmpty,
      'X-Token-Id': sharedPreferencesHelper.getTokenId().orEmpty,
      'X-Request-Id': const Uuid().v1(),
      'X-Device-Info': sharedPreferencesHelper.getDeviceInfo().orEmpty,
      'Authorization': authToken == null ? '' : 'Bearer ${sharedPreferencesHelper.getAuthToken()}'
    };
  }

  Map<String, String> get _defaultPostHeaders => <String, String>{}
    ..addAll(_defaultHeaders)
    ..addAll({
      'Content-Type': 'application/json',
      'User': const Uuid().v1(), // TODO: Get it from storage
      'Behalf-Of-User': const Uuid().v1(), // TODO: Get it from storage
    });

  static Future init(String httpConfigEndpoint) async {
    if (_httpClientConfig != null) {
      return;
    }
    try {
      _httpClientConfig = await shared._fetchHttpClientConfig(httpConfigEndpoint);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> call(NeoHttpCall neoCall) async {
    _lastCall = neoCall;
    final fullPath = _httpClientConfig?.getServiceUrlByKey(
      neoCall.endpoint,
      parameters: neoCall.pathParameters,
      useHttps: neoCall.useHttps,
    );
    final method = _httpClientConfig?.getServiceMethodByKey(neoCall.endpoint);
    if (fullPath == null || method == null) {
      // TODO: Throw custom exception
      throw NeoException(error: NeoError.defaultError());
    }
    switch (method) {
      case HttpMethod.get:
        return await _requestGet(fullPath, queryProviders: neoCall.queryProviders);
      case HttpMethod.post:
        return await _requestPost(fullPath, neoCall.body, queryProviders: neoCall.queryProviders);
      case HttpMethod.delete:
        return await _requestDelete(fullPath);
    }
  }

  Future<Map<String, dynamic>> _requestGet(
    String fullPath, {
    List<HttpQueryProvider> queryProviders = const [],
  }) async {
    String fullPathWithQueries = _getFullPathWithQueries(fullPath, queryProviders);
    final response = await http.get(
      Uri.parse(fullPathWithQueries),
      headers: _defaultHeaders,
    );
    return _createResponseMap(response);
  }

  Future<Map<String, dynamic>> _requestPost(
    String fullPath,
    Map<String, dynamic> body, {
    List<HttpQueryProvider> queryProviders = const [],
  }) async {
    String fullPathWithQueries = _getFullPathWithQueries(fullPath, queryProviders);
    final response = await http.post(
      Uri.parse(fullPathWithQueries),
      headers: _defaultPostHeaders,
      body: json.encode(body),
    );
    return _createResponseMap(response);
  }

  Future<Map<String, dynamic>> _requestDelete(
    String fullPath, {
    Map<String, dynamic>? body,
    List<HttpQueryProvider> queryProviders = const [],
  }) async {
    String fullPathWithQueries = _getFullPathWithQueries(fullPath, queryProviders);
    final response = await http.delete(
      Uri.parse(fullPathWithQueries),
      headers: _defaultHeaders,
      body: json.encode(body),
    );
    return _createResponseMap(response);
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

  Future<Map<String, dynamic>> _createResponseMap(http.Response? response) async {
    Map<String, dynamic>? responseJSON;
    if (response?.body != null) {
      try {
        const utf8Decoder = Utf8Decoder();
        final responseString = utf8Decoder.convert(response!.bodyBytes);
        responseJSON = json.decode(responseString) as Map<String, dynamic>;
      } on Exception {
        responseJSON = {};
      }
    }

    if (response!.statusCode >= 200 && response.statusCode < 300) {
      return responseJSON ?? {};
    } else if (response.statusCode == _Constants.responseCodeUnauthorized) {
      final isTokenRefreshed = await _refreshAuthDetailsByUsingRefreshToken();
      if (isTokenRefreshed) {
        _retryLastCall();
      } else {
        // TODO: Return error
      }
      return {}; // STOPSHIP: Update with response
    } else {
      try {
        final error = NeoError.fromJson(responseJSON ?? {});
        throw NeoException(error: error);
      } on MissingRequiredKeysException {
        final error = NeoError(responseCode: response.statusCode.toString());
        throw NeoException(error: error);
      } on Exception catch (e) {
        if (e is NeoException) {
          rethrow;
        }
        throw NeoException(error: const NeoError(responseCode: "-1"));
      }
    }
  }

  void _retryLastCall() {
    if (_lastCall != null) {
      if (_lastCall!.retryCount == null) {
        _lastCall!.setRetryCount(_httpClientConfig?.getRetryCountByKey(_lastCall!.endpoint) ?? 0);
      }
      if (canRetryRequest(_lastCall!)) {
        _lastCall!.decreaseRetryCount();
        call(_lastCall!);
      }
    }
  }

  bool canRetryRequest(NeoHttpCall call) {
    if (_httpClientConfig == null) {
      return false;
    }
    final retryCount = _httpClientConfig!.getRetryCountByKey(call.endpoint);
    return retryCount > 0;
  }

  Future<HttpClientConfig?> _fetchHttpClientConfig(String httpConfigEndpoint) async {
    final responseJson = await _requestGet(httpConfigEndpoint);
    return HttpClientConfig.fromJson(responseJson);
  }

  Future<bool> _refreshAuthDetailsByUsingRefreshToken() async {
    final sharedPrefs = NeoCoreSharedPreferences.shared;
    try {
      final responseJson = await call(
        NeoHttpCall(
          endpoint: "get-token",
          body: {
            "grant_type": "refresh_token",
            "refresh_token": sharedPrefs.getRefreshToken(),
          },
        ),
      ); // STOPSHIP: Update token endpoint when determined.
      final authResponse = HttpAuthResponse.fromJson(responseJson);
      sharedPrefs.setAuthToken(authResponse.token);
      if (authResponse.refreshToken.isNotEmpty) {
        sharedPrefs.setRefreshToken(authResponse.refreshToken);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
