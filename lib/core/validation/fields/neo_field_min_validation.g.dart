// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_field_min_validation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoFieldMinValidation _$NeoFieldMinValidationFromJson(
        Map<String, dynamic> json) =>
    NeoFieldMinValidation(
      min: json['min'] as int?,
      message: json['message'] as String?,
    );

const _$NeoFieldMinValidationFieldMap = <String, String>{
  'min': 'min',
  'message': 'message',
};

Map<String, dynamic> _$NeoFieldMinValidationToJson(
        NeoFieldMinValidation instance) =>
    <String, dynamic>{
      'min': instance.min,
      'message': instance.message,
    };
