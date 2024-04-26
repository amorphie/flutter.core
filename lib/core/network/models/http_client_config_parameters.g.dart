// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_client_config_parameters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HttpClientConfigParameters _$HttpClientConfigParametersFromJson(
        Map<String, dynamic> json) =>
    HttpClientConfigParameters(
      cachePages: json['cache-pages'] as bool? ?? false,
      cacheStorage: json['cache-storage'] as bool? ?? false,
      logLevel: json['log-level'] == null
          ? Level.off
          : HttpClientConfigParameters._logLevelFromJson(
              json['log-level'] as String),
    );
