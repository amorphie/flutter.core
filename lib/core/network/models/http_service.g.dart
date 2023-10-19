// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HttpService _$HttpServiceFromJson(Map<String, dynamic> json) => HttpService(
      key: json['key'] as String? ?? '',
      method: $enumDecodeNullable(_$HttpMethodEnumMap, json['method']) ??
          HttpMethod.get,
      host: json['host'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );

const _$HttpMethodEnumMap = {
  HttpMethod.get: 'GET',
  HttpMethod.post: 'POST',
  HttpMethod.delete: 'DELETE',
};
