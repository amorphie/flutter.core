import 'package:json_annotation/json_annotation.dart';

part 'neo_page_components_response.g.dart';

@JsonSerializable(createToJson: false)
class NeoPageComponentsResponse {
  @JsonKey(name: "components", defaultValue: {})
  final Map<String, dynamic> components;

  factory NeoPageComponentsResponse.fromJson(Map<String, dynamic> json) => _$NeoPageComponentsResponseFromJson(json);

  NeoPageComponentsResponse({
    required this.components,
  });
}
