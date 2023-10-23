/*
 * burgan_core
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

import 'package:burgan_core/burgan_core.dart';
import 'package:burgan_core/core/network/models/base_response.dart';
import 'package:burgan_core/core/network/models/http_client_config.dart';
import 'package:burgan_core/core/network/models/http_method.dart';
import 'package:burgan_core/core/network/models/neo_response.dart';
import 'package:burgan_core/core/storage/shared_preferences_helper.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

class NeoNetworkManager {
  final bool useHttps;

  static HttpClientConfig? _httpClientConfig;

  NeoNetworkManager({this.useHttps = true});

  static Future init(String httpConfigEndpoint) async {
    if (_httpClientConfig != null) {
      return;
    }
    try {
      _httpClientConfig = await _fetchHttpClientConfig(httpConfigEndpoint);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<NeoResponse<T>> call<T extends BaseResponse>(
    String endpoint, {
    Object body = const {},
    Map<String, String>? pathParameters,
    List<HttpQueryProvider> queryProviders = const [],
  }) async {
    final fullPath = _httpClientConfig?.getServiceUrlByKey(endpoint, parameters: pathParameters, useHttps: useHttps);
    final method = _httpClientConfig?.getServiceMethodByKey(endpoint);
    if (fullPath == null || method == null) {
      return NeoResponse.error(BrgError.defaultError());
    }
    switch (method) {
      case HttpMethod.get:
        return await _requestGet<T>(fullPath, queryProviders: queryProviders);
      case HttpMethod.post:
        return await _requestPost<T>(fullPath, body, queryProviders: queryProviders);
      case HttpMethod.delete:
        return await _requestDelete<T>(fullPath);
    }
  }

  static Map<String, String> get _defaultHeaders {
    final sharedPreferencesHelper = SharedPreferencesHelper.shared;
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

  static Future<NeoResponse<T>> _requestGet<T extends BaseResponse>(
    String fullPath, {
    List<HttpQueryProvider> queryProviders = const [],
  }) async {
    String fullPathWithQueries = _getFullPathWithQueries(fullPath, queryProviders);
    final response = await http.get(
      Uri.parse(fullPathWithQueries),
      headers: _defaultHeaders,
    );
    return _createResponseMap<T>(response);
  }

  Future<NeoResponse<T>> _requestPost<T extends BaseResponse>(
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
    return _createResponseMap<T>(response);
  }

  Future<NeoResponse<T>> _requestDelete<T extends BaseResponse>(
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
    return _createResponseMap<T>(response);
  }

  static String _getFullPathWithQueries(String fullPath, List<HttpQueryProvider> queryProviders) {
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

  static Future<NeoResponse<T>> _createResponseMap<T extends BaseResponse>(http.Response? response) async {
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
      return NeoResponse.success((T as BaseResponse).fromJson(responseJSON ?? {}) as T);
    } else {
      try {
        return NeoResponse.error(BrgError.fromJson(responseJSON ?? {}));
      } on MissingRequiredKeysException {
        final error = BrgError(
          httpStatusCode: response.statusCode,
          errorCode: '${response.statusCode}',
          message: "Teknik bir hata meydana geldi, lütfen daha sonra tekrar deneyiniz.",
        );
        return NeoResponse.error(error);
      } on Exception catch (e) {
        return NeoResponse.error(
          BrgError(
            httpStatusCode: -1,
            errorCode: '-1',
            message: e.toString(),
          ),
        );
      }
    }
  }

  static Future<HttpClientConfig?> _fetchHttpClientConfig(String httpConfigEndpoint) async {
    try {
      final responseJson = await _requestGet(httpConfigEndpoint);
      if (responseJson.isSuccess) {
        return HttpClientConfig.fromJson((responseJson as NeoSuccess).data);
      }
      return null;
    } on Exception catch (_) {
      return null;
    }
  }
}
