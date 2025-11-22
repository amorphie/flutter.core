import 'package:json_annotation/json_annotation.dart';

part 'vnext_transition.g.dart';

@JsonSerializable()
class VNextTransition {
  @JsonKey(name: "name")
  final String name;

  @JsonKey(name: "href")
  final String href;

  VNextTransition({required this.name, required this.href});

  Map<String, dynamic> toJson() => _$VNextTransitionToJson(this);

  factory VNextTransition.fromJson(Map<String, dynamic> json) => _$VNextTransitionFromJson(json);
}
