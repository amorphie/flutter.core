/*
 * neo_core
 *
 * Created on 7/2/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/analytics/neo_logger_type.dart';
import 'package:neo_core/core/analytics/neo_posthog.dart';
import 'package:neo_core/core/feature_flags/neo_feature_flag_key.dart';
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/bloc/neo_transition_listener_bloc.dart';
import 'package:neo_core/core/workflow_form/neo_sub_workflow_manager.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:rxdart/rxdart.dart';

abstract class _Constants {
  static const signalrTimeOutDuration = Duration(seconds: 5);
  static const signalrLongPollingMaxRetryCount = 6;
  static const signalrBypassDelayDuration = Duration(seconds: 2);
  static const transitionResponseDataKey = "data";
  static const transitionBaseStateKey = "base-state";
  static const transitionBaseStateNewValue = "New";
  static const transitionBaseStateInProgressValue = "InProgress";
}

mixin NeoTransitionBus on Bloc<NeoTransitionListenerEvent, NeoTransitionListenerState> {
  late final BehaviorSubject<NeoSignalRTransition> _transitionBus = BehaviorSubject();
  late final NeoWorkflowManager neoWorkflowManager;
  late final NeoSubWorkflowManager neoSubWorkflowManager;
  late final SignalrConnectionManager signalrConnectionManager;
  late bool _bypassSignalr;

  late final NeoLogger _neoLogger = GetIt.I.get();

  NeoWorkflowManager currentWorkflowManager({required bool isSubFlow}) {
    return isSubFlow ? neoSubWorkflowManager : neoWorkflowManager;
  }

  Future<void> initTransitionBus({
    required NeoWorkflowManager neoWorkflowManager,
    required NeoSubWorkflowManager neoSubWorkflowManager,
    required NeoPosthog neoPosthog,
    required String signalrServerUrl,
    required String signalrMethodName,
    required bool bypassSignalr,
  }) async {
    this.neoWorkflowManager = neoWorkflowManager;
    this.neoSubWorkflowManager = neoSubWorkflowManager;
    _bypassSignalr =
        bypassSignalr || (await neoPosthog.isFeatureEnabled(NeoFeatureFlagKey.bypassSignalR.value) ?? false);
    if (!_bypassSignalr) {
      await _initSignalrConnectionManager(signalrServerUrl: signalrServerUrl, signalrMethodName: signalrMethodName);
    }
  }

  Future<NeoResponse> initWorkflow({
    required String workflowName,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headerParameters,
    String? instanceId,
    bool isSubFlow = false,
  }) {
    if (instanceId == null) {
      return currentWorkflowManager(isSubFlow: isSubFlow).initWorkflow(
        workflowName: workflowName,
        queryParameters: queryParameters,
        headerParameters: headerParameters,
      );
    } else {
      return currentWorkflowManager(isSubFlow: isSubFlow).getAvailableTransitions(instanceId: instanceId);
    }
  }

  Future<String?> getAvailableTransitionId(NeoSignalRTransition ongoingTransition) async {
    if (ongoingTransition.viewSource == "transition") {
      final response = await neoWorkflowManager.getAvailableTransitions();
      if (response.isSuccess) {
        return response.asSuccess.data["transition"]?.first["transition"];
      }
    }
    return null;
  }

  Future<NeoSignalRTransition?> postTransition(
    String transitionId,
    Map<String, dynamic> body, {
    Map<String, String>? headerParameters,
    bool isSubFlow = false,
    bool ignoreResponse = false,
  }) async {
    final completer = Completer<NeoSignalRTransition?>();
    StreamSubscription<NeoSignalRTransition>? transitionBusSubscription;

    if (!_bypassSignalr) {
      // Skip last transition event(currently at bus if it is not initial post request)
      // and listen for first upcoming event
      final stream = (_transitionBus.valueOrNull != null) ? _transitionBus.skip(1) : _transitionBus;
      transitionBusSubscription = stream.listen((transition) {
        if (!completer.isCompleted) {
          completer.complete(transition);
        }
      });
    }
    await currentWorkflowManager(isSubFlow: isSubFlow).postTransition(
      transitionName: transitionId,
      body: body,
      headerParameters: headerParameters,
    );

    if (ignoreResponse) {
      return null;
    }
    unawaited(
      _getTransitionWithLongPolling(
        completer,
        isSubFlow: isSubFlow,
        retryCount: _Constants.signalrLongPollingMaxRetryCount,
      ),
    );

    return completer.future.whenComplete(() async {
      await transitionBusSubscription?.cancel();
    });
  }

  Future<void> _initSignalrConnectionManager({
    required String signalrServerUrl,
    required String signalrMethodName,
  }) async {
    signalrConnectionManager = SignalrConnectionManager(
      serverUrl: signalrServerUrl,
      methodName: signalrMethodName,
    );
    await signalrConnectionManager.init();
    signalrConnectionManager.listenForTransitionEvents(
      onTransition: (NeoSignalRTransition transition) async {
        final isDifferentTransition = _transitionBus.hasValue && _transitionBus.value.id != transition.id;
        // Add different events only
        if (!_transitionBus.hasValue || isDifferentTransition) {
          _transitionBus.add(transition);
        }
      },
    );
  }

  Future<void> _getTransitionWithLongPolling(
    Completer<NeoSignalRTransition?> completer, {
    required bool isSubFlow,
    required int retryCount,
  }) async {
    if (retryCount == 0) {
      completer.completeError(const NeoError());
      return;
    }
    await Future.delayed(_bypassSignalr ? _Constants.signalrBypassDelayDuration : _Constants.signalrTimeOutDuration);

    if (completer.isCompleted) {
      return;
    }
    _neoLogger.logCustom(
      "[NeoTransitionListener]: No transition event within ${_Constants.signalrTimeOutDuration.inSeconds} seconds! Retrieving last event by long polling...",
      logTypes: [NeoLoggerType.posthog],
    );

    final response = await currentWorkflowManager(isSubFlow: isSubFlow).getLastTransitionByLongPolling();
    if (response.isSuccess) {
      if (!completer.isCompleted) {
        final responseData = response.asSuccess.data;
        final isTransitionInProgress =
            responseData[_Constants.transitionBaseStateKey] == _Constants.transitionBaseStateInProgressValue;
        if (isTransitionInProgress) {
          return _getTransitionWithLongPolling(completer, isSubFlow: isSubFlow, retryCount: retryCount - 1);
        } else if (responseData[_Constants.transitionBaseStateKey] == _Constants.transitionBaseStateNewValue) {
          completer.complete(null);
        } else {
          completer.complete(NeoSignalRTransition.fromJson(responseData[_Constants.transitionResponseDataKey]));
        }
      }
    } else {
      _neoLogger.logCustom(
        "[NeoTransitionListener]: Retrieving last event by long polling is failed!",
        logTypes: [NeoLoggerType.posthog],
      );
      if (!completer.isCompleted) {
        completer.completeError(response.asError.error);
      }
    }
  }

  @override
  Future<void> close() {
    signalrConnectionManager.stop();
    _transitionBus.close();
    return super.close();
  }
}
