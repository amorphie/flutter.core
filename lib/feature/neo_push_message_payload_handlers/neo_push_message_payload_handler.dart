abstract class NeoPushMessagePayloadHandler {
  static const pushNotificationDeeplinkKey = "deeplink";
  static const pushNotificationHuaweiDeeplinkExtrasKey = "extras";

  void handleMessage({required dynamic message, required Function(String)? onDeeplinkNavigation});
}
