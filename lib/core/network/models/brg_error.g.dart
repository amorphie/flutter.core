// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brg_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrgError _$BrgErrorFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['errorCode', 'message'],
  );
  return BrgError(
    errorCode: json['errorCode'] as String?,
    message: json['message'] as String?,
  );
}
