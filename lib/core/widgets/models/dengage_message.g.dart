// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dengage_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DengageMessage _$DengageMessageFromJson(Map<String, dynamic> json) =>
    DengageMessage(
      addToInbox: json['addToInbox'] as bool,
      badge: json['badge'] as bool,
      badgeCount: json['badgeCount'] as int? ?? 0,
      dengageCampId: json['dengageCampId'] as int? ?? 0,
      dengageCampName: json['dengageCampName'] as String? ?? '',
      current: json['current'] as int? ?? -1,
      customParams: json['customParams'] as List<dynamic>? ?? [],
      expireDate: json['expireDate'] as String? ?? '',
      dengageMedia: (json['media'] as List<dynamic>?)
              ?.map((e) => DengageMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mediaUrl: json['mediaUrl'] as String? ?? '',
      message: json['message'] as String? ?? '',
      messageDetails: json['messageDetails'] as String? ?? '',
      messageId: json['messageId'] as int? ?? 0,
      messageSource: json['messageSource'] as String? ?? '',
      notificationType: json['notificationType'] as String? ?? '',
      dengageSendId: json['dengageSendId'] as int? ?? 0,
      sound: json['sound'] as String? ?? '',
      source: json['source'] as String? ?? '',
      subTitle: json['subTitle'] as String? ?? '',
      targetUrl: json['targetUrl'] as String? ?? '',
      title: json['title'] as String? ?? '',
      transactionId: json['transactionId'] as String? ?? '',
    );

DengageMedia _$DengageMediaFromJson(Map<String, dynamic> json) => DengageMedia(
      target: json['target'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
