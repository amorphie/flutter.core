import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/network/models/mtls_enabled_transition_config.dart';

part 'mtls_enabled_transition.g.dart';

@JsonSerializable(createToJson: false)
class MtlsEnabledTransition {
  @JsonKey(name: 'transition-name')
  final String transitionName;

  @JsonKey(name: 'config')
  final MtlsEnabledTransitionConfig config;

  const MtlsEnabledTransition({
    required this.transitionName,
    required this.config,
  });

  factory MtlsEnabledTransition.fromJson(Map<String, dynamic> json) => _$MtlsEnabledTransitionFromJson(json);
}
