import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neo_core/core/analytics/neo_posthog.dart';
import 'package:neo_core/core/navigation/models/ekyc_event_data.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/bloc/neo_transition_listener_bloc.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:neo_core/neo_core.dart';

class NeoTransitionListenerWidget extends StatelessWidget {
  final Widget child;
  final NeoWorkflowManager neoWorkflowManager;
  final NeoPosthog neoPosthog;
  final NeoCoreSecureStorage neoCoreSecureStorage;
  final String signalRServerUrl;
  final String signalRMethodName;
  final Function(SignalrTransitionData navigationData) onTransitionEvent;
  final Function(EkycEventData eventData) onEkycEvent;
  final Function({required bool isTwoFactorAuthenticated})? onLoggedInSuccessfully;
  final Function(NeoError error, {required bool displayAsPopup})? onError;
  final Function({required bool displayLoading}) onLoadingStatusChanged;
  final bool bypassSignalr;
  final Duration signalrLongPollingPeriod;
  final Duration signalRTimeoutDuration;

  const NeoTransitionListenerWidget({
    required this.child,
    required this.neoWorkflowManager,
    required this.neoPosthog,
    required this.neoCoreSecureStorage,
    required this.signalRServerUrl,
    required this.signalRMethodName,
    required this.onTransitionEvent,
    required this.onEkycEvent,
    required this.onLoadingStatusChanged,
    required this.signalrLongPollingPeriod,
    required this.signalRTimeoutDuration,
    this.onLoggedInSuccessfully,
    this.onError,
    this.bypassSignalr = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NeoTransitionListenerBloc(
        neoCoreSecureStorage: neoCoreSecureStorage,
      )..add(
          NeoTransitionListenerEventInit(
            neoWorkflowManager: neoWorkflowManager,
            neoPosthog: neoPosthog,
            signalRServerUrl: signalRServerUrl,
            signalRMethodName: signalRMethodName,
            onTransitionEvent: onTransitionEvent,
            onEkycEvent: onEkycEvent,
            onLoggedInSuccessfully: onLoggedInSuccessfully,
            onTransitionError: onError,
            onLoadingStatusChanged: onLoadingStatusChanged,
            bypassSignalr: bypassSignalr,
            signalrLongPollingPeriod: signalrLongPollingPeriod,
            signalRTimeoutDuration: signalRTimeoutDuration,
          ),
        ),
      child: BlocBuilder<NeoTransitionListenerBloc, NeoTransitionListenerState>(
        buildWhen: (previous, current) => false,
        builder: (context, state) {
          return child;
        },
      ),
    );
  }
}
