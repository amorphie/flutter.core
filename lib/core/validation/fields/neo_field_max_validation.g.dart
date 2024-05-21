// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_field_max_validation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoFieldMaxValidation _$NeoFieldMaxValidationFromJson(
        Map<String, dynamic> json) =>
    NeoFieldMaxValidation(
      max: json['max'] as int?,
      message: json['message'] as String?,
    );

const _$NeoFieldMaxValidationFieldMap = <String, String>{
  'max': 'max',
  'message': 'message',
};

Map<String, dynamic> _$NeoFieldMaxValidationToJson(
        NeoFieldMaxValidation instance) =>
    <String, dynamic>{
      'max': instance.max,
      'message': instance.message,
    };
