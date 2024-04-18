// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_client_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HttpClientConfig _$HttpClientConfigFromJson(Map<String, dynamic> json) =>
    HttpClientConfig(
      hosts: (json['hosts'] as List<dynamic>?)
              ?.map((e) => HttpHostDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      config: HttpConfig.fromJson(json['config'] as Map<String, dynamic>),
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => HttpService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
