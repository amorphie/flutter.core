import 'package:flutter/material.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';

class NeoTransitionListenerWidget extends StatefulWidget {
  final Widget child;
  final String transitionId;
  final String signalRServerUrl;
  final String signalRMethodName;
  final Function(SignalrTransitionData navigationData) onPageNavigation;
  final Function(String errorMessage)? onError;

  const NeoTransitionListenerWidget({
    required this.child,
    required this.transitionId,
    required this.signalRServerUrl,
    required this.signalRMethodName,
    required this.onPageNavigation,
    this.onError,
    Key? key,
  }) : super(key: key);

  @override
  State<NeoTransitionListenerWidget> createState() => _NeoTransitionListenerWidgetState();
}

class _NeoTransitionListenerWidgetState extends State<NeoTransitionListenerWidget> {
  late SignalrConnectionManager signalrConnectionManager;
  late NeoCoreSecureStorage neoCoreSecureStorage = NeoCoreSecureStorage();

  @override
  void initState() {
    super.initState();
    _initSignalRConnectionManager();
  }

  _initSignalRConnectionManager() async {
    signalrConnectionManager = SignalrConnectionManager(
      serverUrl: widget.signalRServerUrl,
      methodName: widget.signalRMethodName,
    );
    await signalrConnectionManager.init();
    signalrConnectionManager.listenForTransitionEvents(
      transitionId: widget.transitionId,
      onPageNavigation: widget.onPageNavigation,
      onTokenRetrieved: (token, refreshToken) => neoCoreSecureStorage
        ..setAuthToken(token)
        ..setRefreshToken(refreshToken),
      onError: widget.onError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    signalrConnectionManager.stop();
    super.dispose();
  }
}
