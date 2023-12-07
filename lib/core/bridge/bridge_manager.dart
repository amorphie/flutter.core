import 'package:neo_core/core/channel/event_channel_handler.dart';

class BridgeManager {
  BridgeManager._();

  static init() {
    EventChannelHandler.init();
  }
}
