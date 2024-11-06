// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dengage_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DengageMessage _$DengageMessageFromJson(Map<String, dynamic> json) =>
    DengageMessage(
      addToInbox: json['addToInbox'] as bool,
      badge: json['badge'] as bool,
      badgeCount: json['badgeCount'] as int,
      dengageCampId: json['dengageCampId'] as int,
      dengageCampName: json['dengageCampName'] as String,
      current: json['current'] as int,
      customParams: json['customParams'] as List<dynamic>,
      expireDate: json['expireDate'] as String,
      media: (json['media'] as List<dynamic>)
          .map((e) => Media.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaUrl: json['mediaUrl'] as String,
      message: json['message'] as String,
      messageDetails: json['messageDetails'] as String,
      messageId: json['messageId'] as int,
      messageSource: json['messageSource'] as String,
      notificationType: json['notificationType'] as String,
      dengageSendId: json['dengageSendId'] as int,
      sound: json['sound'] as String,
      source: json['source'] as String,
      subTitle: json['subTitle'] as String,
      targetUrl: json['targetUrl'] as String,
      title: json['title'] as String,
      transactionId: json['transactionId'] as String,
    );

Map<String, dynamic> _$DengageMessageToJson(DengageMessage instance) =>
    <String, dynamic>{
      'addToInbox': instance.addToInbox,
      'badge': instance.badge,
      'badgeCount': instance.badgeCount,
      'dengageCampId': instance.dengageCampId,
      'dengageCampName': instance.dengageCampName,
      'current': instance.current,
      'customParams': instance.customParams,
      'expireDate': instance.expireDate,
      'media': instance.media,
      'mediaUrl': instance.mediaUrl,
      'message': instance.message,
      'messageDetails': instance.messageDetails,
      'messageId': instance.messageId,
      'messageSource': instance.messageSource,
      'notificationType': instance.notificationType,
      'dengageSendId': instance.dengageSendId,
      'sound': instance.sound,
      'source': instance.source,
      'subTitle': instance.subTitle,
      'targetUrl': instance.targetUrl,
      'title': instance.title,
      'transactionId': instance.transactionId,
    };

Media _$MediaFromJson(Map<String, dynamic> json) => Media(
      target: json['target'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$MediaToJson(Media instance) => <String, dynamic>{
      'target': instance.target,
      'url': instance.url,
    };
