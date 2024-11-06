import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/widgets/models/dengage_message.dart';
import 'package:neo_core/core/widgets/neo_core_firebase_messaging/neo_core_firebase_messaging.dart';
import 'package:neo_core/core/widgets/neo_core_huawei_messaging/neo_core_huawei_messaging.dart';
import 'dart:convert'

abstract class _Constants {
  static const messageSource = "DENGAGE";
}

class NeoCoreMessaging extends StatefulWidget {
  final Widget child;
  final NeoSharedPrefs neoSharedPrefs;
  final NeoNetworkManager networkManager;
  final NeoCoreSecureStorage neoCoreSecureStorage;
  final Function(String) firebaseToken;
  final String? androidDefaultIcon;
  final Function(String)? onDeeplinkNavigation;

  const NeoCoreMessaging({
    required this.child,
    required this.neoSharedPrefs,
    required this.networkManager,
    required this.neoCoreSecureStorage,
    required this.firebaseToken,
    this.androidDefaultIcon,
    this.onDeeplinkNavigation,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _NeoCoreMessagingState();
}

class _NeoCoreMessagingState extends State<NeoCoreMessaging> {
  static const EventChannel eventChannel = EventChannel("com.dengage.flutter/onNotificationClicked");

  void _onEvent(dynamic event) {
    debugPrint("Dengage in on Event object is: $event");
    final dengageMessage = DengageMessage.fromJson(jsonDecode(event));
    debugPrint("Dengage in on Message $dengageMessage");
    DengageMessage.fromJson(event);
    if (_Constants.messageSource.toLowerCase() == dengageMessage.messageSource.toLowerCase() &&
        dengageMessage.media.isNotEmpty &&
        dengageMessage.media[0].target.isNotEmpty) {
      widget.onDeeplinkNavigation?.call(dengageMessage.media[0].target);
    }
  }

  void _onError(dynamic error) {
    debugPrint("Dengage in on Error Object is: $error");
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return widget.child;
    } else {
      final bool isHuaweiCompatible =
          widget.neoSharedPrefs.read(NeoCoreParameterKey.sharedPrefsIsHuaweiCompatible) as bool? ?? false;
      if (isHuaweiCompatible) {
        return NeoCoreHuaweiMessaging(
          networkManager: widget.networkManager,
          neoCoreSecureStorage: widget.neoCoreSecureStorage,
          token: widget.firebaseToken,
          androidDefaultIcon: widget.androidDefaultIcon,
          onDeeplinkNavigation: widget.onDeeplinkNavigation,
          child: widget.child,
        );
      } else {
        return NeoCoreFirebaseMessaging(
          networkManager: widget.networkManager,
          neoCoreSecureStorage: widget.neoCoreSecureStorage,
          token: widget.firebaseToken,
          androidDefaultIcon: widget.androidDefaultIcon,
          onDeeplinkNavigation: widget.onDeeplinkNavigation,
          child: widget.child,
        );
      }
    }
  }

  @override
  void initState() {
    eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
    super.initState();
  }
}
