import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neo_core/core/navigation/models/ekyc_event_data.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/bloc/neo_transition_listener_bloc.dart';
import 'package:neo_core/core/workflow_form/neo_sub_workflow_manager.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';

class NeoTransitionListenerWidget extends StatelessWidget {
  final Widget child;
  final NeoWorkflowManager neoWorkflowManager;
  final NeoSubWorkflowManager neoSubWorkflowManager;
  final String signalRServerUrl;
  final String signalRMethodName;
  final Function(SignalrTransitionData navigationData) onPageNavigation;
  final Function(EkycEventData eventData) onEkycEvent;
  final Function({required bool isTwoFactorAuthenticated})? onLoggedInSuccessfully;
  final Function(NeoError error)? onError;
  final Function({required bool displayLoading}) onLoadingStatusChanged;
  final bool bypassSignalr;

  const NeoTransitionListenerWidget({
    required this.child,
    required this.neoWorkflowManager,
    required this.neoSubWorkflowManager,
    required this.signalRServerUrl,
    required this.signalRMethodName,
    required this.onPageNavigation,
    required this.onEkycEvent,
    required this.onLoadingStatusChanged,
    this.onLoggedInSuccessfully,
    this.onError,
    this.bypassSignalr = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NeoTransitionListenerBloc()
        ..add(
          NeoTransitionListenerEventInit(
            neoWorkflowManager: neoWorkflowManager,
            neoSubWorkflowManager: neoSubWorkflowManager,
            signalRServerUrl: signalRServerUrl,
            signalRMethodName: signalRMethodName,
            onTransitionSuccess: onPageNavigation,
            onEkycEvent: onEkycEvent,
            onLoggedInSuccessfully: onLoggedInSuccessfully,
            onTransitionError: onError,
            onLoadingStatusChanged: onLoadingStatusChanged,
            bypassSignalr: bypassSignalr,
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
