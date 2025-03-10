import 'package:json_annotation/json_annotation.dart';

part 'mtls_enabled_transition_config.g.dart';

@JsonSerializable(createToJson: false)
class MtlsEnabledTransitionConfig {
  @JsonKey(name: 'sign')
  final bool sign;

  @JsonKey(name: 'mtls')
  final bool mtls;

  const MtlsEnabledTransitionConfig({
    this.sign = false,
    this.mtls = false,
  });

  factory MtlsEnabledTransitionConfig.fromJson(Map<String, dynamic> json) => _$MtlsEnabledTransitionConfigFromJson(json);
}
