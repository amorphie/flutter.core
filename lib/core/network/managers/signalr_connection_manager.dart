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
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/neo_signalr_transition.dart';
import 'package:signalr_netcore/signalr_client.dart';

abstract class _Constants {
  static const eventNameSignalrOnClose = "[SignalrConnectionManager]: onClose is called!";
  static const eventNameSignalrOnReconnecting = "[SignalrConnectionManager]: onReconnecting is called!";
  static const eventNameSignalrOnReconnected = "[SignalrConnectionManager]: onReconnected is called!";
  static const eventNameSignalrInitSucceed = "[SignalrConnectionManager]: init is succeed!";
  static const eventNameSignalrInitFailed = "[SignalrConnectionManager]: init is failed!";
  static const transitionSubjectKey = "subject";
  static const transitionSubjectValue = "worker-completed";
}

class SignalrConnectionManager {
  final String serverUrl;
  final String methodName;
  final NeoLogger _neoLogger;

  HubConnection? _hubConnection;

  SignalrConnectionManager({
    required this.serverUrl,
    required this.methodName,
  }) : _neoLogger = NeoLogger();

  Future init() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl)
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 20000]).build();
    _hubConnection?.onclose(({error}) {
      _neoLogger.logEvent(_Constants.eventNameSignalrOnClose);
      debugPrint(_Constants.eventNameSignalrOnClose);
    });
    _hubConnection?.onreconnecting(({error}) {
      _neoLogger.logEvent(_Constants.eventNameSignalrOnReconnecting);
      debugPrint(_Constants.eventNameSignalrOnReconnecting);
    });
    _hubConnection?.onreconnected(({connectionId}) {
      _neoLogger.logEvent(_Constants.eventNameSignalrOnReconnected);
      debugPrint(_Constants.eventNameSignalrOnReconnected);
    });

    if (_hubConnection?.state != HubConnectionState.Connected) {
      try {
        await _hubConnection?.start();
        _neoLogger.logEvent(_Constants.eventNameSignalrInitSucceed);
        debugPrint(_Constants.eventNameSignalrInitSucceed);
      } on Exception catch (e, stacktrace) {
        _neoLogger.logException("${_Constants.eventNameSignalrInitFailed} $e", stacktrace);
        debugPrint(_Constants.eventNameSignalrInitFailed);
      }
    }
  }

  void listenForTransitionEvents({required Function(NeoSignalRTransition transition) onTransition}) {
    _hubConnection?.on(methodName, (List<Object?>? transitions) {
      if (kDebugMode) {
        log('\n[SignalrConnectionManager] Transition: $transitions');
      }
      if (transitions == null) {
        return;
      }
      final NeoSignalRTransition? ongoingTransition = _parseOngoingTransition(transitions);
      if (ongoingTransition == null) {
        return;
      }
      onTransition(ongoingTransition);
    });
  }

  NeoSignalRTransition? _parseOngoingTransition(List<Object?> transitions) {
    return transitions
        .map((transition) {
          try {
            final transitionJsonDecoded = jsonDecode(transition is String ? transition : "{}");
            if (transitionJsonDecoded[_Constants.transitionSubjectKey] != _Constants.transitionSubjectValue) {
              return null;
            }
            return NeoSignalRTransition.fromJson(transitionJsonDecoded["data"]);
          } catch (_) {
            return null;
          }
        })
        .whereNotNull()
        .toList()
        .firstOrNull;
  }

  void stop() {
    _hubConnection?.stop();
  }
}
