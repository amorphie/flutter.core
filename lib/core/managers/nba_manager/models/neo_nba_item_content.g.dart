// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neo_nba_item_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NeoNbaItemContent _$NeoNbaItemContentFromJson(Map<String, dynamic> json) =>
    NeoNbaItemContent(
      contentType: $enumDecode(_$NeoNbaContentTypeEnumMap, json['contentType']),
      title: json['title'] as String?,
      body: json['body'],
      image: json['image'] as String?,
      sound: json['sound'] as String?,
    );

const _$NeoNbaContentTypeEnumMap = {
  NeoNbaContentType.image: 4,
  NeoNbaContentType.dynamicWidget: 5,
};
