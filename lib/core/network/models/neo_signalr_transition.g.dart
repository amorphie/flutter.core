// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_signalr_transition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoSignalRTransition _$NeoSignalRTransitionFromJson(
        Map<String, dynamic> json) =>
    NeoSignalRTransition(
      transitionId: json['transition'] as String,
      state: json['state'] as String? ?? '',
      viewSource: json['viewSource'] as String? ?? '',
      pageDetails: json['page'] as Map<String, dynamic>? ?? {},
      initialData: json['data'] as Map<String, dynamic>? ?? {},
      buttonType: json['buttonType'] as String?,
      time: json['time'] as String? ?? '',
      statusMessage: json['message'] as String?,
      statusCode: json['errorCode'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NeoSignalRTransitionToJson(
        NeoSignalRTransition instance) =>
    <String, dynamic>{
      'transition': instance.transitionId,
      'state': instance.state,
      'viewSource': instance.viewSource,
      'page': instance.pageDetails,
      'data': instance.initialData,
      'additionalData': instance.additionalData,
      'message': instance.statusMessage,
      'errorCode': instance.statusCode,
      'buttonType': instance.buttonType,
      'time': instance.time,
    };
