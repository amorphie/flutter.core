import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/managers/nba_manager/models/neo_nba_item_action_type.dart';

part 'neo_nba_item_action.g.dart';

@JsonSerializable(createToJson: false)
class NeoNbaItemAction {
  @JsonKey(name: "actionType")
  final NeoNbaItemActionType type;

  @JsonKey(name: "actionLink")
  final String link;

  NeoNbaItemAction({
    required this.type,
    required this.link,
  });

  factory NeoNbaItemAction.fromJson(Map<String, dynamic> json) => _$NeoNbaItemActionFromJson(json);
}
