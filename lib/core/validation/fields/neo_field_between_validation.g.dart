// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_field_between_validation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoFieldBetweenValidation _$NeoFieldBetweenValidationFromJson(
        Map<String, dynamic> json) =>
    NeoFieldBetweenValidation(
      start: json['start'] as int?,
      end: json['end'] as int?,
      message: json['message'] as String?,
    );

const _$NeoFieldBetweenValidationFieldMap = <String, String>{
  'start': 'start',
  'end': 'end',
  'message': 'message',
};

Map<String, dynamic> _$NeoFieldBetweenValidationToJson(
        NeoFieldBetweenValidation instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'message': instance.message,
    };
