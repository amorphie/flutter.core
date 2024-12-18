abstract class NeoPushMessagePayloadHandler {
  static const pushNotificationDeeplinkKey = "deeplink";

  void handleMessage({required dynamic message, required Function(String)? onDeeplinkNavigation});
}
