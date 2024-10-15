import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoSignalREventType {
  @JsonValue('silent')
  silent,
  @JsonValue('workflow')
  workflow,
  @JsonValue('force')
  force,
}
