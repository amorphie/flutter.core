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
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/http_client_config.dart';
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_polling_config.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_client.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_message_handler.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_message_handler_factory.dart';
import 'package:neo_core/core/workflow_form/workflow_engine_config.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';
import 'package:neo_core/core/workflow_form/workflow_ui_events.dart';

// WorkflowRouterConfig removed - configuration is now handled through HttpClientConfig
// and WorkflowEngineConfig for individual workflows

/// Router that directs workflow operations to V1 or V2 implementations
/// with configuration-driven engine selection and multi-instance support
class WorkflowRouter {
  final NeoWorkflowManager v1Manager;
  final VNextWorkflowClient vNextClient;
  final NeoLogger logger;
  final HttpClientConfig httpClientConfig;
  final WorkflowInstanceManager instanceManager;
  final NeoNetworkManager networkManager;
  
  // vNext message handler factory for automatic updates
  late final VNextWorkflowMessageHandlerFactory _messageHandlerFactory;
  VNextWorkflowMessageHandler? _messageHandler;

  WorkflowRouter({
    required this.v1Manager,
    required this.vNextClient,
    required this.logger,
    required this.httpClientConfig,
    required this.instanceManager,
    required this.networkManager,
  }) {
    // Initialize the message handler factory
    _messageHandlerFactory = VNextWorkflowMessageHandlerFactory(
      networkManager: networkManager,
      instanceManager: instanceManager,
      logger: logger,
    );
    
    logger.logConsole('[WorkflowRouter] Router initialized with vNext message handler support');
  }

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
    
    logger.logConsole('[WorkflowRouter] initWorkflow called for: $workflowName, engine: ${engineConfig.engine}, valid: ${engineConfig.isValid}');

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
    logger.logConsole('[WorkflowRouter] Routing initWorkflow to V2 (vNext)${engineConfig.version != null ? " with version: ${engineConfig.version}" : ""}');
    logger.logConsole('[WorkflowRouter] Engine config: ${engineConfig.toJson()}');
    logger.logConsole('[WorkflowRouter] Domain: ${engineConfig.vNextDomain}');
    logger.logConsole('[WorkflowRouter] Base URL: ${engineConfig.vNextBaseUrl}');
    logger.logConsole('[WorkflowRouter] Version: ${engineConfig.version}');
    logger.logConsole('[WorkflowRouter] Query parameters: $queryParameters');
    
    try {
      final v2Response = await vNextClient.initWorkflow(
        domain: engineConfig.vNextDomain!,
        workflowName: workflowName,
        key: _generateKey(),
        attributes: queryParameters ?? const {},
        version: engineConfig.version, // Pass version from config
        headers: headerParameters,
      );
      
      // Track the instance in instance manager
      if (v2Response is NeoSuccessResponse) {
        // vNext can return either 'id' or 'instanceId'
        final instanceId = v2Response.data['instanceId'] as String? ?? v2Response.data['id'] as String?;
        logger.logConsole('[WorkflowRouter] Extracted instanceId for tracking: $instanceId');
        if (instanceId != null) {
          instanceManager.trackInstance(WorkflowInstanceEntity(
            instanceId: instanceId,
            workflowName: workflowName,
            engine: WorkflowEngine.vnext,
            status: WorkflowInstanceStatus.active,
            currentState: v2Response.data['currentState'] as String?,
            attributes: queryParameters ?? {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            domain: engineConfig.vNextDomain,
            metadata: {
              'engineConfig': engineConfig.toJson(),
              'version': engineConfig.version, // Store version in metadata
              'isSubFlow': isSubFlow,
            },
          ));
          
          // Start automatic polling for this instance
          await _startPollingForInstance(instanceId, workflowName, engineConfig);
        }
      }
      
      return _convertV2ToV1Response(v2Response, isInit: true, workflowName: workflowName);
    } catch (e, stackTrace) {
      logger.logConsole('[WorkflowRouter] ERROR: V2 initWorkflow failed: $e\nStackTrace: $stackTrace');
      
      // Fallback to V1 if V2 fails and fallback is enabled
      if (engineConfig.config['fallbackToV1'] == true) {
        logger.logConsole('[WorkflowRouter] Falling back to V1 due to V2 failure');
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
    logger.logConsole('[WorkflowRouter] Routing initWorkflow to V1 (amorphie)');
    
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
          engine: WorkflowEngine.amorphie,
          status: WorkflowInstanceStatus.active,
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
      logger.logConsole('[WorkflowRouter] ERROR: V1 initWorkflow failed: $e\nStackTrace: $stackTrace');
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
    logger.logConsole('[WorkflowRouter] postTransition called for: $transitionName with body: $body');

    // Try to get instanceId from body or current managers
    final instanceId = body['instanceId'] as String? ?? 
                      (isSubFlow ? v1Manager.subFlowInstanceId : v1Manager.instanceId);
    
    logger.logConsole('[WorkflowRouter] Using instanceId: $instanceId (isSubFlow: $isSubFlow)');
    
    if (instanceId.isEmpty) {
      logger.logConsole('[WorkflowRouter] ERROR: No instanceId available for transition');
      return const NeoErrorResponse(
        NeoError(
          error: NeoErrorDetail(description: 'No instanceId available for transition'),
        ),
        statusCode: 400,
        headers: {},
      );
    }

    // Get instance information from instance manager
    final instance = instanceManager.getInstance(instanceId);
    if (instance == null) {
      logger.logConsole('[WorkflowRouter] WARNING: Instance not found in manager, using V1 fallback');
      // Fallback to V1 if instance not tracked
      return _postTransitionV1(transitionName, body, headerParameters, isSubFlow);
    }

    logger.logConsole('[WorkflowRouter] Found instance - Engine: ${instance.engine}, Domain: ${instance.domain}');

    // Route based on instance engine
    if (instance.engine == WorkflowEngine.vnext) {
      logger.logConsole('[WorkflowRouter] Routing to V2 (vNext) engine');
      return _postTransitionV2(transitionName, body, headerParameters, instance);
    } else {
      logger.logConsole('[WorkflowRouter] Routing to V1 (amorphie) engine');
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
    // Extract version from instance metadata
    final version = instance.metadata?['version'] as String?;
    logger.logConsole('[WorkflowRouter] Routing postTransition to V2 (vNext)${version != null ? " with version: $version" : ""}');
    
    try {
      // Remove instanceId from body for vNext client (it goes in URL path)
      final cleanBody = Map<String, dynamic>.from(body);
      final removedInstanceId = cleanBody.remove('instanceId');
      
      logger.logConsole('[WorkflowRouter] Removed instanceId from body: $removedInstanceId');
      logger.logConsole('[WorkflowRouter] Clean body for HTTP request: $cleanBody');
      
      final v2Response = await vNextClient.postTransition(
        domain: instance.domain!,
        workflowName: instance.workflowName,
        instanceId: instance.instanceId,
        transitionKey: transitionName,
        data: cleanBody,
        version: version, // Pass version from metadata
        headers: headerParameters,
      );
      
      // Update instance in manager
      if (v2Response is NeoSuccessResponse) {
        instanceManager.updateInstanceOnEvent(
          instance.instanceId,
          newStatus: _parseWorkflowStatus(v2Response.data['status'] as String?),
          newState: v2Response.data['currentState'] as String?,
          additionalAttributes: body,
          additionalMetadata: {
            'lastTransition': transitionName,
            'lastTransitionAt': DateTime.now().toIso8601String(),
          },
        );
        
        // Ensure polling is active after transition (resume if stopped)
        final engineConfig = _getConfigForWorkflow(instance.workflowName);
        await _ensurePollingActive(instance.instanceId, instance.workflowName, engineConfig);
      }
      
      return _convertV2ToV1Response(v2Response, transitionName: transitionName);
    } catch (e, stackTrace) {
      logger.logConsole('[WorkflowRouter] ERROR: V2 postTransition failed: $e\nStackTrace: $stackTrace');
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
    logger.logConsole('[WorkflowRouter] Routing postTransition to V1 (amorphie)');
    
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
          newStatus: _parseWorkflowStatus(response.data['status'] as String?),
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
      logger.logConsole('[WorkflowRouter] ERROR: V1 postTransition failed: $e\nStackTrace: $stackTrace');
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
    logger.logConsole('[WorkflowRouter] getAvailableTransitions called');

    final targetInstanceId = instanceId ?? v1Manager.instanceId;
    if (targetInstanceId.isEmpty) {
      logger.logConsole('[WorkflowRouter] ERROR: No instanceId available for transitions');
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
    
    if (instance?.engine == WorkflowEngine.vnext && instance?.domain != null) {
      // Extract version from instance metadata
      final version = instance?.metadata?['version'] as String?;
      logger.logConsole('[WorkflowRouter] Routing getAvailableTransitions to V2 (vNext)${version != null ? " with version: $version" : ""}');
      
      final v2Response = await vNextClient.getAvailableTransitions(
        domain: instance!.domain!,
        workflowName: instance.workflowName,
        instanceId: targetInstanceId,
        version: version, // Pass version from metadata
      );
      return _convertV2ToV1Response(v2Response);
    } else {
      logger.logConsole('[WorkflowRouter] Routing getAvailableTransitions to V1 (amorphie)');
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
      logger.logConsole('[WorkflowRouter] ❌ V2 response is ERROR');
      logger.logConsole('[WorkflowRouter] Status code: ${v2Response.statusCode}');
      logger.logConsole('[WorkflowRouter] Error response code: ${v2Response.error.responseCode}');
      logger.logConsole('[WorkflowRouter] Error detail: ${v2Response.error.error?.description}');
      logger.logConsole('[WorkflowRouter] Error title: ${v2Response.error.error?.title}');
      logger.logConsole('[WorkflowRouter] Full error: ${v2Response.error}');
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
      // vNext can return either 'id' or 'instanceId'
      final instanceId = v2Data['instanceId'] as String? ?? v2Data['id'] as String?;
      if (instanceId != null) {
        v1Data['instanceId'] = instanceId;
        // Store for future use
        _storeInstanceId(instanceId);
      }

      // vNext can return 'currentState' or 'state'
      final state = v2Data['currentState'] as String? ?? v2Data['state'] as String?;
      if (state != null) {
        v1Data['state'] = state;
      }

      // Add V1-specific fields for compatibility
      if (isInit && workflowName != null) {
        v1Data['init-page-name'] = state ?? workflowName;
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
  List<WorkflowInstanceEntity> getInstancesByEngine(WorkflowEngine engine) {
    return instanceManager.getWorkflowsByEngine(engine);
  }

  /// Search instances with filters
  List<WorkflowInstanceEntity> searchInstances({
    String? workflowName,
    WorkflowInstanceStatus? status,
    WorkflowEngine? engine,
    String? domain,
    Map<String, dynamic>? attributeFilters,
  }) {
    return instanceManager.searchInstances(
      workflowName: workflowName,
      status: status,
      engine: engine,
      domain: domain,
      attributeFilters: attributeFilters,
    );
  }

  /// Terminate a specific workflow instance
  void terminateInstance(String instanceId, {String? reason}) {
    logger.logConsole('[WorkflowRouter] Terminating instance: $instanceId (reason: ${reason ?? "not specified"})');
    
    // Get instance to check engine type
    final instance = instanceManager.getInstance(instanceId);
    
    // Terminate in instance manager
    instanceManager.terminateInstance(instanceId, reason: reason);
    
    // Stop polling if vNext instance
    if (instance?.engine == WorkflowEngine.vnext) {
      _stopPollingForInstance(instanceId);
    }
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

  /// Get the current instanceId for the specified flow type
  /// This handles both vNext (server-provided) and amorphie (client-generated) instanceIds
  String? getInstanceId({bool isSubFlow = false}) {
    // For amorphie workflows, return the locally generated instanceId
    return isSubFlow ? v1Manager.subFlowInstanceId : v1Manager.instanceId;
  }

  /// Get workflow configuration for a specific workflow
  WorkflowEngineConfig getWorkflowConfig(String workflowName) {
    return _getConfigForWorkflow(workflowName);
  }

  /// Get the message handler's UI event stream (for bridge integration)
  Stream<WorkflowUIEvent>? get vNextUIEventStream => _messageHandler?.uiEvents;

  /// Dispose router and cleanup resources
  Future<void> dispose() async {
    logger.logConsole('[WorkflowRouter] Disposing router and cleaning up resources');
    
    // Stop all polling and cleanup message handler
    await _messageHandlerFactory.dispose();
    _messageHandler = null;
    
    // Cleanup instance manager
    instanceManager.dispose();
    
    logger.logConsole('[WorkflowRouter] Router disposed successfully');
  }

  // Helper methods
  
  /// Start polling for a vNext workflow instance
  Future<void> _startPollingForInstance(
    String instanceId,
    String workflowName,
    WorkflowEngineConfig engineConfig,
  ) async {
    try {
      logger.logConsole('[WorkflowRouter] Starting polling for instance: $instanceId');
      
      // Get or create message handler
      _messageHandler ??= _messageHandlerFactory.getOrCreateHandler();
      
      // Extract polling config from engine config
      final pollingConfig = _extractPollingConfig(engineConfig);
      
      // Start handling messages for this instance
      await _messageHandler!.startHandling(
        instanceId,
        workflowName: workflowName,
        config: pollingConfig,
      );
      
      logger.logConsole('[WorkflowRouter] Polling started successfully for instance: $instanceId');
    } catch (e, stackTrace) {
      logger.logError('[WorkflowRouter] Failed to start polling for instance $instanceId: $e\nStackTrace: $stackTrace');
      // Don't rethrow - polling failure shouldn't break the workflow initialization
    }
  }

  /// Ensure polling is active for an instance (resume if needed)
  Future<void> _ensurePollingActive(
    String instanceId,
    String workflowName,
    WorkflowEngineConfig engineConfig,
  ) async {
    try {
      if (_messageHandler == null) {
        // Handler not initialized, start polling
        await _startPollingForInstance(instanceId, workflowName, engineConfig);
        return;
      }
      
      // Check if instance is already being polled
      final activeInstances = _messageHandler!.getActiveInstances();
      if (!activeInstances.contains(instanceId)) {
        logger.logConsole('[WorkflowRouter] Instance $instanceId not being polled, starting polling');
        await _startPollingForInstance(instanceId, workflowName, engineConfig);
      } else {
        logger.logConsole('[WorkflowRouter] Instance $instanceId already being polled');
      }
    } catch (e, stackTrace) {
      logger.logError('[WorkflowRouter] Failed to ensure polling for instance $instanceId: $e\nStackTrace: $stackTrace');
    }
  }

  /// Stop polling for a specific instance
  Future<void> _stopPollingForInstance(String instanceId) async {
    try {
      if (_messageHandler != null) {
        logger.logConsole('[WorkflowRouter] Stopping polling for instance: $instanceId');
        await _messageHandler!.stopHandling(instanceId);
        logger.logConsole('[WorkflowRouter] Polling stopped for instance: $instanceId');
      }
    } catch (e, stackTrace) {
      logger.logError('[WorkflowRouter] Failed to stop polling for instance $instanceId: $e\nStackTrace: $stackTrace');
    }
  }

  /// Extract polling configuration from workflow engine config
  VNextPollingConfig _extractPollingConfig(WorkflowEngineConfig engineConfig) {
    final config = engineConfig.config;
    
    // Extract polling parameters from config or use defaults
    final pollingIntervalSeconds = config['pollingIntervalSeconds'] as int? ?? 5;
    final pollingDurationSeconds = config['pollingDurationSeconds'] as int? ?? 60;
    final maxConsecutiveErrors = config['maxConsecutiveErrors'] as int? ?? 5;
    final requestTimeoutSeconds = config['requestTimeoutSeconds'] as int? ?? 30;
    
    return VNextPollingConfig(
      interval: Duration(seconds: pollingIntervalSeconds),
      duration: Duration(seconds: pollingDurationSeconds),
      maxConsecutiveErrors: maxConsecutiveErrors,
      requestTimeout: Duration(seconds: requestTimeoutSeconds),
    );
  }

  /// Check if polling is active for a specific instance
  bool isPollingActive(String instanceId) {
    if (_messageHandler == null) return false;
    return _messageHandler!.getActiveInstances().contains(instanceId);
  }

  /// Get all active polling instance IDs
  List<String> getActivePollingInstances() {
    if (_messageHandler == null) return [];
    return _messageHandler!.getActiveInstances();
  }

  /// Parse string status to WorkflowInstanceStatus enum
  WorkflowInstanceStatus? _parseWorkflowStatus(String? statusString) {
    if (statusString == null) return null;
    
    switch (statusString.toLowerCase()) {
      case 'active':
        return WorkflowInstanceStatus.active;
      case 'completed':
        return WorkflowInstanceStatus.completed;
      case 'terminated':
        return WorkflowInstanceStatus.terminated;
      case 'failed':
        return WorkflowInstanceStatus.failed;
      case 'pending':
        return WorkflowInstanceStatus.pending;
      default:
        return WorkflowInstanceStatus.active; // Default fallback
    }
  }

  /// Query workflow instances with enhanced filtering - routes to appropriate engine
  Future<NeoResponse> queryWorkflowInstances({
    required String workflowName,
    String? domain,
    Map<String, String>? attributeFilters,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
  }) async {
    final engineConfig = _getConfigForWorkflow(workflowName);
    
    logger.logConsole('[WorkflowRouter] queryWorkflowInstances called for: $workflowName, engine: ${engineConfig.engine}');

    if (engineConfig.isVNext && engineConfig.isValid) {
      return _queryVNextInstances(workflowName, engineConfig, domain, attributeFilters, page, pageSize, sortBy, sortOrder);
    } else {
      // For amorphie, we'll fallback to basic instance search
      return _queryAmorphieInstances(workflowName, attributeFilters);
    }
  }

  /// Query instances using vNext engine with advanced filtering
  Future<NeoResponse> _queryVNextInstances(
    String workflowName,
    WorkflowEngineConfig engineConfig,
    String? domain,
    Map<String, String>? attributeFilters,
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder,
  ) async {
    logger.logConsole('[WorkflowRouter] Routing queryInstances to V2 (vNext)');
    
    try {
      final effectiveDomain = domain ?? engineConfig.vNextDomain!;
      
      return await vNextClient.listWorkflowInstances(
        domain: effectiveDomain,
        workflowName: workflowName,
        attributeFilters: attributeFilters,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e, stackTrace) {
      logger.logConsole('[WorkflowRouter] ERROR: V2 queryInstances failed: $e\nStackTrace: $stackTrace');
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'vNext query instances failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Query instances using amorphie engine (limited functionality)
  Future<NeoResponse> _queryAmorphieInstances(
    String workflowName,
    Map<String, String>? attributeFilters,
  ) async {
    logger.logConsole('[WorkflowRouter] Routing queryInstances to V1 (amorphie) - limited filtering');
    
    try {
      // For amorphie, we'll use the existing instance manager to return tracked instances
      final instances = instanceManager.searchInstances(workflowName: workflowName);
      
      // Convert to API response format
      final responseData = {
        'data': instances.map((instance) => {
          'instanceId': instance.instanceId,
          'workflowName': instance.workflowName,
          'status': instance.status.toString(),
          'currentState': instance.currentState,
          'attributes': instance.attributes,
          'createdAt': instance.createdAt.toIso8601String(),
          'updatedAt': instance.updatedAt.toIso8601String(),
          'engine': instance.engine.toString(),
        }).toList(),
        'pagination': {
          'totalCount': instances.length,
          'page': 1,
          'pageSize': instances.length,
        }
      };
      
      return NeoSuccessResponse(responseData, statusCode: 200, headers: {});
    } catch (e, stackTrace) {
      logger.logConsole('[WorkflowRouter] ERROR: V1 queryInstances failed: $e\nStackTrace: $stackTrace');
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'amorphie query instances failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Get workflow instance history - routes to appropriate engine
  Future<NeoResponse> getInstanceHistory({
    required String instanceId,
    required String workflowName,
    required String domain,
  }) async {
    final engineConfig = _getConfigForWorkflow(workflowName);
    
    logger.logConsole('[WorkflowRouter] getInstanceHistory called for: $instanceId, engine: ${engineConfig.engine}');

    if (engineConfig.isVNext && engineConfig.isValid) {
      return _getVNextInstanceHistory(instanceId, workflowName, domain, engineConfig);
    } else {
      return _getAmorphieInstanceHistory(instanceId);
    }
  }

  /// Get instance history using vNext engine
  Future<NeoResponse> _getVNextInstanceHistory(
    String instanceId,
    String workflowName,
    String domain,
    WorkflowEngineConfig engineConfig,
  ) async {
    logger.logConsole('[WorkflowRouter] Routing getInstanceHistory to V2 (vNext)');
    
    try {
      return await vNextClient.getInstanceHistory(
        domain: domain,
        workflowName: workflowName,
        instanceId: instanceId,
      );
    } catch (e, stackTrace) {
      logger.logConsole('[WorkflowRouter] ERROR: V2 getInstanceHistory failed: $e\nStackTrace: $stackTrace');
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'vNext get instance history failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Get instance history using amorphie engine (limited functionality)
  Future<NeoResponse> _getAmorphieInstanceHistory(String instanceId) async {
    logger.logConsole('[WorkflowRouter] Routing getInstanceHistory to V1 (amorphie) - limited functionality');
    
    try {
      // For amorphie, return basic instance information as "history"
      final instances = instanceManager.getActiveWorkflows();
      final instance = instances.where((i) => i.instanceId == instanceId).firstOrNull;
      
      if (instance != null) {
        final historyData = [
          {
            'timestamp': instance.createdAt.toIso8601String(),
            'event': 'instance_created',
            'state': 'initial',
            'data': instance.attributes,
          },
          if (instance.updatedAt != instance.createdAt) {
            'timestamp': instance.updatedAt.toIso8601String(),
            'event': 'instance_updated',
            'state': instance.currentState,
            'data': {'status': instance.status.toString()},
          },
        ];
        
        final responseData = {
          'data': historyData,
          'instanceId': instanceId,
        };
        
        return NeoSuccessResponse(responseData, statusCode: 200, headers: {});
      } else {
        return NeoErrorResponse(
          NeoError(
            responseCode: 404,
            error: NeoErrorDetail(description: 'Instance not found: $instanceId'),
          ),
          statusCode: 404,
          headers: {},
        );
      }
    } catch (e, stackTrace) {
      logger.logConsole('[WorkflowRouter] ERROR: V1 getInstanceHistory failed: $e\nStackTrace: $stackTrace');
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'amorphie get instance history failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Get system health - routes to appropriate engine
  Future<NeoResponse> getSystemHealth() async {
    logger.logConsole('[WorkflowRouter] getSystemHealth called');

    // Try to get health from vNext first (if configured), fallback to generic health
    final configs = httpClientConfig.workflowConfigs;
    final vNextConfig = configs.values.where((config) => config.isVNext && config.isValid).firstOrNull;
    
    if (vNextConfig != null) {
      return _getVNextSystemHealth();
    } else {
      return _getGenericSystemHealth();
    }
  }

  /// Get system health from vNext engine
  Future<NeoResponse> _getVNextSystemHealth() async {
    logger.logConsole('[WorkflowRouter] Routing getSystemHealth to V2 (vNext)');
    
    try {
      return await vNextClient.getSystemHealth();
    } catch (e, stackTrace) {
      logger.logConsole('[WorkflowRouter] ERROR: V2 getSystemHealth failed: $e\nStackTrace: $stackTrace');
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'vNext system health check failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Get generic system health (when vNext is not available)
  Future<NeoResponse> _getGenericSystemHealth() async {
    logger.logConsole('[WorkflowRouter] Providing generic system health');
    
    try {
      final activeInstances = instanceManager.getActiveWorkflows();
      final healthData = {
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
        'system': 'flutter-workflow-core',
        'metrics': {
          'activeInstances': activeInstances.length,
          'engines': {
            'amorphie': activeInstances.where((i) => i.engine == WorkflowEngine.amorphie).length,
            'vnext': activeInstances.where((i) => i.engine == WorkflowEngine.vnext).length,
          }
        }
      };
      
      return NeoSuccessResponse(healthData, statusCode: 200, headers: {});
    } catch (e, stackTrace) {
      logger.logConsole('[WorkflowRouter] ERROR: Generic getSystemHealth failed: $e\nStackTrace: $stackTrace');
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'System health check failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Get system metrics - routes to appropriate engine
  Future<NeoResponse> getSystemMetrics() async {
    logger.logConsole('[WorkflowRouter] getSystemMetrics called');

    // Try to get metrics from vNext first (if configured), fallback to generic metrics
    final configs = httpClientConfig.workflowConfigs;
    final vNextConfig = configs.values.where((config) => config.isVNext && config.isValid).firstOrNull;
    
    if (vNextConfig != null) {
      return _getVNextSystemMetrics();
    } else {
      return _getGenericSystemMetrics();
    }
  }

  /// Get system metrics from vNext engine
  Future<NeoResponse> _getVNextSystemMetrics() async {
    logger.logConsole('[WorkflowRouter] Routing getSystemMetrics to V2 (vNext)');
    
    try {
      return await vNextClient.getSystemMetrics();
    } catch (e, stackTrace) {
      logger.logConsole('[WorkflowRouter] ERROR: V2 getSystemMetrics failed: $e\nStackTrace: $stackTrace');
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'vNext system metrics failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Get generic system metrics (when vNext is not available)
  Future<NeoResponse> _getGenericSystemMetrics() async {
    logger.logConsole('[WorkflowRouter] Providing generic system metrics');
    
    try {
      final activeInstances = instanceManager.getActiveWorkflows();
      final now = DateTime.now();
      
      // Calculate basic metrics
      final instancesByEngine = <WorkflowEngine, int>{};
      final instancesByStatus = <WorkflowInstanceStatus, int>{};
      
      for (final instance in activeInstances) {
        instancesByEngine[instance.engine] = (instancesByEngine[instance.engine] ?? 0) + 1;
        instancesByStatus[instance.status] = (instancesByStatus[instance.status] ?? 0) + 1;
      }
      
      final metricsData = {
        'timestamp': now.toIso8601String(),
        'system': 'flutter-workflow-core',
        'metrics': {
          'workflow_instances_total': activeInstances.length,
          'workflow_instances_by_engine': instancesByEngine.map((k, v) => MapEntry(k.toString(), v)),
          'workflow_instances_by_status': instancesByStatus.map((k, v) => MapEntry(k.toString(), v)),
          'uptime_seconds': now.millisecondsSinceEpoch ~/ 1000, // Approximate uptime
        }
      };
      
      return NeoSuccessResponse(metricsData, statusCode: 200, headers: {});
    } catch (e, stackTrace) {
      logger.logConsole('[WorkflowRouter] ERROR: Generic getSystemMetrics failed: $e\nStackTrace: $stackTrace');
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: 'System metrics failed: $e'),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }
}