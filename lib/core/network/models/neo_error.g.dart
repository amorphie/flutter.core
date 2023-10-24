// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoError _$NeoErrorFromJson(Map<String, dynamic> json) => NeoError(
      responseCode: json['response-code'] as int? ?? 400,
      displayMode: $enumDecodeNullable(
              _$NeoErrorDisplayMethodEnumMap, json['display-mode']) ??
          _Constants.defaultErrorDisplayMode,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => NeoErrorMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          _Constants.defaultErrorMessages,
    );

const _$NeoErrorDisplayMethodEnumMap = {
  NeoErrorDisplayMethod.popup: 'popup',
  NeoErrorDisplayMethod.inline: 'inline',
};
