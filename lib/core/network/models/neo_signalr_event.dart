import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/network/models/neo_signalr_transition.dart';

part 'neo_signalr_event.g.dart';

@JsonSerializable(createToJson: false)
class NeoSignalREvent extends Equatable {
  @JsonKey(name: "id")
  final String eventId;

  @JsonKey(name: "type")
  final String type;

  @JsonKey(name: "subject")
  final String status;

  @JsonKey(name: "data")
  final NeoSignalRTransition transition;

  @JsonKey(name: "oldHubValues")
  final List<NeoSignalREvent> previousEvents;

  const NeoSignalREvent({
    required this.eventId,
    required this.type,
    required this.status,
    required this.transition,
    this.previousEvents = const [],
  });

  @override
  List<Object?> get props =>
      [
        eventId,
        type,
        status,
        transition,
        previousEvents,
      ];

  factory NeoSignalREvent.fromJson(Map<String, dynamic> json) => _$NeoSignalREventFromJson(json);
}
