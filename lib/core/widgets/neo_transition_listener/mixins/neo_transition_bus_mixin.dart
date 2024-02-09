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
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/widgets/neo_transition_listener/bloc/neo_transition_listener_bloc.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:rxdart/rxdart.dart';

abstract class _Constants {
  static const signalrTimeOutDuration = Duration(seconds: 10);
  static const transitionResponseDataKey = "data";
}

mixin NeoTransitionBus on Bloc<NeoTransitionListenerEvent, NeoTransitionListenerState> {
  late final BehaviorSubject<NeoSignalRTransition> _transitionBus = BehaviorSubject();
  late final NeoWorkflowManager neoWorkflowManager;
  late final SignalrConnectionManager signalrConnectionManager;

  Future<void> initTransitionBus({
    required NeoWorkflowManager neoWorkflowManager,
    required String signalrServerUrl,
    required String signalrMethodName,
  }) async {
    this.neoWorkflowManager = neoWorkflowManager;
    await _initSignalrConnectionManager(signalrServerUrl: signalrServerUrl, signalrMethodName: signalrMethodName);
  }

  Future<Map<String, dynamic>> initWorkflow(String workflowName) {
    return neoWorkflowManager.initWorkflow(workflowName: workflowName);
  }

  Future<NeoSignalRTransition> postTransition(String transitionId, Map<String, dynamic> body) async {
    final completer = Completer<NeoSignalRTransition>();

    // Skip last transition event(currently at bus if it is not initial post request)
    // and listen for first upcoming event
    final stream = (_transitionBus.valueOrNull != null) ? _transitionBus.skip(1) : _transitionBus;
    final subscription = stream.listen((transition) {
      if (transition.transitionId == transitionId) {
        completer.complete(transition);
      }
    });

    unawaited(neoWorkflowManager.postTransition(transitionName: transitionId, body: body));
    unawaited(_getTransitionWithLongPolling(completer));

    return completer.future.whenComplete(() async {
      await subscription.cancel();
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
      onTransition: (NeoSignalRTransition transition) {
        _transitionBus.add(transition);
      },
    );
  }

  Future<void> _getTransitionWithLongPolling(Completer<NeoSignalRTransition> completer) async {
    await Future.delayed(_Constants.signalrTimeOutDuration);
    if (completer.isCompleted) {
      return;
    }
    try {
      final response = await neoWorkflowManager.getLastTransitionByLongPolling();
      completer.complete(NeoSignalRTransition.fromJson(response[_Constants.transitionResponseDataKey]));
    } catch (e) {
      completer.completeError(NeoError.defaultError());
    }
  }

  @override
  Future<void> close() {
    signalrConnectionManager.stop();
    _transitionBus.close();
    return super.close();
  }
}
