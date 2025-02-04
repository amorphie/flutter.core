import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/network/models/neo_signalr_event_base_state.dart';
import 'package:neo_core/core/network/models/neo_signalr_event_type.dart';
import 'package:neo_core/core/network/models/neo_signalr_transition.dart';

part 'neo_signalr_event.g.dart';

@JsonSerializable(createToJson: false)
class NeoSignalREvent extends Equatable {
  @JsonKey(name: "id")
  final String eventId;

  @JsonKey(name: "type")
  final NeoSignalREventType type;

  @JsonKey(name: "subject")
  final String status;

  @JsonKey(name: "data")
  final NeoSignalRTransition transition;

  @JsonKey(name: "base-state")
  final NeoSignalREventBaseState baseState;

  @JsonKey(name: "oldHubValues")
  final List<NeoSignalREvent> previousEvents;

  const NeoSignalREvent({
    required this.eventId,
    required this.type,
    required this.status,
    required this.transition,
    required this.baseState,
    this.previousEvents = const [],
  });

  bool get isSilentEvent => type == NeoSignalREventType.silent;

  @override
  List<Object?> get props => [
        eventId,
        type,
        status,
        transition,
        baseState,
        previousEvents,
      ];

  factory NeoSignalREvent.fromJson(Map<String, dynamic> json) => _$NeoSignalREventFromJson(json);
}
