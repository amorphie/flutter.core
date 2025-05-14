// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_nba_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoNbaItem _$NeoNbaItemFromJson(Map<String, dynamic> json) => NeoNbaItem(
      type: $enumDecode(_$NeoNbaItemTypeEnumMap, json['type']),
      content:
          NeoNbaItemContent.fromJson(json['content'] as Map<String, dynamic>),
      order: (json['score'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt(),
      displayWhen: json['when'],
      action: json['action'] == null
          ? null
          : NeoNbaItemAction.fromJson(json['action'] as Map<String, dynamic>),
    );

const _$NeoNbaItemTypeEnumMap = {
  NeoNbaItemType.inApp: 1,
  NeoNbaItemType.placeholder: 2,
  NeoNbaItemType.mail: 3,
  NeoNbaItemType.sms: 4,
  NeoNbaItemType.push: 5,
  NeoNbaItemType.ivn: 6,
  NeoNbaItemType.serviceCall: 7,
  NeoNbaItemType.card: 8,
};
