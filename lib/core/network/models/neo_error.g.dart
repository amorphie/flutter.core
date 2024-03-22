// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoError _$NeoErrorFromJson(Map<String, dynamic> json) => NeoError(
      responseCode:
          json['response-code'] as String? ?? _Constants.defaultErrorCode,
      displayMode: $enumDecodeNullable(
              _$NeoErrorDisplayMethodEnumMap, json['display-mode']) ??
          _Constants.defaultErrorDisplayMode,
      title: json['title'] as String? ?? _Constants.defaultErrorTitle,
      message: json['message'] as String? ?? _Constants.defaultErrorMessage,
    );

Map<String, dynamic> _$NeoErrorToJson(NeoError instance) => <String, dynamic>{
      'response-code': instance.responseCode,
      'display-mode': _$NeoErrorDisplayMethodEnumMap[instance.displayMode]!,
      'title': instance.title,
      'message': instance.message,
    };

const _$NeoErrorDisplayMethodEnumMap = {
  NeoErrorDisplayMethod.popup: 'popup',
  NeoErrorDisplayMethod.inline: 'inline',
};
