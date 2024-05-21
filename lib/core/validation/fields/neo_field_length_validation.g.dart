// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_field_length_validation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoFieldLengthValidation _$NeoFieldLengthValidationFromJson(
        Map<String, dynamic> json) =>
    NeoFieldLengthValidation(
      length: json['length'] as int?,
      message: json['message'] as String?,
    );

const _$NeoFieldLengthValidationFieldMap = <String, String>{
  'length': 'length',
  'message': 'message',
};

Map<String, dynamic> _$NeoFieldLengthValidationToJson(
        NeoFieldLengthValidation instance) =>
    <String, dynamic>{
      'length': instance.length,
      'message': instance.message,
    };
