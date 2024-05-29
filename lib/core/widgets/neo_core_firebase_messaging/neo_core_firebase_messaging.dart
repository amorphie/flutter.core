import 'package:flutter/material.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';

class NeoCoreFirebaseMessaging extends StatelessWidget {
  const NeoCoreFirebaseMessaging({
    required this.child,
    required this.networkManager,
    this.androidDefaultIcon,
    this.onDeeplinkNavigation,
    super.key,
  });

  final Widget child;
  final NeoNetworkManager networkManager;
  final String? androidDefaultIcon;
  final Function(String)? onDeeplinkNavigation;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
