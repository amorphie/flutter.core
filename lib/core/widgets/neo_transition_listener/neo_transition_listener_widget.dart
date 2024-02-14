import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neo_core/core/navigation/models/signalr_ekyc_data.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/bloc/neo_transition_listener_bloc.dart';

class NeoTransitionListenerWidget extends StatelessWidget {
  final Widget child;
  final NeoNetworkManager neoNetworkManager;
  final String signalRServerUrl;
  final String signalRMethodName;
  final Function(SignalrTransitionData navigationData) onPageNavigation;
  final Function(SignalrEkycData flowdata) onEventFlow;
  final VoidCallback? onLoggedInSuccessfully;
  final Function(NeoError error)? onError;
  final Function({required bool displayLoading}) onLoadingStatusChanged;

  const NeoTransitionListenerWidget({
    required this.child,
    required this.neoNetworkManager,
    required this.signalRServerUrl,
    required this.signalRMethodName,
    required this.onPageNavigation,
    required this.onEventFlow,
    required this.onLoadingStatusChanged,
    this.onLoggedInSuccessfully,
    this.onError,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NeoTransitionListenerBloc()
        ..add(
          NeoTransitionListenerEventInit(
            neoNetworkManager: neoNetworkManager,
            signalRServerUrl: signalRServerUrl,
            signalRMethodName: signalRMethodName,
            onPageNavigation: onPageNavigation,
            onEventFlow: onEventFlow,
            onLoggedInSuccessfully: onLoggedInSuccessfully,
            onError: onError,
            onLoadingStatusChanged: onLoadingStatusChanged,
          ),
        ),
      child: BlocBuilder<NeoTransitionListenerBloc, NeoTransitionListenerState>(
        builder: (context, state) {
          return child;
        },
      ),
    );
  }
}
