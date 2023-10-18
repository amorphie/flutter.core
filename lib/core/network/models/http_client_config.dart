/*
 * burgan_core
 *
 * Created on 18/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:burgan_core/core/network/models/http_host_details.dart';
import 'package:burgan_core/core/network/models/http_service.dart';
import 'package:json_annotation/json_annotation.dart';

part 'http_client_config.g.dart';

@JsonSerializable(createToJson: false)
class HttpClientConfig {
  @JsonKey(name: 'hosts', defaultValue: [])
  final List<HttpHostDetails> hosts;

  @JsonKey(name: 'services', defaultValue: [])
  final List<HttpService> services;

  const HttpClientConfig({required this.hosts, required this.services});

  factory HttpClientConfig.fromJson(Map<String, dynamic> json) => _$HttpClientConfigFromJson(json);
}
