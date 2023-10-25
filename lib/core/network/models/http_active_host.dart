/*
 * neo_core
 *
 * Created on 18/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:json_annotation/json_annotation.dart';

part 'http_active_host.g.dart';

@JsonSerializable(createToJson: false)
class HttpActiveHost {
  @JsonKey(name: 'host', defaultValue: "")
  final String host;

  const HttpActiveHost({required this.host});

  factory HttpActiveHost.fromJson(Map<String, dynamic> json) => _$HttpActiveHostFromJson(json);
}
