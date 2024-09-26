// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_signalr_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoSignalREvent _$NeoSignalREventFromJson(Map<String, dynamic> json) =>
    NeoSignalREvent(
      eventId: json['id'] as String,
      type: json['type'] as String,
      status: json['subject'] as String,
      transition:
          NeoSignalRTransition.fromJson(json['data'] as Map<String, dynamic>),
      previousEvents: (json['oldHubValues'] as List<dynamic>?)
              ?.map((e) => NeoSignalREvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
