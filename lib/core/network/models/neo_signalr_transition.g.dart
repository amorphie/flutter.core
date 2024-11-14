// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_signalr_transition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoSignalRTransition _$NeoSignalRTransitionFromJson(
        Map<String, dynamic> json) =>
    NeoSignalRTransition(
      instanceId: json['instanceId'] as String? ?? '',
      transitionId: json['transition'] as String,
      state: json['state'] as String? ?? '',
      viewSource: json['viewSource'] as String? ?? '',
      pageDetails: json['page'] as Map<String, dynamic>? ?? {},
      initialData: json['data'] as Map<String, dynamic>? ?? {},
      buttonType: json['buttonType'] as String?,
      time: DateTime.parse(json['time'] as String),
      statusMessage: json['message'] as String?,
      statusCode: json['errorCode'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      dataPageId: json['dataPageId'] as String?,
      workflowStateType: $enumDecodeNullable(
          _$NeoSignalRTransitionStateTypeEnumMap, json['workflowStateType']),
    );

const _$NeoSignalRTransitionStateTypeEnumMap = {
  NeoSignalRTransitionStateType.fail: 'Fail',
  NeoSignalRTransitionStateType.finish: 'Finish',
  NeoSignalRTransitionStateType.partialStart: 'PartialStart',
  NeoSignalRTransitionStateType.standard: 'Standart',
  NeoSignalRTransitionStateType.start: 'Start',
  NeoSignalRTransitionStateType.subFail: 'SubFail',
  NeoSignalRTransitionStateType.subFinish: 'SubFinish',
  NeoSignalRTransitionStateType.subWorkflow: 'SubWorkflow',
};
