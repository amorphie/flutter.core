// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_active_host.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HttpActiveHost _$HttpActiveHostFromJson(Map<String, dynamic> json) =>
    HttpActiveHost(
      host: json['host'] as String? ?? '',
      mtlsHost: json['mtls-host'] as String? ?? '',
      retryCount: (json['retry-count'] as num?)?.toInt() ?? 0,
    );
