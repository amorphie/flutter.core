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
  final NeoNetworkManager neoNetworkManager;
  final String signalRServerUrl;
  final String signalRMethodName;
  final Function(SignalrTransitionData navigationData) onTransitionSuccess;
  final Function(EkycEventData flowdata) onEkycEvent;
  final VoidCallback? onLoggedInSuccessfully;
  final Function(NeoError error)? onTransitionError;
  final Function({required bool displayLoading}) onLoadingStatusChanged;

  NeoTransitionListenerEventInit({
    required this.neoNetworkManager,
    required this.signalRServerUrl,
    required this.signalRMethodName,
    required this.onTransitionSuccess,
    required this.onEkycEvent,
    required this.onLoggedInSuccessfully,
    required this.onTransitionError,
    required this.onLoadingStatusChanged,
  });

  @override
  List<Object?> get props => [
        neoNetworkManager,
        signalRServerUrl,
        signalRMethodName,
        onTransitionSuccess,
        onLoggedInSuccessfully,
        onTransitionError,
        onLoadingStatusChanged,
      ];
}

class NeoTransitionListenerEventPostTransition extends NeoTransitionListenerEvent {
  final String transitionName;
  final Map<String, dynamic> body;

  NeoTransitionListenerEventPostTransition({required this.transitionName, required this.body});

  @override
  List<Object?> get props => [transitionName, body];
}
