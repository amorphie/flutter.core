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
}

class NeoWorkflowManager {
  final NeoNetworkManager neoNetworkManager;
  String _instanceId = const Uuid().v1();
  static String workflowName = "";

  NeoWorkflowManager(this.neoNetworkManager);

  void resetInstanceId() {
    _instanceId = const Uuid().v1();
  }

  void setInstanceId(String? newInstanceId) {
    _instanceId = newInstanceId ?? _instanceId;
  }

  String get instanceId => _instanceId;

  Future<NeoResponse> initWorkflow({
    required String workflowName,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headerParameters,
  }) async {
    NeoWorkflowManager.workflowName = workflowName;
    resetInstanceId();

    final List<HttpQueryProvider> queryProviders = [];
    if (queryParameters != null) {
      queryProviders.add(HttpQueryProvider(queryParameters));
    }

    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointInitWorkflow,
        pathParameters: {
          _Constants.pathParameterWorkflowName: workflowName,
        },
        headerParameters: headerParameters ?? const {},
        queryProviders: queryProviders,
      ),
    );
    debugPrint('\n[NeoWorkflowManager] Init Workflow: $response');
    return response;
  }

  Future<NeoResponse> getAvailableTransitions({String? instanceId}) async {
    setInstanceId(instanceId);
    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointGetAvailableTransitions,
        pathParameters: {
          _Constants.pathParameterInstanceId: _instanceId,
        },
      ),
    );
    debugPrint('\n[NeoWorkflowManager] Get Transitions: $response');
    return response;
  }

  Future postTransition({
    required String transitionName,
    required Map<String, dynamic> body,
    Map<String, String>? headerParameters,
  }) async {
    await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointPostTransition,
        pathParameters: {
          _Constants.pathParameterInstanceId: _instanceId,
          _Constants.pathParameterTransitionName: transitionName,
        },
        headerParameters: headerParameters ?? const {},
        body: body,
      ),
    );
  }

  Future<NeoResponse> getLastTransitionByLongPolling() async {
    return neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointGetLastEventByLongPolling,
        pathParameters: {_Constants.pathParameterWorkflowName: workflowName},
        queryProviders: [
          HttpQueryProvider({_Constants.queryParameterInstanceId: _instanceId}),
        ],
      ),
    );
  }
}
