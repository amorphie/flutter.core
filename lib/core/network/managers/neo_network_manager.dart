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
  static const String wrapperResponseKey = "data";
}

class NeoNetworkManager {
  final NeoCoreSecureStorage secureStorage;
  final HttpClientConfig httpClientConfig;

  NeoNetworkManager({
    required this.httpClientConfig,
    required this.secureStorage,
  });

  static NeoHttpCall? _lastCall;

  Future<Map<String, String>> get _defaultHeaders async {
    final results = await Future.wait([
      secureStorage.getLanguageCode(),
      secureStorage.getDeviceId(),
      secureStorage.getTokenId(),
      secureStorage.getDeviceInfo(),
      _authHeader,
      _customerIdHeader,
    ]);

    final languageCode = results[0] as String? ?? "";
    final deviceId = results[1] as String? ?? "";
    final tokenId = results[2] as String? ?? "";
    final deviceInfo = results[3] as String? ?? "";
    final authHeader = results[4] as Map<String, String>? ?? {};
    final customerIdHeader = results[5] as Map<String, String>? ?? {};

    return {
      'Content-Type': 'application/json',
      'Accept-Language': '$languageCode-${languageCode.toUpperCase()}',
      'X-Application': 'burgan-mobile-app',
      'X-Deployment': DeviceUtil().getPlatformName(),
      'X-Device-Id': deviceId,
      'X-Token-Id': tokenId,
      'X-Request-Id': const Uuid().v1(),
      'X-Device-Info': deviceInfo,
    }
      ..addAll(authHeader)
      ..addAll(customerIdHeader);
  }

  Future<Map<String, String>> get _authHeader async {
    final authToken = await secureStorage.getAuthToken();
    return authToken == null ? {} : {'Authorization': 'Bearer $authToken'};
  }

  Future<Map<String, String>> get _customerIdHeader async {
    final customerId = await secureStorage.getCustomerId();
    return customerId == null ? {} : {'A-Customer': customerId};
  }

  Future<Map<String, String>> get _defaultPostHeaders async => <String, String>{}
    ..addAll(await _defaultHeaders)
    ..addAll({
      'User': const Uuid().v1(), // STOPSHIP: Delete it
      'Behalf-Of-User': const Uuid().v1(), // STOPSHIP: Delete it
    });

  Future<Map<String, dynamic>> call(NeoHttpCall neoCall) async {
    _lastCall = neoCall;
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
    switch (method) {
      case HttpMethod.get:
        return _requestGet(fullPath, queryProviders: neoCall.queryProviders);
      case HttpMethod.post:
        return _requestPost(fullPath, neoCall.body, queryProviders: neoCall.queryProviders);
      case HttpMethod.delete:
        return _requestDelete(fullPath);
    }
  }

  Future<Map<String, dynamic>> _requestGet(
    String fullPath, {
    List<HttpQueryProvider> queryProviders = const [],
  }) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, queryProviders);
    final response = await http.get(
      Uri.parse(fullPathWithQueries),
      headers: await _defaultHeaders,
    );
    return _createResponseMap(response);
  }

  Future<Map<String, dynamic>> _requestPost(
    String fullPath,
    Map<String, dynamic> body, {
    List<HttpQueryProvider> queryProviders = const [],
  }) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, queryProviders);
    final response = await http.post(
      Uri.parse(fullPathWithQueries),
      headers: await _defaultPostHeaders,
      body: json.encode(body),
    );
    return _createResponseMap(response);
  }

  Future<Map<String, dynamic>> _requestDelete(
    String fullPath, {
    Map<String, dynamic>? body,
    List<HttpQueryProvider> queryProviders = const [],
  }) async {
    final fullPathWithQueries = _getFullPathWithQueries(fullPath, queryProviders);
    final response = await http.delete(
      Uri.parse(fullPathWithQueries),
      headers: await _defaultHeaders,
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
        final decodedResponse = json.decode(responseString);
        if (decodedResponse is Map<String, dynamic>) {
          responseJSON = decodedResponse;
        } else {
          responseJSON = {_Constants.wrapperResponseKey: decodedResponse};
        }
      } catch (_) {
        responseJSON = {};
      }
    }

    if (response!.statusCode >= 200 && response.statusCode < 300) {
      return responseJSON ?? {};
    } else if (response.statusCode == _Constants.responseCodeUnauthorized) {
      final isTokenRefreshed = await _refreshAuthDetailsByUsingRefreshToken();
      if (isTokenRefreshed) {
        await _retryLastCall();
      } else {
        throw NeoException(error: NeoError.defaultError());
      }
      return {}; // STOPSHIP: Update with response
    } else {
      try {
        final error = NeoError.fromJson(responseJSON ?? {});
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

  Future _retryLastCall() async {
    if (_lastCall != null) {
      if (_lastCall!.retryCount == null) {
        _lastCall!.setRetryCount(httpClientConfig.getRetryCountByKey(_lastCall!.endpoint));
      }
      if (_canRetryRequest(_lastCall!)) {
        _lastCall!.decreaseRetryCount();
        await call(_lastCall!);
      } else {
        throw NeoException(error: NeoError.defaultError());
      }
    }
  }

  bool _canRetryRequest(NeoHttpCall call) {
    return (call.retryCount ?? 0) > 0;
  }

  Future<bool> _refreshAuthDetailsByUsingRefreshToken() async {
    try {
      final responseJson = await call(
        NeoHttpCall(
          endpoint: "get-token",
          body: {
            "grant_type": "refresh_token",
            "refresh_token": await secureStorage.getRefreshToken(),
          },
        ),
      ); // STOPSHIP: Update token endpoint when determined.
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
}
