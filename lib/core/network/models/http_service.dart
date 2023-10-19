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

import 'package:burgan_core/core/network/models/http_method.dart';
import 'package:json_annotation/json_annotation.dart';

part 'http_service.g.dart';

@JsonSerializable(createToJson: false)
class HttpService {
  @JsonKey(name: 'key', defaultValue: "")
  final String key;

  @JsonKey(name: 'method', defaultValue: HttpMethod.get)
  final HttpMethod method;

  @JsonKey(name: 'host', defaultValue: "")
  final String host;

  @JsonKey(name: 'name', defaultValue: "")
  final String name;

  const HttpService({required this.key, required this.method, required this.host, required this.name});

  factory HttpService.fromJson(Map<String, dynamic> json) => _$HttpServiceFromJson(json);
}
