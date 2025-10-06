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
import 'package:neo_core/core/network/interceptors/neo_user_internet_usage_interceptor.dart';
import 'package:neo_core/core/network/models/neo_signalr_event.dart';
import 'package:neo_core/core/network/models/neo_signalr_event_base_state.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';
import 'package:signalr_netcore/iretry_policy.dart';
import 'package:signalr_netcore/signalr_client.dart';

abstract class _Constants {
  static const eventNameSignalrOnClose = "[SignalrConnectionManager]: onClose is called!";
  static const eventNameSignalrInitSucceed = "[SignalrConnectionManager]: init is succeed!";
  static const eventNameSignalrInitFailed = "[SignalrConnectionManager]: init is failed!";
  static const eventCompletionStatusValues = ["worker-completed", "transition-completed"];
}

class _SignalRReconnectPolicy implements IRetryPolicy {
  @override
  int? nextRetryDelayInMilliseconds(RetryContext retryContext) {
    return null;
  }
}

class SignalrConnectionManager {
  HubConnection? _hubConnection;
  String? methodName;

  SignalrConnectionManager();

  NeoLogger get _neoLogger => GetIt.I.get();

  NeoUserInternetUsageInterceptor? get _internetUsageInterceptor =>
      GetIt.I.getIfReady<NeoUserInternetUsageInterceptor>();

  Future init({
    required String serverUrl,
    required String methodName,
    required Function({required bool hasConnection}) onConnectionStatusChanged,
  }) async {
    this.methodName = methodName;

    await stop();
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          serverUrl,
          options: HttpConnectionOptions(transport: HttpTransportType.WebSockets, skipNegotiation: true),
        )
        .withAutomaticReconnect(reconnectPolicy: _SignalRReconnectPolicy())
        .build();
    _hubConnection?.onclose(({error}) {
      onConnectionStatusChanged(hasConnection: false);
      _neoLogger.logCustom(
        _Constants.eventNameSignalrOnClose,
        logTypes: [NeoLoggerType.elastic, NeoLoggerType.logger],
      );
    });

    if (_hubConnection?.state != HubConnectionState.Connected) {
      try {
        await _hubConnection?.start();
        onConnectionStatusChanged(hasConnection: true);
        _neoLogger.logCustom(
          _Constants.eventNameSignalrInitSucceed,
          logTypes: [NeoLoggerType.elastic, NeoLoggerType.logger],
        );
      } catch (e) {
        onConnectionStatusChanged(hasConnection: false);
        _neoLogger
          ..logError("${_Constants.eventNameSignalrInitFailed} $e")
          ..logConsole(_Constants.eventNameSignalrInitFailed);
      }
    }
  }

  void listenForSignalREvents({required Function(NeoSignalREvent event) onEvent}) {
    if (methodName == null) {
      return;
    }
    _hubConnection?.on(methodName ?? "", (List<Object?>? transitions) {
      if (kDebugMode) {
        _neoLogger.logConsole('[SignalrConnectionManager] Transition: $transitions');
      }
      if (transitions == null) {
        return;
      }

      _internetUsageInterceptor?.interceptTransitions(transitions, _hubConnection?.baseUrl ?? "unknown");

      final NeoSignalREvent? ongoingEvent = _parseOngoingEvent(transitions);
      if (ongoingEvent == null) {
        return;
      }
      onEvent(ongoingEvent);
    });
  }

  NeoSignalREvent? _parseOngoingEvent(List<Object?> transitions) {
    return transitions
        .map((transition) {
          try {
            final transitionJsonDecoded = jsonDecode(transition is String ? transition : "{}");
            final event = NeoSignalREvent.fromJson(transitionJsonDecoded);
            if (!_Constants.eventCompletionStatusValues.contains(event.status) ||
                event.baseState != NeoSignalREventBaseState.completed) {
              return null;
            }
            return event;
          } catch (_) {
            return null;
          }
        })
        .nonNulls
        .toList()
        .firstOrNull;
  }

  Future<void> stop() async {
    try {
      await _hubConnection?.stop();
    } catch (_) {
      // No-op
    }
  }
}
