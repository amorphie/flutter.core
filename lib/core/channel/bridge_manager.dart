library env_bridge;

import 'package:flutter/services.dart';

part 'package:neo_core/core/channel/common/method_channel_handler.dart';
part 'package:neo_core/core/channel/common/method_keys.dart';
part 'package:neo_core/core/channel/common/method_names.dart';
part 'package:neo_core/core/channel/enverify/event_channel_handler.dart';
part 'package:neo_core/core/channel/enverify/method_channel_handler.dart';
part 'package:neo_core/core/channel/enverify/method_keys.dart';
part 'package:neo_core/core/channel/enverify/method_names.dart';

class BridgeManager {
  static final _instance = BridgeManager._internal();

  BridgeManager._internal();

  factory BridgeManager() => _instance;

  _EnverifyMethodChannelHandler? _emc;
  _MethodChannelHandler? _mc;

  void init() {
    //EventChannelHandler.init();
    _mc = _MethodChannelHandler();
    _emc = _EnverifyMethodChannelHandler();
  }

  prepareSDK() {
    print("CORE: prepareSDK");
    _mc?.prepareEnverifySDK({
      _MethodKeys.configEnverifySDK.name: "TODO add config.",
    });
  }

  startSDK(String firstName, String lastName, String callType) {
    _emc?.startSDK({
      _EnverifyMethodKeys.firstName.name: firstName,
      _EnverifyMethodKeys.lastName.name: lastName,
      _EnverifyMethodKeys.callType.name: callType,
    });
  }
}
