/*
 * neo_core
 *
 * Created on 5/2/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

part of 'neo_transition_listener_bloc.dart';

sealed class NeoTransitionListenerEvent extends Equatable {}

class NeoTransitionListenerEventInit extends NeoTransitionListenerEvent {
  final NeoWorkflowManager neoWorkflowManager;
  final NeoSubWorkflowManager neoSubWorkflowManager;
  final String signalRServerUrl;
  final String signalRMethodName;
  final Function(SignalrTransitionData navigationData) onTransitionSuccess;
  final Function(EkycEventData eventData) onEkycEvent;
  final Function({required bool isTwoFactorAuthenticated})? onLoggedInSuccessfully;
  final Function(NeoError error)? onTransitionError;
  final Function({required bool displayLoading}) onLoadingStatusChanged;
  final bool bypassSignalr;

  NeoTransitionListenerEventInit({
    required this.neoWorkflowManager,
    required this.neoSubWorkflowManager,
    required this.signalRServerUrl,
    required this.signalRMethodName,
    required this.onTransitionSuccess,
    required this.onEkycEvent,
    required this.onLoggedInSuccessfully,
    required this.onTransitionError,
    required this.onLoadingStatusChanged,
    required this.bypassSignalr,
  });

  @override
  List<Object?> get props => [
        neoWorkflowManager,
        neoSubWorkflowManager,
        signalRServerUrl,
        signalRMethodName,
        onTransitionSuccess,
        onEkycEvent,
        onLoggedInSuccessfully,
        onTransitionError,
        onLoadingStatusChanged,
        bypassSignalr,
      ];
}

class NeoTransitionListenerEventInitWorkflow extends NeoTransitionListenerEvent {
  final String workflowName;
  final Map<String, dynamic>? queryParameters;
  final bool displayLoading;
  final bool isSubFlow;
  final Map<String, dynamic>? initialData;

  NeoTransitionListenerEventInitWorkflow({
    required this.workflowName,
    this.queryParameters,
    this.isSubFlow = false,
    this.displayLoading = true,
    this.initialData,
  });

  @override
  List<Object?> get props => [workflowName, queryParameters, isSubFlow, displayLoading, initialData];
}

class NeoTransitionListenerEventPostTransition extends NeoTransitionListenerEvent {
  final String transitionName;
  final Map<String, dynamic> body;
  final String? instanceId;
  final bool isSubFlow;
  final bool displayLoading;

  NeoTransitionListenerEventPostTransition({
    required this.transitionName,
    required this.body,
    this.instanceId,
    this.isSubFlow = false,
    this.displayLoading = true,
  });

  @override
  List<Object?> get props => [transitionName, body, isSubFlow, displayLoading];
}
