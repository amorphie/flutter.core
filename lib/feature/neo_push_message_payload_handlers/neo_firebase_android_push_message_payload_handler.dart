import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:neo_core/feature/neo_push_message_payload_handlers/neo_push_message_payload_handler.dart';

class NeoFirebaseAndroidPushMessagePayloadHandler extends NeoPushMessagePayloadHandler {
  @override
  void handleMessage({required dynamic message, required Function(String)? onDeeplinkNavigation}) {
    if (message is! RemoteMessage) {
      return;
    }

    final String? deeplinkPath = message.data[NeoPushMessagePayloadHandler.pushNotificationDeeplinkKey];
    if (deeplinkPath != null && deeplinkPath.isNotEmpty) {
      onDeeplinkNavigation?.call(deeplinkPath);
    }
  }
}
