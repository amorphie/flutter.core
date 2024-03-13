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
import 'package:neo_core/core/feature_flags/neo_feature_flag_util.dart';
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/bloc/neo_transition_listener_bloc.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:rxdart/rxdart.dart';

abstract class _Constants {
  static const signalrTimeOutDuration = Duration(seconds: 10);
  static const signalrBypassDelayDuration = Duration(seconds: 2);
  static const transitionResponseDataKey = "data";
}

mixin NeoTransitionBus on Bloc<NeoTransitionListenerEvent, NeoTransitionListenerState> {
  late final BehaviorSubject<NeoSignalRTransition> _transitionBus = BehaviorSubject();
  late final NeoWorkflowManager neoWorkflowManager;
  late final SignalrConnectionManager signalrConnectionManager;
  late bool _bypassSignalr;

  Future<void> initTransitionBus({
    required NeoWorkflowManager neoWorkflowManager,
    required String signalrServerUrl,
    required String signalrMethodName,
  }) async {
    this.neoWorkflowManager = neoWorkflowManager;
    _bypassSignalr = await NeoFeatureFlagUtil.bypassSignalR();
    if (!_bypassSignalr) {
      await _initSignalrConnectionManager(signalrServerUrl: signalrServerUrl, signalrMethodName: signalrMethodName);
    }
  }

  Future<Map<String, dynamic>> initWorkflow({required String workflowName, String? suffix, String? instanceId}) {
    if (instanceId == null) {
      return neoWorkflowManager.initWorkflow(workflowName: workflowName, suffix: suffix);
    } else {
      return neoWorkflowManager.getAvailableTransitions(instanceId: instanceId);
    }
  }

  Future<String?> getAvailableTransitionId(NeoSignalRTransition ongoingTransition) async {
    if (ongoingTransition.viewSource == "transition") {
      final workflowData = await neoWorkflowManager.getAvailableTransitions();
      return workflowData["transition"]?.first["transition"];
    }
    return null;
  }

  Future<NeoSignalRTransition> postTransition(String transitionId, Map<String, dynamic> body) async {
    final completer = Completer<NeoSignalRTransition>();
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
    await neoWorkflowManager.postTransition(transitionName: transitionId, body: body);

    unawaited(_getTransitionWithLongPolling(completer));

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

  Future<void> _getTransitionWithLongPolling(Completer<NeoSignalRTransition> completer) async {
    await Future.delayed(_bypassSignalr ? _Constants.signalrBypassDelayDuration : _Constants.signalrTimeOutDuration);

    if (completer.isCompleted) {
      return;
    }
    try {
      final response = await neoWorkflowManager.getLastTransitionByLongPolling();
      if (!completer.isCompleted) {
        completer.complete(NeoSignalRTransition.fromJson(response[_Constants.transitionResponseDataKey]));
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(NeoError.defaultError());
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
