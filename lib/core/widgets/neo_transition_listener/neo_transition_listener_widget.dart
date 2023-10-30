import 'package:flutter/material.dart';
import 'package:neo_core/core/network/neo_network.dart';

class NeoTransitionListenerWidget extends StatefulWidget {
  final Widget child;
  final String transitionId;
  final String signalRServerUrl;
  final String signalRMethodName;
  final Function(String navigationPath) onPageNavigation;
  final Function(String token)? onTokenRetrieved;
  final Function(String errorMessage)? onError;

  const NeoTransitionListenerWidget({
    Key? key,
    required this.child,
    required this.transitionId,
    required this.signalRServerUrl,
    required this.signalRMethodName,
    required this.onPageNavigation,
    this.onTokenRetrieved,
    this.onError,
  }) : super(key: key);

  @override
  State<NeoTransitionListenerWidget> createState() => _NeoTransitionListenerWidgetState();
}

class _NeoTransitionListenerWidgetState extends State<NeoTransitionListenerWidget> {
  late SignalrConnectionManager signalrConnectionManager;

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
      onTokenRetrieved: widget.onTokenRetrieved,
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
