// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HttpConfig _$HttpConfigFromJson(Map<String, dynamic> json) => HttpConfig(
      cachePages: json['cache-pages'] as bool? ?? false,
      cacheStorage: json['cache-storage'] as bool? ?? false,
      logLevel: json['log-level'] == null
          ? Level.off
          : HttpConfig._logLevelFromJson(json['log-level'] as String),
      services: (json['services'] as List<dynamic>?)
              ?.map((e) =>
                  HttpOutsourceService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
