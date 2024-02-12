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

const _$NeoErrorDisplayMethodEnumMap = {
  NeoErrorDisplayMethod.popup: 'popup',
  NeoErrorDisplayMethod.inline: 'inline',
};
