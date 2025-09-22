/*
 * neo_core
 *
 * Created on 18/9/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/http_client_config.dart';
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_client.dart';
import 'package:neo_core/core/workflow_form/workflow_engine_config.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';

/// Configuration for workflow routing decisions
class WorkflowRouterConfig {
  final bool enableV2Workflows;
  final String? vNextBaseUrl;
  final String? vNextDomain;

  WorkflowRouterConfig({
    this.enableV2Workflows = false,
    this.vNextBaseUrl,
    this.vNextDomain,
  });

  bool get canUseV2 => 
      enableV2Workflows && 
      vNextBaseUrl != null && 
      vNextBaseUrl!.isNotEmpty &&
      vNextDomain != null && 
      vNextDomain!.isNotEmpty;
}

/// Enhanced router that directs workflow operations to V1 or V2 implementations
/// with configuration-driven engine selection and multi-instance support
class EnhancedWorkflowRouter {
  final NeoWorkflowManager v1Manager;
  final VNextWorkflowClient v2Client;
  final NeoLogger logger;
  final HttpClientConfig httpClientConfig;
  final WorkflowInstanceManager instanceManager;

  EnhancedWorkflowRouter({
    required this.v1Manager,
    required this.v2Client,
    required this.logger,
    required this.httpClientConfig,
    required this.instanceManager,
  });

  /// Get workflow engine configuration for a workflow name
  WorkflowEngineConfig _getConfigForWorkflow(String workflowName) {
    return httpClientConfig.getWorkflowConfig(workflowName);
  }

  /// Initialize workflow - routes to V1 or V2 based on configuration
  Future<NeoResponse> initWorkflow({
    required String workflowName,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headerParameters,
    bool isSubFlow = false,
  }) async {
    final engineConfig = _getConfigForWorkflow(workflowName);
    
    logger.logConsole('[EnhancedWorkflowRouter] initWorkflow called for: $workflowName, engine: ${engineConfig.engine}, valid: ${engineConfig.isValid}');

    if (engineConfig.isVNext && engineConfig.isValid) {
      return _initvNextWorkflow(workflowName, engineConfig, queryParameters, headerParameters, isSubFlow);
    } else {
      return _initAmorphieWorkflow(workflowName, engineConfig, queryParameters, headerParameters, isSubFlow);
    }
  }

  /// Initialize workflow using vNext (V2) engine
  Future<NeoResponse> _initvNextWorkflow(
    String workflowName,
    WorkflowEngineConfig engineConfig,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headerParameters,
    bool isSubFlow,
  ) async {
    logger.logConsole('[EnhancedWorkflowRouter] Routing initWorkflow to V2 (vNext)');
    
    try {
      final v2Response = await v2Client.initWorkflow(
        domain: engineConfig.vNextDomain!,
        workflowName: workflowName,
        key: _generateKey(),
        attributes: queryParameters ?? const {},
        headers: headerParameters,
      );
      
      // Track the instance in instance manager
      if (v2Response is NeoSuccessResponse) {
        final instanceId = v2Response.data['instanceId'] as String?;
        if (instanceId != null) {
          instanceManager.trackInstance(WorkflowInstanceEntity(
            instanceId: instanceId,
            workflowName: workflowName,
            engine: 'vnext',
            status: 'active',
            currentState: v2Response.data['currentState'] as String?,
            attributes: queryParameters ?? {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            vNextDomain: engineConfig.vNextDomain,
            metadata: {
              'engineConfig': engineConfig.toJson(),
              'isSubFlow': isSubFlow,
            },
          ));
        }
      }
      
      return _convertV2ToV1Response(v2Response, isInit: true, workflowName: workflowName);
    } catch (e, stackTrace) {
      logger.logConsole('[EnhancedWorkflowRouter] ERROR: V2 initWorkflow failed: $e\nStackTrace: $stackTrace');
      
      // Fallback to V1 if V2 fails and fallback is enabled
      if (engineConfig.config['fallbackToV1'] == true) {
        logger.logConsole('[EnhancedWorkflowRouter] Falling back to V1 due to V2 failure');
        return _initAmorphieWorkflow(workflowName, engineConfig, queryParameters, headerParameters, isSubFlow);
      }
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'vNext workflow initialization failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Initialize workflow using amorphie (V1) engine
  Future<NeoResponse> _initAmorphieWorkflow(
    String workflowName,
    WorkflowEngineConfig engineConfig,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headerParameters,
    bool isSubFlow,
  ) async {
    logger.logConsole('[EnhancedWorkflowRouter] Routing initWorkflow to V1 (amorphie)');
    
    try {
      final response = await v1Manager.initWorkflow(
        workflowName: workflowName,
        queryParameters: queryParameters,
        headerParameters: headerParameters,
        isSubFlow: isSubFlow,
      );
      
      // Track the instance in instance manager
      if (response is NeoSuccessResponse) {
        final instanceId = isSubFlow ? v1Manager.subFlowInstanceId : v1Manager.instanceId;
        
        instanceManager.trackInstance(WorkflowInstanceEntity(
          instanceId: instanceId,
          workflowName: workflowName,
          engine: 'amorphie',
          status: 'active',
          currentState: response.data['state'] as String?,
          attributes: queryParameters ?? {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          metadata: {
            'engineConfig': engineConfig.toJson(),
            'isSubFlow': isSubFlow,
          },
        ));
      }
      
      return response;
    } catch (e, stackTrace) {
      logger.logConsole('[EnhancedWorkflowRouter] ERROR: V1 initWorkflow failed: $e\nStackTrace: $stackTrace');
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'amorphie workflow initialization failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Post transition - routes to V1 or V2 based on instanceId and configuration
  Future<NeoResponse> postTransition({
    required String transitionName,
    required Map<String, dynamic> body,
    Map<String, String>? headerParameters,
    bool isSubFlow = false,
  }) async {
    logger.logConsole('[EnhancedWorkflowRouter] postTransition called for: $transitionName');

    // Try to get instanceId from body or current managers
    final instanceId = body['instanceId'] as String? ?? 
                      (isSubFlow ? v1Manager.subFlowInstanceId : v1Manager.instanceId);
    
    if (instanceId == null || instanceId.isEmpty) {
      logger.logConsole('[EnhancedWorkflowRouter] ERROR: No instanceId available for transition');
      return NeoErrorResponse(
        const NeoError(
          responseCode: 400,
          error: NeoErrorDetail(description: 'No instanceId available for transition'),
        ),
        statusCode: 400,
        headers: {},
      );
    }

    // Get instance information from instance manager
    final instance = instanceManager.getInstance(instanceId);
    if (instance == null) {
      logger.logConsole('[EnhancedWorkflowRouter] WARNING: Instance not found in manager, determining engine from managers');
      // Fallback to V1 if instance not tracked
      return _postTransitionV1(transitionName, body, headerParameters, isSubFlow);
    }

    // Route based on instance engine
    if (instance.engine == 'vnext') {
      return _postTransitionV2(transitionName, body, headerParameters, instance);
    } else {
      return _postTransitionV1(transitionName, body, headerParameters, isSubFlow);
    }
  }

  /// Post transition using vNext (V2) engine
  Future<NeoResponse> _postTransitionV2(
    String transitionName,
    Map<String, dynamic> body,
    Map<String, String>? headerParameters,
    WorkflowInstanceEntity instance,
  ) async {
    logger.logConsole('[EnhancedWorkflowRouter] Routing postTransition to V2 (vNext)');
    
    try {
      final v2Response = await v2Client.postTransition(
        domain: instance.vNextDomain!,
        workflowName: instance.workflowName,
        instanceId: instance.instanceId,
        transitionKey: transitionName,
        data: body,
        headers: headerParameters,
      );
      
      // Update instance in manager
      if (v2Response is NeoSuccessResponse) {
        instanceManager.updateInstanceOnEvent(
          instance.instanceId,
          newStatus: v2Response.data['status'] as String?,
          newState: v2Response.data['currentState'] as String?,
          additionalAttributes: body,
          additionalMetadata: {
            'lastTransition': transitionName,
            'lastTransitionAt': DateTime.now().toIso8601String(),
          },
        );
      }
      
      return _convertV2ToV1Response(v2Response, transitionName: transitionName);
    } catch (e, stackTrace) {
      logger.logConsole('[EnhancedWorkflowRouter] ERROR: V2 postTransition failed: $e\nStackTrace: $stackTrace');
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'vNext transition failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Post transition using amorphie (V1) engine
  Future<NeoResponse> _postTransitionV1(
    String transitionName,
    Map<String, dynamic> body,
    Map<String, String>? headerParameters,
    bool isSubFlow,
  ) async {
    logger.logConsole('[EnhancedWorkflowRouter] Routing postTransition to V1 (amorphie)');
    
    try {
      final response = await v1Manager.postTransition(
        transitionName: transitionName,
        body: body,
        headerParameters: headerParameters,
        isSubFlow: isSubFlow,
      );
      
      // Update instance in manager
      if (response is NeoSuccessResponse) {
        final instanceId = isSubFlow ? v1Manager.subFlowInstanceId : v1Manager.instanceId;
        instanceManager.updateInstanceOnEvent(
          instanceId,
          newStatus: response.data['status'] as String?,
          newState: response.data['state'] as String?,
          additionalAttributes: body,
          additionalMetadata: {
            'lastTransition': transitionName,
            'lastTransitionAt': DateTime.now().toIso8601String(),
          },
        );
      }
      
      return response;
    } catch (e, stackTrace) {
      logger.logConsole('[EnhancedWorkflowRouter] ERROR: V1 postTransition failed: $e\nStackTrace: $stackTrace');
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'amorphie transition failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Get available transitions - routes to V1 or V2 based on instance
  Future<NeoResponse> getAvailableTransitions({String? instanceId}) async {
    logger.logConsole('[EnhancedWorkflowRouter] getAvailableTransitions called');

    final targetInstanceId = instanceId ?? v1Manager.instanceId;
    if (targetInstanceId == null || targetInstanceId.isEmpty) {
      logger.logConsole('[EnhancedWorkflowRouter] ERROR: No instanceId available for transitions');
      return const NeoErrorResponse(
        NeoError(
          responseCode: 400,
          error: NeoErrorDetail(description: 'No instanceId available for transitions'),
        ),
        statusCode: 400,
        headers: {},
      );
    }

    // Get instance information to determine engine
    final instance = instanceManager.getInstance(targetInstanceId);
    
    if (instance?.engine == 'vnext' && instance?.vNextDomain != null) {
      logger.logConsole('[EnhancedWorkflowRouter] Routing getAvailableTransitions to V2 (vNext)');
      
      final v2Response = await v2Client.getAvailableTransitions(
        domain: instance!.vNextDomain!,
        workflowName: instance.workflowName,
        instanceId: targetInstanceId,
      );
      return _convertV2ToV1Response(v2Response);
    } else {
      logger.logConsole('[EnhancedWorkflowRouter] Routing getAvailableTransitions to V1 (amorphie)');
      return v1Manager.getAvailableTransitions(instanceId: instanceId);
    }
  }

  /// Convert V2 response format to V1 format for backward compatibility
  NeoResponse _convertV2ToV1Response(
    NeoResponse v2Response, {
    bool isInit = false,
    String? workflowName,
    String? transitionName,
  }) {
    logger.logConsole('[WorkflowRouter] Converting V2 response to V1 format');

    if (v2Response is NeoErrorResponse) {
      logger.logConsole('[WorkflowRouter] V2 response is error, passing through');
      return v2Response;
    }

    if (v2Response is NeoSuccessResponse) {
      final v2Data = v2Response.data as Map<String, dynamic>?;
      if (v2Data == null) {
        logger.logConsole('[WorkflowRouter] V2 response data is null');
        return v2Response;
      }

      // Convert V2 response to V1 format according to contract
      final v1Data = <String, dynamic>{};

      // Core V1 fields from V2 response
      if (v2Data.containsKey('instanceId')) {
        v1Data['instanceId'] = v2Data['instanceId'];
        // Store for future use
        _storeInstanceId(v2Data['instanceId'] as String);
      }

      if (v2Data.containsKey('currentState')) {
        v1Data['state'] = v2Data['currentState'];
      }

      // Add V1-specific fields for compatibility
      if (isInit && workflowName != null) {
        v1Data['init-page-name'] = v2Data['currentState'] ?? workflowName;
      }

      v1Data['navigation'] = 'push';

      // Handle view/page information
      if (v2Data.containsKey('view')) {
        v1Data['view-source: page'] = v2Data['view'];
      } else if (v2Data.containsKey('currentState')) {
        v1Data['view-source: page'] = v2Data['currentState'];
      }

      // Handle transitions
      if (v2Data.containsKey('availableTransitions')) {
        final transitions = v2Data['availableTransitions'] as List?;
        if (transitions != null) {
          v1Data['transition'] = transitions.map((t) => {'transition': t}).toList();
        }
      } else if (transitionName != null) {
        v1Data['transition'] = [{'transition': transitionName}];
      }

      // Pass through additional data
      if (v2Data.containsKey('additionalData')) {
        v1Data['additionalData'] = v2Data['additionalData'];
      }

      // Pass through any other relevant fields
      v2Data.forEach((key, value) {
        if (!v1Data.containsKey(key) && 
            !['currentState', 'view', 'availableTransitions'].contains(key)) {
          v1Data[key] = value;
        }
      });

      logger.logConsole('[WorkflowRouter] V2 to V1 conversion completed: $v1Data');
      return NeoSuccessResponse(v1Data, statusCode: 200, headers: {});
    }

    logger.logConsole('[WorkflowRouter] Unknown V2 response type, passing through');
    return v2Response;
  }


  String _generateKey() {
    // Minimal unique key for vNext start. In real impl, use a stronger ID.
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Store instance ID for future use (simplified for minimal implementation)
  void _storeInstanceId(String instanceId) {
    // For now, set it in V1 manager to maintain compatibility
    v1Manager.setInstanceId(instanceId);
  }

  // Instance management methods

  /// Get all active workflow instances
  List<WorkflowInstanceEntity> getAllActiveInstances() {
    return instanceManager.getActiveWorkflows();
  }

  /// Get instances for a specific workflow name
  List<WorkflowInstanceEntity> getInstancesByWorkflow(String workflowName) {
    return instanceManager.getInstancesByWorkflow(workflowName);
  }

  /// Get instances by engine type
  List<WorkflowInstanceEntity> getInstancesByEngine(String engine) {
    return instanceManager.getWorkflowsByEngine(engine);
  }

  /// Search instances with filters
  List<WorkflowInstanceEntity> searchInstances({
    String? workflowName,
    String? status,
    String? engine,
    String? vNextDomain,
    Map<String, dynamic>? attributeFilters,
  }) {
    return instanceManager.searchInstances(
      workflowName: workflowName,
      status: status,
      engine: engine,
      vNextDomain: vNextDomain,
      attributeFilters: attributeFilters,
    );
  }

  /// Terminate a specific workflow instance
  void terminateInstance(String instanceId, {String? reason}) {
    instanceManager.terminateInstance(instanceId, reason: reason);
  }

  /// Get workflow instance statistics
  Map<String, int> getInstanceStats() {
    return instanceManager.getInstanceStats();
  }

  /// Get comprehensive router and instance manager statistics
  Map<String, dynamic> getRouterStats() {
    final managerStats = instanceManager.getManagerStats();
    final configSummary = httpClientConfig.getWorkflowConfigSummary();
    
    return {
      'instanceManager': managerStats,
      'workflowConfigs': configSummary,
      'engineCapabilities': {
        'hasVNextWorkflows': httpClientConfig.hasVNextWorkflows,
        'vNextWorkflows': httpClientConfig.getWorkflowsForEngine('vnext'),
        'amorphieWorkflows': httpClientConfig.getWorkflowsForEngine('amorphie'),
      },
      'configValidation': httpClientConfig.validateWorkflowConfigs(),
    };
  }

  /// Listen to workflow instance events
  Stream<WorkflowInstanceEvent> get instanceEventStream => instanceManager.eventStream;

  /// Check if router has vNext capabilities
  bool get hasVNextCapabilities => httpClientConfig.hasVNextWorkflows;

  /// Get workflow configuration for a specific workflow
  WorkflowEngineConfig getWorkflowConfig(String workflowName) {
    return _getConfigForWorkflow(workflowName);
  }
}