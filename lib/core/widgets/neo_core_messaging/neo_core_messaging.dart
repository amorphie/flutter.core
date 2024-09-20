import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/widgets/neo_core_firebase_messaging/neo_core_firebase_messaging.dart';
import 'package:neo_core/core/widgets/neo_core_huawei_messaging/neo_core_huawei_messaging.dart';

class NeoCoreMessaging extends StatelessWidget {
  final bool isHuaweiCompatible;
  final Widget child;
  final NeoNetworkManager networkManager;
  final NeoCoreSecureStorage neoCoreSecureStorage;
  final String? androidDefaultIcon;
  final Function(String)? onDeeplinkNavigation;

  const NeoCoreMessaging({
    required this.isHuaweiCompatible,
    required this.child,
    required this.networkManager,
    required this.neoCoreSecureStorage,
    this.androidDefaultIcon,
    this.onDeeplinkNavigation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return child;
    } else if (isHuaweiCompatible) {
      return NeoCoreHuaweiMessaging(
        networkManager: networkManager,
        neoCoreSecureStorage: neoCoreSecureStorage,
        androidDefaultIcon: androidDefaultIcon,
        onDeeplinkNavigation: onDeeplinkNavigation,
        child: child,
      );
    } else {
      return NeoCoreFirebaseMessaging(
        networkManager: networkManager,
        neoCoreSecureStorage: neoCoreSecureStorage,
        androidDefaultIcon: androidDefaultIcon,
        onDeeplinkNavigation: onDeeplinkNavigation,
        child: child,
      );
    }
  }
}
