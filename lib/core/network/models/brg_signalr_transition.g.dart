// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brg_signalr_transition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BrgSignalRTransition _$BrgSignalRTransitionFromJson(
        Map<String, dynamic> json) =>
    BrgSignalRTransition(
      transitionId: json['transition'] as String,
      pageDetails: json['page'] as Map<String, dynamic>? ?? {},
      errorMessage: json['message'] as String? ?? '',
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
