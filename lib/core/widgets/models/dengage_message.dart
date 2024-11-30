import 'package:json_annotation/json_annotation.dart';

part 'dengage_message.g.dart';

@JsonSerializable(createToJson: false)
class DengageMessage {
  @JsonKey(name: "addToInbox")
  final bool addToInbox;
  @JsonKey(name: "badge")
  final bool badge;
  @JsonKey(name: "badgeCount", defaultValue: 0)
  final int badgeCount;
  @JsonKey(name: "dengageCampId", defaultValue: 0)
  final int dengageCampId;
  @JsonKey(name: "dengageCampName", defaultValue: "")
  final String dengageCampName;
  @JsonKey(name: "current", defaultValue: -1)
  final int current;
  @JsonKey(name: "customParams", defaultValue: [])
  final List<dynamic> customParams;
  @JsonKey(name: "expireDate", defaultValue: "")
  final String expireDate;
  @JsonKey(name: "media", defaultValue: [])
  final List<DengageMedia> dengageMedia;
  @JsonKey(name: "mediaUrl", defaultValue: "")
  final String mediaUrl;
  @JsonKey(name: "message", defaultValue: "")
  final String message;
  @JsonKey(name: "messageDetails", defaultValue: "")
  final String messageDetails;
  @JsonKey(name: "messageId", defaultValue: 0)
  final int messageId;
  @JsonKey(name: "messageSource", defaultValue: "")
  final String messageSource;
  @JsonKey(name: "notificationType", defaultValue: "")
  final String notificationType;
  @JsonKey(name: "dengageSendId", defaultValue: 0)
  final int dengageSendId;
  @JsonKey(name: "sound", defaultValue: "")
  final String sound;
  @JsonKey(name: "source", defaultValue: "")
  final String source;
  @JsonKey(name: "subTitle", defaultValue: "")
  final String subTitle;
  @JsonKey(name: "targetUrl", defaultValue: "")
  final String targetUrl;
  @JsonKey(name: "title", defaultValue: "")
  final String title;
  @JsonKey(name: "transactionId", defaultValue: "")
  final String transactionId;

  DengageMessage({
    required this.addToInbox,
    required this.badge,
    required this.badgeCount,
    required this.dengageCampId,
    required this.dengageCampName,
    required this.current,
    required this.customParams,
    required this.expireDate,
    required this.dengageMedia,
    required this.mediaUrl,
    required this.message,
    required this.messageDetails,
    required this.messageId,
    required this.messageSource,
    required this.notificationType,
    required this.dengageSendId,
    required this.sound,
    required this.source,
    required this.subTitle,
    required this.targetUrl,
    required this.title,
    required this.transactionId,
  });

  factory DengageMessage.fromJson(Map<String, dynamic> json) => _$DengageMessageFromJson(json);
}

@JsonSerializable(createToJson: false)
class DengageMedia {
  @JsonKey(name: "target", defaultValue: "")
  final String target;
  @JsonKey(name: "url", defaultValue: "")
  final String url;

  DengageMedia({
    required this.target,
    required this.url,
  });

  factory DengageMedia.fromJson(Map<String, dynamic> json) => _$DengageMediaFromJson(json);
}
