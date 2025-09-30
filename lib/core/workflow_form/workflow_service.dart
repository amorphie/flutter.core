/*
 * neo_core
 *
 * Created on 23/9/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';
import 'package:neo_core/core/workflow_form/workflow_router.dart';

/// Result of a workflow operation
class WorkflowResult {
  final bool isSuccess;
  final String? instanceId;
  final Map<String, dynamic>? data;
  final String? error;

  const WorkflowResult._({
    required this.isSuccess,
    this.instanceId,
    this.data,
    this.error,
  });

  factory WorkflowResult.success({
    String? instanceId,
    Map<String, dynamic>? data,
  }) {
    return WorkflowResult._(
      isSuccess: true,
      instanceId: instanceId,
      data: data,
    );
  }

  factory WorkflowResult.error(String error) {
    return WorkflowResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Pure workflow service - NO Flutter dependencies
/// Provides clean business logic interface for workflow operations
class WorkflowService {
  final WorkflowRouter _router;
  final WorkflowInstanceManager _instanceManager;
  final NeoLogger _logger;

  WorkflowService({
    required WorkflowRouter router,
    required WorkflowInstanceManager instanceManager,
    required NeoLogger logger,
  })  : _router = router,
        _instanceManager = instanceManager,
        _logger = logger;

  /// Initialize a workflow with the appropriate engine (amorphie/vNext)
  /// Returns WorkflowResult with instance ID and page data
  Future<WorkflowResult> initWorkflow({
    required String workflowName,
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    bool isSubFlow = false,
  }) async {
    try {
      _logger.logConsole('[WorkflowService] Initializing workflow: $workflowName');

      final response = await _router.initWorkflow(
        workflowName: workflowName,
        queryParameters: parameters,
        headerParameters: headers,
        isSubFlow: isSubFlow,
      );

      if (response.isSuccess) {
        final data = response.asSuccess.data;
        
        final instanceId = _router.getInstanceId(isSubFlow: isSubFlow);
        
        _logger.logConsole('[WorkflowService] Workflow initialized successfully: $instanceId');
        _logger.logConsole('[WorkflowService] InstanceId source: ${instanceId != null ? (data.containsKey('instanceId') ? 'server (vNext)' : 'client-generated (amorphie)') : 'unknown'}');
        
        return WorkflowResult.success(
          instanceId: instanceId,
          data: data,
        );
      } else {
        final error = response.asError.error.error.description;
        _logger.logError('[WorkflowService] Workflow initialization failed: $error');
        
        return WorkflowResult.error(error);
      }
    } catch (e) {
      final errorMessage = 'Workflow initialization exception: $e';
      _logger.logError('[WorkflowService] $errorMessage');
      
      return WorkflowResult.error(errorMessage);
    }
  }

  /// Post a transition to a workflow instance
  /// Automatically routes to the correct engine based on instance
  Future<WorkflowResult> postTransition({
    required String transitionName,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    bool isSubFlow = false,
  }) async {
    try {
      _logger.logConsole('[WorkflowService] Posting transition: $transitionName');

      final response = await _router.postTransition(
        transitionName: transitionName,
        body: body,
        headerParameters: headers,
        isSubFlow: isSubFlow,
      );

      if (response.isSuccess) {
        final data = response.asSuccess.data;
        final instanceId = body['instanceId'] as String? ?? data['instanceId'] as String?;
        
        _logger.logConsole('[WorkflowService] Transition posted successfully: $instanceId');
        
        return WorkflowResult.success(
          instanceId: instanceId,
          data: data,
        );
      } else {
        final error = response.asError.error.error.description;
        _logger.logError('[WorkflowService] Transition failed: $error');
        
        return WorkflowResult.error(error);
      }
    } catch (e) {
      final errorMessage = 'Transition exception: $e';
      _logger.logError('[WorkflowService] $errorMessage');
      
      return WorkflowResult.error(errorMessage);
    }
  }

  /// Get all active workflow instances
  List<WorkflowInstanceEntity> getActiveWorkflows() {
    return _instanceManager.getActiveWorkflows();
  }

  /// Get workflows by engine type
  List<WorkflowInstanceEntity> getWorkflowsByEngine(WorkflowEngine engine) {
    return _instanceManager.getWorkflowsByEngine(engine);
  }

  /// Search workflow instances with filters
  List<WorkflowInstanceEntity> searchInstances({
    String? workflowName,
    WorkflowInstanceStatus? status,
    WorkflowEngine? engine,
    String? domain,
    Map<String, dynamic>? attributeFilters,
  }) {
    return _instanceManager.searchInstances(
      workflowName: workflowName,
      status: status,
      engine: engine,
      domain: domain,
      attributeFilters: attributeFilters,
    );
  }

  /// Terminate a specific workflow instance
  bool terminateInstance(String instanceId, {String? reason}) {
    _instanceManager.terminateInstance(instanceId, reason: reason);
    return true;
  }

  /// Query workflow instances with enhanced filtering
  /// Provides access to vNext's powerful filtering capabilities
  Future<WorkflowResult> queryWorkflowInstances({
    required String workflowName,
    String? domain,
    Map<String, String>? attributeFilters,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      _logger.logConsole('[WorkflowService] Querying instances for workflow: $workflowName');

      final response = await _router.queryWorkflowInstances(
        workflowName: workflowName,
        domain: domain,
        attributeFilters: attributeFilters,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      if (response.isSuccess) {
        final data = response.asSuccess.data;
        _logger.logConsole('[WorkflowService] Query successful');
        
        return WorkflowResult.success(data: data);
      } else {
        final error = response.asError.error.error.description;
        _logger.logError('[WorkflowService] Query failed: $error');
        
        return WorkflowResult.error(error);
      }
    } catch (e) {
      final errorMessage = 'Query instances exception: $e';
      _logger.logError('[WorkflowService] $errorMessage');
      
      return WorkflowResult.error(errorMessage);
    }
  }

  /// Get workflow instance history
  /// Provides access to instance state transitions and history
  Future<WorkflowResult> getInstanceHistory({
    required String instanceId,
    required String workflowName,
    required String domain,
  }) async {
    try {
      _logger.logConsole('[WorkflowService] Getting history for instance: $instanceId');

      final response = await _router.getInstanceHistory(
        instanceId: instanceId,
        workflowName: workflowName,
        domain: domain,
      );

      if (response.isSuccess) {
        final data = response.asSuccess.data;
        _logger.logConsole('[WorkflowService] History retrieved successfully');
        
        return WorkflowResult.success(data: data);
      } else {
        final error = response.asError.error.error.description;
        _logger.logError('[WorkflowService] History retrieval failed: $error');
        
        return WorkflowResult.error(error);
      }
    } catch (e) {
      final errorMessage = 'Get instance history exception: $e';
      _logger.logError('[WorkflowService] $errorMessage');
      
      return WorkflowResult.error(errorMessage);
    }
  }

  /// Get system health status
  /// Provides access to workflow system health monitoring
  Future<WorkflowResult> getSystemHealth() async {
    try {
      _logger.logConsole('[WorkflowService] Getting system health');

      final response = await _router.getSystemHealth();

      if (response.isSuccess) {
        final data = response.asSuccess.data;
        _logger.logConsole('[WorkflowService] Health check successful');
        
        return WorkflowResult.success(data: data);
      } else {
        final error = response.asError.error.error.description;
        _logger.logError('[WorkflowService] Health check failed: $error');
        
        return WorkflowResult.error(error);
      }
    } catch (e) {
      final errorMessage = 'Get system health exception: $e';
      _logger.logError('[WorkflowService] $errorMessage');
      
      return WorkflowResult.error(errorMessage);
    }
  }

  /// Get system metrics
  /// Provides access to workflow system metrics for monitoring
  Future<WorkflowResult> getSystemMetrics() async {
    try {
      _logger.logConsole('[WorkflowService] Getting system metrics');

      final response = await _router.getSystemMetrics();

      if (response.isSuccess) {
        final data = response.asSuccess.data;
        _logger.logConsole('[WorkflowService] Metrics retrieved successfully');
        
        return WorkflowResult.success(data: data);
      } else {
        final error = response.asError.error.error.description;
        _logger.logError('[WorkflowService] Metrics retrieval failed: $error');
        
        return WorkflowResult.error(error);
      }
    } catch (e) {
      final errorMessage = 'Get system metrics exception: $e';
      _logger.logError('[WorkflowService] $errorMessage');
      
      return WorkflowResult.error(errorMessage);
    }
  }
}
