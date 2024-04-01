// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoDeviceInfo _$NeoDeviceInfoFromJson(Map<String, dynamic> json) =>
    NeoDeviceInfo(
      model: json['model'] as String,
      platform: json['platform'] as String,
      version: json['version'] as String,
    );

Map<String, dynamic> _$NeoDeviceInfoToJson(NeoDeviceInfo instance) =>
    <String, dynamic>{
      'model': instance.model,
      'platform': instance.platform,
      'version': instance.version,
    };
