import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NeoSignalRTransitionStateType {
  @JsonValue('Fail')
  fail,
  @JsonValue('Finish')
  finish,
  @JsonValue('PartialStart')
  partialStart,
  @JsonValue('Standart')
  standard,
  @JsonValue('Start')
  start,
  @JsonValue('SubWorkflow')
  subWorkflow,
}

extension NeoSignalRTransitionStateTypeExtension on NeoSignalRTransitionStateType? {
  bool get isTerminated => this == NeoSignalRTransitionStateType.fail || this == NeoSignalRTransitionStateType.finish;
}
