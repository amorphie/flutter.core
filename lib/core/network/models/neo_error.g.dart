// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoError _$NeoErrorFromJson(Map<String, dynamic> json) => NeoError(
      responseCode: json['errorCode'] as int? ?? _Constants.defaultErrorCode,
      displayMode: $enumDecodeNullable(
              _$NeoErrorDisplayMethodEnumMap, json['errorType']) ??
          _Constants.defaultErrorDisplayMode,
      error: json['error'] == null
          ? const NeoErrorDetail()
          : NeoErrorDetail.fromJson(json['error'] as Map<String, dynamic>),
      body: json['body'],
    );

Map<String, dynamic> _$NeoErrorToJson(NeoError instance) => <String, dynamic>{
      'errorCode': instance.responseCode,
      'errorType': _$NeoErrorDisplayMethodEnumMap[instance.displayMode]!,
      'error': instance.error,
      'body': instance.body,
    };

const _$NeoErrorDisplayMethodEnumMap = {
  NeoErrorDisplayMethod.popup: 'popup',
  NeoErrorDisplayMethod.inline: 'inline',
};

NeoErrorDetail _$NeoErrorDetailFromJson(Map<String, dynamic> json) =>
    NeoErrorDetail(
      icon: json['icon'] as String? ?? _Constants.defaultErrorIcon,
      title: json['title'] as String? ?? _Constants.defaultErrorTitle,
      description:
          json['description'] as String? ?? _Constants.defaultErrorMessage,
      closeButton: json['closeButton'] as String? ??
          _Constants.defaultErrorCloseButtonText,
    );

Map<String, dynamic> _$NeoErrorDetailToJson(NeoErrorDetail instance) =>
    <String, dynamic>{
      'icon': instance.icon,
      'title': instance.title,
      'description': instance.description,
      'closeButton': instance.closeButton,
    };
