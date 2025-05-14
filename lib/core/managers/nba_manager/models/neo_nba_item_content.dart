import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/managers/nba_manager/models/neo_nba_content_type.dart';

part 'neo_nba_item_content.g.dart';

@JsonSerializable(createToJson: false)
class NeoNbaItemContent {
  @JsonKey(name: "contentType")
  final NeoNbaContentType contentType;

  @JsonKey(name: "title")
  final String? title;

  @JsonKey(name: "body")
  final dynamic body;

  @JsonKey(name: "image")
  final String? image;

  @JsonKey(name: "sound")
  final String? sound;

  NeoNbaItemContent({
    required this.contentType,
    this.title,
    this.body,
    this.image,
    this.sound,
  });

  factory NeoNbaItemContent.fromJson(Map<String, dynamic> json) => _$NeoNbaItemContentFromJson(json);
}
