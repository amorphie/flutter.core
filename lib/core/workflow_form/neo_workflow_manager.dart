import 'package:flutter/material.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/util/uuid_util.dart';
import 'package:neo_core/neo_core.dart';

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
  String _instanceId = UuidUtil.generateUUID();
  String _subFlowInstanceId = UuidUtil.generateUUID();
  String _workflowName = "";
  String _subWorkflowName = "";

  NeoWorkflowManager(this.neoNetworkManager);

  void resetInstanceId({bool isSubFlow = false}) {
    if (isSubFlow) {
      _subFlowInstanceId = UuidUtil.generateUUID();
    } else {
      _instanceId = UuidUtil.generateUUID();
    }
  }

  void setInstanceId(String? newInstanceId, {bool isSubFlow = false}) {
    if (isSubFlow) {
      _subFlowInstanceId = newInstanceId ?? _subFlowInstanceId;
    } else {
      _instanceId = newInstanceId ?? _instanceId;
    }
  }

  String get instanceId => _instanceId;

  String get subFlowInstanceId => _subFlowInstanceId;

  Future<NeoResponse> initWorkflow({
    required String workflowName,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headerParameters,
    bool isSubFlow = false,
  }) async {
    if (isSubFlow) {
      _subWorkflowName = workflowName;
    } else {
      _workflowName = workflowName;
    }
    resetInstanceId(isSubFlow: isSubFlow);

    final List<HttpQueryProvider> queryProviders = [];
    if (queryParameters != null) {
      queryProviders.add(HttpQueryProvider(queryParameters));
    }

    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointInitWorkflow,
        pathParameters: {
          _Constants.pathParameterWorkflowName: _getActiveWorkflowName(isSubFlow: isSubFlow),
        },
        headerParameters: _getDefaultHeaderParameters(headerParameters, isSubFlow: isSubFlow),
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
    bool isSubFlow = false,
  }) async {
    await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointPostTransition,
        pathParameters: {
          _Constants.pathParameterInstanceId: _getActiveInstanceId(isSubFlow: isSubFlow),
          _Constants.pathParameterTransitionName: transitionName,
        },
        headerParameters: _getDefaultHeaderParameters(headerParameters, isSubFlow: isSubFlow),
        body: body,
      ),
    );
  }

  Future<NeoResponse> getLastTransitionByLongPolling({required bool isSubFlow}) async {
    return neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointGetLastEventByLongPolling,
        pathParameters: {_Constants.pathParameterWorkflowName: _getActiveWorkflowName(isSubFlow: isSubFlow)},
        queryProviders: [
          HttpQueryProvider({_Constants.queryParameterInstanceId: _getActiveInstanceId(isSubFlow: isSubFlow)}),
        ],
      ),
    );
  }

  Map<String, String> _getDefaultHeaderParameters(Map<String, String>? headerParameters, {required bool isSubFlow}) {
    return {
      NeoNetworkHeaderKey.instanceId: _getActiveInstanceId(isSubFlow: isSubFlow),
      NeoNetworkHeaderKey.workflowName: _getActiveWorkflowName(isSubFlow: isSubFlow),
    }..addAll(headerParameters ?? const {});
  }

  String _getActiveWorkflowName({required bool isSubFlow}) {
    return isSubFlow ? _subWorkflowName : _workflowName;
  }

  String _getActiveInstanceId({required bool isSubFlow}) {
    return isSubFlow ? _subFlowInstanceId : _instanceId;
  }
}
