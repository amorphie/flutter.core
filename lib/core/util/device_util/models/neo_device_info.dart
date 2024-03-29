/*
 * neo_core
 *
 * Created on 29/3/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'neo_device_info.g.dart';

@JsonSerializable()
class NeoDeviceInfo {
  @JsonKey(name: "model")
  final String model;

  @JsonKey(name: "platform")
  final String platform;

  @JsonKey(name: "version")
  final String version;

  const NeoDeviceInfo({
    required this.model,
    required this.platform,
    required this.version,
  });

  String encode() {
    return jsonEncode(toJson());
  }

  factory NeoDeviceInfo.decode(String data) {
    return NeoDeviceInfo.fromJson(jsonDecode(data));
  }

  Map<String, dynamic> toJson() => _$NeoDeviceInfoToJson(this);

  factory NeoDeviceInfo.fromJson(Map<String, dynamic> json) => _$NeoDeviceInfoFromJson(json);
}
