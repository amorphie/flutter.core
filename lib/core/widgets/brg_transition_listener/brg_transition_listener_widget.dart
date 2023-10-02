import 'package:burgan_core/core/network/burgan_network.dart';
import 'package:flutter/material.dart';

class BrgTransitionListenerWidget extends StatefulWidget {
  final Widget child;
  final String transitionId;
  final String signalRServerUrl;
  final String signalRMethodName;
  final Function(String navigationPath) onPageNavigation;
  final Function(String token)? onTokenRetrieved;
  final Function(String errorMessage)? onError;

  const BrgTransitionListenerWidget({
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
  State<BrgTransitionListenerWidget> createState() => _BrgTransitionListenerWidgetState();
}

class _BrgTransitionListenerWidgetState extends State<BrgTransitionListenerWidget> {
  late SignalrConnectionManager signalrConnectionManager;

  @override
  void initState() {
    super.initState();
    try {
      signalrConnectionManager = SignalrConnectionManager(
        serverUrl: widget.signalRServerUrl,
        methodName: widget.signalRMethodName,
      )..init();

      signalrConnectionManager.listenForTransitionEvents(
        transitionId: widget.transitionId,
        onPageNavigation: widget.onPageNavigation,
        onTokenRetrieved: widget.onTokenRetrieved,
        onError: widget.onError,
      );
    } catch (e) {
      widget.onError?.call(e.toString());
    }
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
