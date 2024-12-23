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
  final NeoPosthog neoPosthog;
  final String signalRServerUrl;
  final String signalRMethodName;
  final Function(SignalrTransitionData navigationData) onTransitionEvent;
  final Function(EkycEventData eventData) onEkycEvent;
  final Function({required bool isTwoFactorAuthenticated})? onLoggedInSuccessfully;
  final Function(NeoError error, {required bool displayAsPopup})? onTransitionError;
  final Function({required bool displayLoading}) onLoadingStatusChanged;
  final bool bypassSignalr;
  final Duration signalrLongPollingPeriod;
  final Duration signalRTimeoutDuration;

  NeoTransitionListenerEventInit({
    required this.neoWorkflowManager,
    required this.neoPosthog,
    required this.signalRServerUrl,
    required this.signalRMethodName,
    required this.onTransitionEvent,
    required this.onEkycEvent,
    required this.onLoggedInSuccessfully,
    required this.onTransitionError,
    required this.onLoadingStatusChanged,
    required this.bypassSignalr,
    required this.signalrLongPollingPeriod,
    required this.signalRTimeoutDuration,
  });

  @override
  List<Object?> get props => [
        neoWorkflowManager,
        neoPosthog,
        signalRServerUrl,
        signalRMethodName,
        onTransitionEvent,
        onEkycEvent,
        onLoggedInSuccessfully,
        onTransitionError,
        onLoadingStatusChanged,
        bypassSignalr,
        signalrLongPollingPeriod,
        signalRTimeoutDuration,
      ];
}

class NeoTransitionListenerEventInitWorkflow extends NeoTransitionListenerEvent {
  final String workflowName;
  final Map<String, dynamic>? queryParameters;
  final Map<String, String>? headerParameters;
  final bool displayLoading;
  final bool isSubFlow;
  final Map<String, dynamic>? initialData;
  final NeoNavigationType? navigationType;
  final bool useSubNavigator;

  NeoTransitionListenerEventInitWorkflow({
    required this.workflowName,
    this.queryParameters,
    this.headerParameters,
    this.isSubFlow = false,
    this.displayLoading = true,
    this.initialData,
    this.navigationType,
    this.useSubNavigator = false,
  });

  @override
  List<Object?> get props => [
        workflowName,
        queryParameters,
        headerParameters,
        isSubFlow,
        displayLoading,
        initialData,
        navigationType,
        useSubNavigator,
      ];
}

class NeoTransitionListenerEventPostTransition extends NeoTransitionListenerEvent {
  final String transitionName;
  final Map<String, dynamic> body;
  final Map<String, String>? headerParameters;
  final bool displayLoading;
  final bool isSubFlow;

  NeoTransitionListenerEventPostTransition({
    required this.transitionName,
    required this.body,
    this.headerParameters,
    this.displayLoading = true,
    this.isSubFlow = false,
  });

  @override
  List<Object?> get props => [transitionName, body, headerParameters, displayLoading, isSubFlow];
}

class NeoTransitionListenerEventStopListening extends NeoTransitionListenerEvent {
  @override
  List<Object?> get props => [];
}
