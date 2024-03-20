import 'package:flutter/material.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/neo_core.dart';
import 'package:uuid/uuid.dart';

abstract class _Constants {
  static const endpointInitWorkflow = "init-workflow";
  static const endpointGetAvailableTransitions = "get-workflow-available-steps";
  static const endpointGetLastEventByLongPolling = "get-last-wf-event-by-long-polling";
  static const endpointPostTransition = "post-transition-to-workflow";
  static const pathParameterTransitionName = "TRANSITION_NAME";
  static const pathParameterWorkflowName = "WORKFLOW_NAME";
  static const pathParameterInstanceId = "INSTANCE_ID";
  static const queryParameterInstanceId = "InstanceId";
  static const queryParameterSuffix = "suffix";
}

class NeoWorkflowManager {
  final NeoNetworkManager neoNetworkManager;
  static String _instanceId = const Uuid().v1();
  static String _subFlowInstanceId = const Uuid().v1();
  static String workflowName = "";
  static String subWorkflowName = "";

  NeoWorkflowManager(this.neoNetworkManager);

  static void resetInstanceId({required bool isSubFlow}) {
    if (isSubFlow) {
      _subFlowInstanceId = const Uuid().v1();
    } else {
      _instanceId = const Uuid().v1();
    }
  }

  static void setInstanceId(String? newInstanceId, {bool isSubFlow = false}) {
    if (isSubFlow) {
      _subFlowInstanceId = newInstanceId ?? _subFlowInstanceId;
    } else {
      _instanceId = newInstanceId ?? _instanceId;
    }
  }

  String getInstanceId({required bool isSubFlow}) {
    if (isSubFlow) {
      return _instanceId;
    } else {
      return _subFlowInstanceId;
    }
  }

  void _setWorkflowName(String workflowName, {required bool isSubFlow}) {
    if (isSubFlow) {
      NeoWorkflowManager.subWorkflowName = workflowName;
    } else {
      NeoWorkflowManager.workflowName = workflowName;
    }
  }

  String _getWorkflowName({required bool isSubFlow}) {
    if (isSubFlow) {
      return NeoWorkflowManager.subWorkflowName;
    } else {
      return NeoWorkflowManager.workflowName;
    }
  }

  Future<Map<String, dynamic>> initWorkflow({
    required String workflowName,
    String? suffix,
    bool isSubFlow = false,
  }) async {
    _setWorkflowName(workflowName, isSubFlow: isSubFlow);
    resetInstanceId(isSubFlow: isSubFlow);

    final List<HttpQueryProvider> queryProviders = [];
    if (suffix != null) {
      queryProviders.add(HttpQueryProvider({_Constants.queryParameterSuffix: suffix}));
    }

    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointInitWorkflow,
        pathParameters: {
          _Constants.pathParameterWorkflowName: _getWorkflowName(isSubFlow: isSubFlow),
        },
        queryProviders: queryProviders,
      ),
    );
    debugPrint('\n[NeoWorkflowManager] Init Workflow: $response');
    return response;
  }

  Future<Map<String, dynamic>> getAvailableTransitions({String? instanceId, bool isSubFlow = false}) async {
    setInstanceId(instanceId);
    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointGetAvailableTransitions,
        pathParameters: {
          _Constants.pathParameterInstanceId: getInstanceId(isSubFlow: isSubFlow),
        },
      ),
    );
    debugPrint('\n[NeoWorkflowManager] Get Transitions: $response');
    return response;
  }

  Future postTransition({
    required String transitionName,
    required Map<String, dynamic> body,
    bool isSubFlow = false,
  }) async {
    await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointPostTransition,
        pathParameters: {
          _Constants.pathParameterInstanceId: getInstanceId(isSubFlow: isSubFlow),
          _Constants.pathParameterTransitionName: transitionName,
        },
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> getLastTransitionByLongPolling({required bool isSubFlow}) async {
    return neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointGetLastEventByLongPolling,
        pathParameters: {_Constants.pathParameterWorkflowName: workflowName},
        queryProviders: [
          HttpQueryProvider({_Constants.queryParameterInstanceId: getInstanceId(isSubFlow: isSubFlow)}),
        ],
      ),
    );
  }
}
