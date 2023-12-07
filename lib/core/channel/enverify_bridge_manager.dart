library env_bridge;

import 'package:flutter/services.dart';

part 'package:neo_core/core/channel/event_channel_handler.dart';
part 'package:neo_core/core/channel/method_channel_handler.dart';
part 'package:neo_core/core/channel/method_keys.dart';
part 'package:neo_core/core/channel/method_names.dart';

class BridgeManager {
  static BridgeManager? _instance;

  BridgeManager._();

  factory BridgeManager() {
    _instance ??= BridgeManager._();
    return _instance!;
  }

  late _MethodChannelHandler _mc;

  void init() {
    //EventChannelHandler.init();
    _mc = _MethodChannelHandler();
  }

  startSDK(String firstName, String lastName, String callType) {
    _mc.startSDK({
      _MethodKeys.firstName.name: firstName,
      _MethodKeys.lastName.name: lastName,
      _MethodKeys.callType.name: callType,
    });
  }
}
