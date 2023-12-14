// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_signalr_transition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoSignalRTransition _$NeoSignalRTransitionFromJson(
        Map<String, dynamic> json) =>
    NeoSignalRTransition(
      transitionId: json['transition'] as String,
      pageId: json['state'] as String? ?? '',
      pageDetails: json['page'] as Map<String, dynamic>? ?? {},
      initialData: json['data'] as Map<String, dynamic>? ?? {},
      errorMessage: json['message'] as String? ?? '',
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
