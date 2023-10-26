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
import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/neo_core.dart';
import 'package:uuid/uuid.dart';

class NeoNetworkManager {
  NeoNetworkManager._();

  static NeoNetworkManager shared = NeoNetworkManager._();
  static HttpClientConfig? _httpClientConfig;

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

  Future<Map<String, dynamic>> call(
    String endpoint, {
    Object body = const {},
    Map<String, String>? pathParameters,
    List<HttpQueryProvider> queryProviders = const [],
    bool useHttps = true,
  }) async {
    final fullPath = _httpClientConfig?.getServiceUrlByKey(endpoint, parameters: pathParameters, useHttps: useHttps);
    final method = _httpClientConfig?.getServiceMethodByKey(endpoint);
    if (fullPath == null || method == null) {
      // TODO: Throw custom exception
      throw NeoException(error: NeoError.defaultError());
    }
    switch (method) {
      case HttpMethod.get:
        return await _requestGet(fullPath, queryProviders: queryProviders);
      case HttpMethod.post:
        return await _requestPost(fullPath, body, queryProviders: queryProviders);
      case HttpMethod.delete:
        return await _requestDelete(fullPath);
    }
  }

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
    Object body, {
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
    Object? body,
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

  static Future<Map<String, dynamic>> _createResponseMap(http.Response? response) async {
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

  Future<HttpClientConfig?> _fetchHttpClientConfig(String httpConfigEndpoint) async {
    final responseJson = await _requestGet(httpConfigEndpoint);
    return HttpClientConfig.fromJson(responseJson);
  }
}
