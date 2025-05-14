// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_nba_item_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoNbaItemAction _$NeoNbaItemActionFromJson(Map<String, dynamic> json) =>
    NeoNbaItemAction(
      type: $enumDecode(_$NeoNbaItemActionTypeEnumMap, json['actionType']),
      link: json['actionLink'] as String,
    );

const _$NeoNbaItemActionTypeEnumMap = {
  NeoNbaItemActionType.noAction: 0,
  NeoNbaItemActionType.externalLink: 1,
  NeoNbaItemActionType.deeplink: 2,
};
