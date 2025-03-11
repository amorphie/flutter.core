import 'package:json_annotation/json_annotation.dart';

part 'mtls_enabled_transition_config.g.dart';

@JsonSerializable(createToJson: false)
class MtlsEnabledTransitionConfig {
  @JsonKey(name: 'sign')
  final bool signForMtls;

  @JsonKey(name: 'mtls')
  final bool enableMtls;

  const MtlsEnabledTransitionConfig({
    this.signForMtls = false,
    this.enableMtls = false,
  });

  factory MtlsEnabledTransitionConfig.fromJson(Map<String, dynamic> json) => _$MtlsEnabledTransitionConfigFromJson(json);
}
