import 'package:burgan_core/core/network/models/neo_base_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'neo_page_components_response.g.dart';

@JsonSerializable(createToJson: false)
class NeoPageComponentsResponse extends NeoBaseResponse {
  @JsonKey(name: "components", defaultValue: {})
  final Map<String, dynamic> components;

  @override
  NeoPageComponentsResponse fromJson(Map<String, dynamic> json) => _$NeoPageComponentsResponseFromJson(json);

  NeoPageComponentsResponse({
    required this.components,
  });
}
