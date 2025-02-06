import 'dart:async';

import 'package:dio/dio.dart';

abstract class _Constants {
  static const String endpointToken = "/ebanking/token";
}

class TokenRequestInterceptor extends Interceptor {
  static Completer? _completer;

  @override
  Future onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final isTokenEndpoint = options.path.endsWith(_Constants.endpointToken);
    if (isTokenEndpoint && _completer == null) {
      _completer = Completer();
    } else  {
      await _completer?.future;
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.path.endsWith(_Constants.endpointToken)) {
      _completer?.complete();
      _completer = null;
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.requestOptions.path.endsWith(_Constants.endpointToken)) {
      _completer?.complete();
      _completer = null;
    }
    return handler.next(err);
  }
}