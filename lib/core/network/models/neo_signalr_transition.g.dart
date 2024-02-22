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
      message: json['message'] as String?,
      responseCode: json['errorCode'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
