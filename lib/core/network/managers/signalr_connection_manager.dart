/*
 * neo_core
 *
 * Created on 22/9/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'dart:convert';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/models/neo_signalr_transition.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalrConnectionManager {
  final String serverUrl;
  final String methodName;
  HubConnection? _hubConnection;

  SignalrConnectionManager({
    required this.serverUrl,
    required this.methodName,
  });

  Future init() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl)
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 20000]).build();
    _hubConnection?.onclose(({error}) {
      if (kDebugMode) {
        log('[SignalrConnectionManager]: onclose called');
      }
    });
    _hubConnection?.onreconnecting(({error}) {
      if (kDebugMode) {
        log('[SignalrConnectionManager]: onreconnecting called');
      }
    });
    _hubConnection?.onreconnected(({connectionId}) {
      if (kDebugMode) {
        log('[SignalrConnectionManager]: onreconnected called');
      }
    });

    if (_hubConnection?.state != HubConnectionState.Connected) {
      await _hubConnection?.start();
    }
  }

  void listenForTransitionEvents({
    required String transitionId,
    required Function(SignalrTransitionData navigationData) onPageNavigation,
    Function(String token, String refreshToken)? onTokenRetrieved,
    Function(String errorMessage)? onError,
  }) {
    _hubConnection?.on(methodName, (List<Object?>? transitions) {
      if (kDebugMode) {
        log('\n[SignalrConnectionManager] Transition: $transitions');
      }
      if (transitions == null) {
        return;
      }
      final NeoSignalRTransition? ongoingTransition = _parseOngoingTransition(transitions, transitionId);
      if (ongoingTransition == null) {
        return;
      }
      _retrieveTokenIfExist(ongoingTransition, onTokenRetrieved);
      _handleTransitionNavigation(ongoingTransition, onPageNavigation, onError);
    });
  }

  NeoSignalRTransition? _parseOngoingTransition(List<Object?> transitions, String transitionId) {
    return transitions
        .map((transition) {
          try {
            return NeoSignalRTransition.fromJson(jsonDecode(transition is String ? transition : "{}")["data"]);
          } catch (_) {
            return null;
          }
        })
        .whereNotNull()
        .toList()
        .firstWhereOrNull((transition) => transition.transitionId == transitionId);
  }

  void _retrieveTokenIfExist(
    NeoSignalRTransition ongoingTransition,
    Function(String token, String refreshToken)? onTokenRetrieved,
  ) {
    final String? token = ongoingTransition.additionalData?["access_token"];
    final String? refreshToken = ongoingTransition.additionalData?["refresh_token"];
    if (onTokenRetrieved != null && token != null && token.isNotEmpty) {
      onTokenRetrieved(token, refreshToken ?? "");
    }
  }

  void _handleTransitionNavigation(
    NeoSignalRTransition ongoingTransition,
    Function(SignalrTransitionData navigationData) onPageNavigation,
    Function(String errorMessage)? onError,
  ) {
    final isNavigationAllowed = ongoingTransition.pageDetails["operation"] == "Open";
    final navigationPath = ongoingTransition.pageDetails["pageRoute"]?["label"] as String?;
    final navigationType = ongoingTransition.pageDetails["type"] as String?;
    final isBackNavigation = ongoingTransition.buttonType == "Back";
    if (isNavigationAllowed && navigationPath != null) {
      onPageNavigation(
        SignalrTransitionData(
          navigationPath: navigationPath,
          navigationType: NeoNavigationType.fromJson(navigationType ?? ""),
          pageId: ongoingTransition.pageId,
          viewSource: ongoingTransition.viewSource,
          initialData: ongoingTransition.additionalData ?? {},
          isBackNavigation: isBackNavigation,
        ),
      );
    } else if ((ongoingTransition.errorMessage.isNotEmpty) && onError != null) {
      onError(ongoingTransition.errorMessage);
    }
  }

  void stop() {
    _hubConnection?.stop();
  }
}
