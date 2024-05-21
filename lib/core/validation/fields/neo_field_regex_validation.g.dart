// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_field_regex_validation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoFieldRegexValidation _$NeoFieldRegexValidationFromJson(
        Map<String, dynamic> json) =>
    NeoFieldRegexValidation(
      regex: json['regex'] as String?,
      message: json['message'] as String?,
    );

const _$NeoFieldRegexValidationFieldMap = <String, String>{
  'regex': 'regex',
  'message': 'message',
};

Map<String, dynamic> _$NeoFieldRegexValidationToJson(
        NeoFieldRegexValidation instance) =>
    <String, dynamic>{
      'regex': instance.regex,
      'message': instance.message,
    };
