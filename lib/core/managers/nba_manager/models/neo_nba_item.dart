import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/managers/nba_manager/models/neo_nba_item_action.dart';
import 'package:neo_core/core/managers/nba_manager/models/neo_nba_item_content.dart';
import 'package:neo_core/core/managers/nba_manager/models/neo_nba_item_type.dart';

part 'neo_nba_item.g.dart';

@JsonSerializable(createToJson: false)
class NeoNbaItem {
  @JsonKey(name: "type")
  final NeoNbaItemType type;

  @JsonKey(name: "content")
  final NeoNbaItemContent content;

  @JsonKey(name: "id")
  final int? id;

  @JsonKey(name: "score", defaultValue: 0)
  final int order;

  @JsonKey(name: "when")
  final dynamic displayWhen;

  @JsonKey(name: "action")
  final NeoNbaItemAction? action;

  NeoNbaItem({
    required this.type,
    required this.content,
    required this.order,
    this.id,
    this.displayWhen,
    this.action,
  });

  factory NeoNbaItem.fromJson(Map<String, dynamic> json) => _$NeoNbaItemFromJson(json);
}
