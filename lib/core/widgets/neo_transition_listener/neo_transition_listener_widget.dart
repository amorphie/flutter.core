import 'package:flutter/material.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:uuid/uuid.dart';

class NeoTransitionListenerWidget extends StatefulWidget {
  final Widget child;
  final String transitionId;
  final String signalRServerUrl;
  final String signalRMethodName;
  final Function(SignalrTransitionData navigationData) onPageNavigation;
  final Function(String str) onEventFlow;
  final VoidCallback? onLoggedInSuccessfully;
  final Function(String errorMessage)? onError;

  const NeoTransitionListenerWidget({
    required this.child,
    required this.transitionId,
    required this.signalRServerUrl,
    required this.signalRMethodName,
    required this.onPageNavigation,
    required this.onEventFlow,
    this.onLoggedInSuccessfully,
    this.onError,
    Key? key,
  }) : super(key: key);

  @override
  State<NeoTransitionListenerWidget> createState() => _NeoTransitionListenerWidgetState();
}

class _NeoTransitionListenerWidgetState extends State<NeoTransitionListenerWidget> {
  SignalrConnectionManager? signalrConnectionManager;
  late NeoCoreSecureStorage neoCoreSecureStorage = NeoCoreSecureStorage();

  @override
  void initState() {
    super.initState();
    _initSignalRConnectionManager();
  }

  _initSignalRConnectionManager() async {
    signalrConnectionManager = SignalrConnectionManager(
      serverUrl: widget.signalRServerUrl + await _getWorkflowQueryParameters(),
      methodName: widget.signalRMethodName,
    );
    await signalrConnectionManager?.init();
    signalrConnectionManager?.listenForTransitionEvents(
      transitionId: widget.transitionId,
      onPageNavigation: widget.onPageNavigation,
      onEventFlow: widget.onEventFlow,
      onTokenRetrieved: (token, refreshToken) {
        widget.onLoggedInSuccessfully?.call();
        neoCoreSecureStorage
          ..setAuthToken(token)
          ..setRefreshToken(refreshToken);
      },
      onError: widget.onError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Future<String> _getWorkflowQueryParameters() async {
    final secureStorage = NeoCoreSecureStorage();
    final results = await Future.wait([
      secureStorage.getDeviceId(),
      secureStorage.getTokenId(),
    ]);

    final deviceId = results[0] ?? "";
    final tokenId = results[1] ?? "";

    return "?${NeoNetworkHeaderKey.deviceId}=$deviceId&"
        "${NeoNetworkHeaderKey.tokenId}=$tokenId&"
        "${NeoNetworkHeaderKey.requestId}=${const Uuid().v1()}";
  }

  @override
  void dispose() {
    signalrConnectionManager?.stop();
    super.dispose();
  }
}
