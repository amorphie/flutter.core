/*
 * neo_core
 *
 * Created on 23/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/network/models/neo_error.dart';

sealed class NeoResponse {
  final int statusCode;
  final Map<String, String> headers;

  const NeoResponse({required this.statusCode, required this.headers});

  bool get isSuccess {
    return switch (this) {
      NeoSuccessResponse _ => true,
      NeoErrorResponse _ => false,
    };
  }

  bool get isError => !isSuccess;

  NeoSuccessResponse get asSuccess {
    return this as NeoSuccessResponse;
  }

  NeoErrorResponse get asError {
    return this as NeoErrorResponse;
  }

  factory NeoResponse.success(
    Map<String, dynamic> data, {
    required int statusCode,
    required Map<String, String> responseHeaders,
  }) =>
      NeoSuccessResponse(data, statusCode: statusCode, headers: responseHeaders);

  factory NeoResponse.error(NeoError error, {required Map<String, String> responseHeaders}) => NeoErrorResponse(
        error,
        statusCode: error.responseCode,
        headers: responseHeaders,
      );
}

final class NeoSuccessResponse extends NeoResponse {
  const NeoSuccessResponse(this.data, {required super.statusCode, required super.headers});

  final Map<String, dynamic> data;
}

final class NeoErrorResponse extends NeoResponse {
  const NeoErrorResponse(this.error, {required super.statusCode, required super.headers});

  final NeoError error;
}
