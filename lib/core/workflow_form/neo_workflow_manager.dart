import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';
import 'package:neo_core/core/util/uuid_util.dart';
import 'package:neo_core/neo_core.dart';

abstract class _Constants {
  static const endpointInitWorkflow = "init-workflow";
  static const endpointGetAvailableTransitions = "get-workflow-available-steps";
  static const endpointGetLastEventByLongPolling = "get-last-wf-event-by-long-polling";
  static const pathParameterWorkflowName = "WORKFLOW_NAME";
  static const pathParameterInstanceId = "INSTANCE_ID";
  static const queryParameterInstanceId = "InstanceId";
  static const noWorkflowName = "-";
}

class NeoWorkflowManager {
  static const endpointPostTransition = "post-transition-to-workflow";
  static const pathParameterTransitionName = "TRANSITION_NAME";

  final NeoNetworkManager neoNetworkManager;
  String _instanceId = UuidUtil.generateUUID();
  String _subFlowInstanceId = UuidUtil.generateUUID();
  String _workflowName = "";
  String _subWorkflowName = "";

  NeoWorkflowManager(this.neoNetworkManager);

  bool get hasActiveWorkflow => _workflowName.isNotEmpty && _workflowName != _Constants.noWorkflowName;

  void resetInstanceId({bool isSubFlow = false}) {
    if (isSubFlow) {
      _subFlowInstanceId = UuidUtil.generateUUID();
      _log('[NeoWorkflowManager] Reset subFlow instanceId: $_subFlowInstanceId');
    } else {
      _instanceId = UuidUtil.generateUUID();
      _log('[NeoWorkflowManager] Reset instanceId: $_instanceId');
    }
  }

  void setInstanceId(String? newInstanceId, {bool isSubFlow = false}) {
    if (isSubFlow) {
      _subFlowInstanceId = newInstanceId ?? _subFlowInstanceId;
      _log('[NeoWorkflowManager] Set subFlow instanceId: $_subFlowInstanceId');
    } else {
      _instanceId = newInstanceId ?? _instanceId;
      _log('[NeoWorkflowManager] Set instanceId: $_instanceId');
    }
  }

  void setWorkflowName(String workflowName, {bool isSubFlow = false}) {
    if (isSubFlow) {
      _subWorkflowName = workflowName;
      _log('[NeoWorkflowManager] Set subWorkflowName: $_subWorkflowName');
    } else {
      _workflowName = workflowName;
      _log('[NeoWorkflowManager] Set workflowName: $_workflowName');
    }
  }

  String getWorkflowName({bool isSubFlow = false}) {
    return isSubFlow ? _subWorkflowName : _workflowName;
  }

  String get instanceId => _instanceId;

  String get subFlowInstanceId => _subFlowInstanceId;

  NeoLogger? get _neoLogger => GetIt.I.getIfReady<NeoLogger>();

  void _log(String message) {
    // Always print to ensure visibility even if logger is disabled
    // ignore: avoid_print
    print(message);
    final logger = _neoLogger;
    if (logger != null) {
      logger.logConsole(message);
    }
  }

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

    // Debug logging for request details
    final activeWorkflowName = _getActiveWorkflowName(isSubFlow: isSubFlow);
    _log('[NeoWorkflowManager] Init Workflow Request:');
    _log('  - Workflow Name: $activeWorkflowName');
    _log('  - Endpoint: ${_Constants.endpointInitWorkflow}');
    _log('  - Query Parameters: $queryParameters');
    _log('  - Header Parameters: $headerParameters');
    _log('  - Instance ID: ${isSubFlow ? _subFlowInstanceId : _instanceId}');

    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointInitWorkflow,
        pathParameters: {
          _Constants.pathParameterWorkflowName: _getActiveWorkflowName(isSubFlow: isSubFlow),
        },
        headerParameters: headerParameters ?? {},
        queryProviders: queryProviders,
      ),
    );
    
    // Enhanced logging for better debugging
    if (response is NeoSuccessResponse) {
      _log('[NeoWorkflowManager] Init Workflow SUCCESS: ${response.data}');
    } else if (response is NeoErrorResponse) {
      _log('[NeoWorkflowManager] Init Workflow ERROR:');
      _log('  - Error Type: ${response.error.errorType}');
      _log('  - Response Code: ${response.error.responseCode}');
      _log('  - Error Detail:');
      _log('    * Icon: ${response.error.error.icon}');
      _log('    * Title: ${response.error.error.title}');
      _log('    * Description: ${response.error.error.description}');
      _log('    * Close Button: ${response.error.error.closeButton}');
      _log('  - Error Body: ${response.error.body}');
      _log('  - Response Headers: ${response.headers}');
      _log('  - Full Error Object: ${response.error.toJson()}');
    } else {
      _log('[NeoWorkflowManager] Init Workflow UNKNOWN RESPONSE: $response');
    }
    
    return response;
  }

  Future<NeoResponse> getAvailableTransitions({String? instanceId}) async {
    setInstanceId(instanceId);
    _log('[NeoWorkflowManager] getAvailableTransitions for instanceId=$_instanceId');
    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: _Constants.endpointGetAvailableTransitions,
        pathParameters: {
          _Constants.pathParameterInstanceId: _instanceId,
        },
      ),
    );
    _log('[NeoWorkflowManager] Get Transitions: $response');
    return response;
  }

  Future<NeoResponse> postTransition({
    required String transitionName,
    required Map<String, dynamic> body,
    Map<String, String>? headerParameters,
    bool isSubFlow = false,
  }) async {
    final targetInstanceId = _getActiveInstanceId(isSubFlow: isSubFlow);
    _log('[NeoWorkflowManager] postTransition: transition=$transitionName, isSubFlow=$isSubFlow, instanceId=$targetInstanceId, bodyKeys=${body.keys.toList()}, headerKeys=${(headerParameters ?? {}).keys.toList()}');
    return neoNetworkManager.call(
      NeoHttpCall(
        endpoint: endpointPostTransition,
        pathParameters: {
          _Constants.pathParameterInstanceId: targetInstanceId,
          pathParameterTransitionName: transitionName,
        },
        headerParameters: headerParameters ?? {},
        body: body,
      ),
    );
  }

  Future<NeoResponse> getLastTransitionByLongPolling({bool isSubFlow = false}) async {
    final name = _getActiveWorkflowName(isSubFlow: isSubFlow);
    final id = _getActiveInstanceId(isSubFlow: isSubFlow);
    _log('[NeoWorkflowManager] getLastTransitionByLongPolling: workflowName=$name, instanceId=$id');
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

  String _getActiveWorkflowName({bool isSubFlow = false}) {
    return isSubFlow ? _subWorkflowName : _workflowName;
  }

  String _getActiveInstanceId({bool isSubFlow = false}) {
    return isSubFlow ? _subFlowInstanceId : _instanceId;
  }

  void terminateWorkflow() {
    _log('[NeoWorkflowManager] terminateWorkflow: clearing workflow and instance IDs');
    resetInstanceId();
    resetInstanceId(isSubFlow: true);
    _workflowName = _Constants.noWorkflowName;
    _subWorkflowName = _Constants.noWorkflowName;
  }
}
