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

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/analytics/neo_logger_type.dart';
import 'package:neo_core/core/network/models/neo_signalr_transition.dart';
import 'package:signalr_netcore/signalr_client.dart';

abstract class _Constants {
  static const eventNameSignalrOnClose = "[SignalrConnectionManager]: onClose is called!";
  static const eventNameSignalrOnReconnecting = "[SignalrConnectionManager]: onReconnecting is called!";
  static const eventNameSignalrOnReconnected = "[SignalrConnectionManager]: onReconnected is called!";
  static const eventNameSignalrInitSucceed = "[SignalrConnectionManager]: init is succeed!";
  static const eventNameSignalrInitFailed = "[SignalrConnectionManager]: init is failed!";
  static const transitionSubjectKey = "subject";
  static const transitionSubjectValue = ["worker-completed", "transition-completed"];
  static const transitionResponseDataKey = "data";
}

class SignalrConnectionManager {
  final String serverUrl;
  final String methodName;

  HubConnection? _hubConnection;

  SignalrConnectionManager({required this.serverUrl, required this.methodName});

  NeoLogger get _neoLogger => GetIt.I.get();

  Future init() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(
      serverUrl,
      options: HttpConnectionOptions(transport: HttpTransportType.WebSockets, skipNegotiation: true),
    )
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 20000]).build();
    _hubConnection?.onclose(({error}) {
      _neoLogger.logCustom(
        _Constants.eventNameSignalrOnClose,
        logTypes: [NeoLoggerType.posthog, NeoLoggerType.logger],
      );
    });
    _hubConnection?.onreconnecting(({error}) {
      _neoLogger.logCustom(
        _Constants.eventNameSignalrOnReconnecting,
        logTypes: [NeoLoggerType.posthog, NeoLoggerType.logger],
      );
    });
    _hubConnection?.onreconnected(({connectionId}) {
      _neoLogger.logCustom(
        _Constants.eventNameSignalrOnReconnected,
        logTypes: [NeoLoggerType.posthog, NeoLoggerType.logger],
      );
    });

    if (_hubConnection?.state != HubConnectionState.Connected) {
      try {
        await _hubConnection?.start();
        _neoLogger.logCustom(
          _Constants.eventNameSignalrInitSucceed,
          logTypes: [NeoLoggerType.posthog, NeoLoggerType.logger],
        );
      } on Exception catch (e, stacktrace) {
        _neoLogger
          ..logException("${_Constants.eventNameSignalrInitFailed} $e", stacktrace)
          ..logConsole(_Constants.eventNameSignalrInitFailed);
      }
    }
  }

  void listenForTransitionEvents({required Function(NeoSignalRTransition transition) onTransition}) {
    _hubConnection?.on(methodName, (List<Object?>? transitions) {
      if (kDebugMode) {
        _neoLogger.logConsole('[SignalrConnectionManager] Transition: $transitions');
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
            if (!_Constants.transitionSubjectValue.contains(transitionJsonDecoded[_Constants.transitionSubjectKey])) {
              return null;
            }
            return NeoSignalRTransition.fromJson(transitionJsonDecoded[_Constants.transitionResponseDataKey]);
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
