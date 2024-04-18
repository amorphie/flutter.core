// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_outsource_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HttpOutsourceService _$HttpOutsourceServiceFromJson(
        Map<String, dynamic> json) =>
    HttpOutsourceService(
      key: json['key'] as String? ?? '',
      method: $enumDecodeNullable(_$HttpMethodEnumMap, json['method']) ??
          HttpMethod.get,
      url: json['url'] as String? ?? '',
    );

const _$HttpMethodEnumMap = {
  HttpMethod.get: 'GET',
  HttpMethod.post: 'POST',
  HttpMethod.delete: 'DELETE',
  HttpMethod.put: 'PUT',
  HttpMethod.patch: 'PATCH',
};
