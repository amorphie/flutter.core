import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoSignalREventBaseState {
  @JsonValue('New')
  newState,
  @JsonValue('InProgress')
  inProgress,
  @JsonValue('Completed')
  completed,
}
