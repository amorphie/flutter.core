import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/widgets/models/dengage_message.dart';
import 'package:neo_core/feature/neo_push_message_payload_handler/neo_push_message_payload_handler.dart';

abstract class _Constants {
  static const messageSource = "DENGAGE";
}

class NeoDengageAndroidPushMessagePayloadHandler extends NeoPushMessagePayloadHandler {
  NeoLogger get _neoLogger => GetIt.I.get();

  @override
  void handleMessage({required dynamic message, required Function(String)? onDeeplinkNavigation}) {
    if (message is! Map<String, dynamic>) {
      return;
    }

    try {
      final dengageMessage = DengageMessage.fromJson(message);
      if (_Constants.messageSource.toLowerCase() == dengageMessage.messageSource.toLowerCase() &&
          dengageMessage.dengageMedia.isNotEmpty &&
          dengageMessage.dengageMedia[0].target.isNotEmpty) {
        onDeeplinkNavigation?.call(dengageMessage.dengageMedia[0].target);
      }
    } on FormatException catch (e) {
      _neoLogger.logError("[NeoDengageAndroidPushMessagePayloadHandler]: JSON Decode Error: $e");
    } catch (e) {
      _neoLogger.logError("[NeoDengageAndroidPushMessagePayloadHandler]: Dengage Message Error is: $e!");
    }
  }
}
