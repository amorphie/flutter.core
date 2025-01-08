/*
 * neo_core
 *
 * Created on 15/1/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:json_annotation/json_annotation.dart';

part 'neo_core_register_device_request.g.dart';

@JsonSerializable(createFactory: false)
class NeoCoreRegisterDeviceRequest {
  @JsonKey(name: "deviceId", defaultValue: "")
  final String deviceId;

  @JsonKey(name: "installationId", defaultValue: "")
  final String installationId;

  @JsonKey(name: "deviceToken", defaultValue: "")
  final String deviceToken;

  @JsonKey(name: "deviceModel", defaultValue: "")
  final String deviceModel;

  @JsonKey(name: "devicePlatform", defaultValue: "")
  final String devicePlatform;

  @JsonKey(name: "deviceVersion", defaultValue: "")
  final String deviceVersion;

  @JsonKey(name: "IsGoogleServiceAvailable")
  final bool isGoogleServiceAvailable;

  const NeoCoreRegisterDeviceRequest({
    required this.deviceId,
    required this.installationId,
    required this.deviceToken,
    required this.deviceModel,
    required this.devicePlatform,
    required this.deviceVersion,
    required this.isGoogleServiceAvailable,
  });

  Map<String, dynamic> toJson() => _$NeoCoreRegisterDeviceRequestToJson(this);
}
