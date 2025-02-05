import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/network/models/http_auth_response.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/neo_core.dart';

abstract class _Constants {
  static const int responseCodeUnauthorized = 401;
  static const String endpointGetToken = "get-token";
  static const String requestKeyGrantType = "grant_type";
  static const String requestValueGrantTypeRefreshToken = "refresh_token";
  static const String requestKeyRefreshToken = "refresh_token";
}

class UnauthorizedResponseInterceptor extends Interceptor {
  final NeoCoreSecureStorage secureStorage;
  final Function()? onInvalidTokenError;
  final Function(String endpoint, String? requestId)? onRequestSucceed;
  final Function(NeoError neoError, String requestId)? onRequestFailed;

  UnauthorizedResponseInterceptor({
    required this.secureStorage,
    this.onInvalidTokenError,
    this.onRequestSucceed,
    this.onRequestFailed,
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response == null) {
      return handler.next(err);
    }

    final response = err.response!;
    final neoHttpCall = err.response!.requestOptions.extra[NeoHttpCall.extraKey] as NeoHttpCall;

    if (response.statusCode == _Constants.responseCodeUnauthorized) {
      final refreshToken = await _getRefreshToken();
      if (refreshToken != null) {
        final result = await _refreshAuthDetailsByUsingRefreshToken(refreshToken);
        if (result.isSuccess) {
          final neoResponse = await GetIt.I.get<NeoNetworkManager>().call(neoHttpCall);
          return handler.resolve(
            Response(
              statusCode: neoResponse.statusCode,
              data: Uint8List.fromList(utf8.encode(jsonEncode(neoResponse.asSuccess.data))),
              requestOptions: err.requestOptions,
            ),
          );
        } else {
          await secureStorage.deleteTokensWithRelatedData();
          // onInvalidTokenError?.call();
        }
      }
    }
    return handler.next(err);
  }

  Future<String?> _getRefreshToken() => secureStorage.read(NeoCoreParameterKey.secureStorageRefreshToken);

  Future<NeoResponse> _refreshAuthDetailsByUsingRefreshToken(String refreshToken) async {
    final response = await GetIt.I.get<NeoNetworkManager>().call(
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
      await GetIt.I.get<NeoNetworkManager>().setTokensByAuthResponse(authResponse);
    }
    return response;
  }
}
