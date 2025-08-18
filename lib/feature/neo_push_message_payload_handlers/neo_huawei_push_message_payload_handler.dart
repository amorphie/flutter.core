import 'package:neo_core/feature/neo_push_message_payload_handlers/neo_push_message_payload_handler.dart';

class NeoHuaweiPushMessagePayloadHandler extends NeoPushMessagePayloadHandler {
  @override
  void handleMessage({required dynamic message, required Function(String)? onDeeplinkNavigation}) {
    if (message is! Map<String, dynamic>) {
      return;
    }

    if (message.containsKey(NeoPushMessagePayloadHandler.pushNotificationHuaweiDeeplinkExtrasKey)) {
      final String? deeplinkPath = message[NeoPushMessagePayloadHandler.pushNotificationHuaweiDeeplinkExtrasKey]
          [NeoPushMessagePayloadHandler.pushNotificationDeeplinkKey];
      if (deeplinkPath != null && deeplinkPath.isNotEmpty) {
        onDeeplinkNavigation?.call(deeplinkPath);
      }
    }
  }
}
