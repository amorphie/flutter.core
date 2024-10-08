// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_signalr_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoSignalREvent _$NeoSignalREventFromJson(Map<String, dynamic> json) =>
    NeoSignalREvent(
      eventId: json['id'] as String,
      type: $enumDecode(_$NeoSignalREventTypeEnumMap, json['type']),
      status: json['subject'] as String,
      transition:
          NeoSignalRTransition.fromJson(json['data'] as Map<String, dynamic>),
      baseState:
          $enumDecode(_$NeoSignalREventBaseStateEnumMap, json['base-state']),
      previousEvents: (json['oldHubValues'] as List<dynamic>?)
              ?.map((e) => NeoSignalREvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

const _$NeoSignalREventTypeEnumMap = {
  NeoSignalREventType.silent: 'silent',
  NeoSignalREventType.workflow: 'workflow',
};

const _$NeoSignalREventBaseStateEnumMap = {
  NeoSignalREventBaseState.newState: 'New',
  NeoSignalREventBaseState.inProgress: 'InProgress',
  NeoSignalREventBaseState.completed: 'Completed',
};
