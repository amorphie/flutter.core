import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_transition.dart';

part 'vnext_state.g.dart';

@JsonSerializable()
class VNextState {
  @JsonKey(name: "data")
  final Map<String, dynamic> data;

  @JsonKey(name: "view")
  final Map<String, dynamic> view;

  @JsonKey(name: "state")
  final String state;

  @JsonKey(name: "transitions")
  final List<VNextTransition> transitions;

  VNextState({required this.data, required this.view, required this.state, required this.transitions});

  Map<String, dynamic> toJson() => _$VNextStateToJson(this);

  factory VNextState.fromJson(Map<String, dynamic> json) => _$VNextStateFromJson(json);
}
