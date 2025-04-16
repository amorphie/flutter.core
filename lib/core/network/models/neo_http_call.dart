/*
 * neo_core
 *
 * Created on 27/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:neo_core/core/network/query_providers/http_query_provider.dart';

// ignore: must_be_immutable
class NeoHttpCall extends Equatable {
  final String endpoint;

  final String? requestId;

  final Map<String, dynamic> body;

  final Map<String, String>? pathParameters;

  final List<HttpQueryProvider> queryProviders;

  final Map<String, String> headerParameters;

  final bool useHttps;

  int? _retryCount;

  int? get retryCount => _retryCount;

  bool enableMtls = false;
  bool signForMtls = false;

  @override
  List<Object?> get props => [
        requestId,
        endpoint,
        body,
        pathParameters,
        queryProviders,
        useHttps,
        enableMtls,
        signForMtls,
      ];

  NeoHttpCall({
    required this.endpoint,
    this.requestId,
    this.body = const {},
    this.queryProviders = const [],
    this.useHttps = true,
    this.pathParameters,
    this.headerParameters = const {},
  });

  void setRetryCount(int retryCount) {
    _retryCount = retryCount;
  }

  void setMtlsStatus({required bool enableMtls, required bool signForMtls}) {
    this.enableMtls = enableMtls;
    this.signForMtls = signForMtls;
  }

  void decreaseRetryCount() {
    _retryCount = max(0, (_retryCount ?? 0) - 1);
  }
}
