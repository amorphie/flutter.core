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

import 'package:equatable/equatable.dart';
import 'package:neo_core/core/network/query_providers/http_query_provider.dart';

class NeoHttpCall extends Equatable {
  final String endpoint;

  final Map<String, dynamic> body;

  final Map<String, String>? pathParameters;

  final List<HttpQueryProvider> queryProviders;

  final bool useHttps;

  @override
  List<Object?> get props => [endpoint, body, pathParameters, queryProviders, useHttps];

  const NeoHttpCall({
    required this.endpoint,
    this.body = const {},
    this.queryProviders = const [],
    this.useHttps = true,
    this.pathParameters,
  });
}
