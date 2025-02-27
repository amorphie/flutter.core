import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/feature/neo_push_message_payload_handlers/neo_push_message_payload_handler.dart';

abstract class _Constants {
  static const String methodChannelName = "com.neo.core/push_notification";
  static const String notificationTapMethodName = "onNotificationTapped";
  static const String dengageDeeplinkFieldName = "targetUrl";
  static const String dengageMessageSourceFieldName = "messageSource";
  static const String dengageMessageSource = "DENGAGE";
}

class NeoIosPushMessagePayloadHandler extends NeoPushMessagePayloadHandler {
  NeoLogger get _neoLogger => GetIt.I.get();

  static const MethodChannel _methodChannel = MethodChannel(_Constants.methodChannelName);
  void Function(String)? onDeeplinkNavigation;

  String deeplinkKey({required bool isDengage}) =>
      isDengage ? _Constants.dengageDeeplinkFieldName : NeoPushMessagePayloadHandler.pushNotificationDeeplinkKey;

  @override
  void handleMessage({required dynamic message, required Function(String)? onDeeplinkNavigation}) {
    if (message is! Map<String, dynamic>) {
      return;
    }

    final bool isDengage = message[_Constants.dengageMessageSourceFieldName] == _Constants.dengageMessageSource;
    final String? deeplinkPath = message[deeplinkKey(isDengage: isDengage)];

    if (deeplinkPath != null && deeplinkPath.isNotEmpty) {
      onDeeplinkNavigation?.call(deeplinkPath);
    }
  }

  void init({required Function(String)? onDeeplinkNavigationParam}) {
    onDeeplinkNavigation = onDeeplinkNavigationParam;

    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case _Constants.notificationTapMethodName:
          _handleIosMessage(call.arguments);
          break;
      }
    });
  }

  void _handleIosMessage(dynamic arguments) {
    if (arguments == null) {
      return;
    }

    try {
      final Map<String, dynamic> messageData = Map<String, dynamic>.from(arguments);
      handleMessage(
        message: Map<String, dynamic>.from(messageData)..remove('aps'),
        onDeeplinkNavigation: onDeeplinkNavigation,
      );
    } catch (e) {
      _neoLogger.logConsole("[NeoApnsPushMessagePayloadHandler]: Error handling iOS APNS message: $e");
    }
  }
}
