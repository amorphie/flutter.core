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
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_client.dart';

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

/// Router that directs workflow operations to V1 or V2 implementations
/// Maintains backward compatibility while enabling gradual vNext adoption
class WorkflowRouter {
  final NeoWorkflowManager v1Manager;
  final VNextWorkflowClient v2Client;
  final NeoLogger logger;
  final WorkflowRouterConfig config;

  WorkflowRouter({
    required this.v1Manager,
    required this.v2Client,
    required this.logger,
    required this.config,
  });

  /// Initialize workflow - routes to V1 or V2 based on configuration
  Future<NeoResponse> initWorkflow({
    required String workflowName,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headerParameters,
    bool isSubFlow = false,
  }) async {
    logger.logConsole('[WorkflowRouter] initWorkflow called for: $workflowName, V2 enabled: ${config.enableV2Workflows}, can use V2: ${config.canUseV2}');

    if (config.canUseV2) {
      logger.logConsole('[WorkflowRouter] Routing initWorkflow to V2 (vNext)');
      final v2Response = await v2Client.initWorkflow(
        domain: config.vNextDomain!,
        workflowName: workflowName,
        key: _generateKey(),
        attributes: queryParameters ?? const {},
        tags: const [],
        headers: headerParameters,
      );
      
      return _convertV2ToV1Response(v2Response, isInit: true, workflowName: workflowName);
    } else {
      logger.logConsole('[WorkflowRouter] Routing initWorkflow to V1 (NeoWorkflowManager)');
      return v1Manager.initWorkflow(
        workflowName: workflowName,
        queryParameters: queryParameters,
        headerParameters: headerParameters,
        isSubFlow: isSubFlow,
      );
    }
  }

  /// Post transition - routes to V1 or V2 based on configuration
  Future<NeoResponse> postTransition({
    required String transitionName,
    required Map<String, dynamic> body,
    Map<String, String>? headerParameters,
    bool isSubFlow = false,
  }) async {
    logger.logConsole('[WorkflowRouter] postTransition called for: $transitionName, V2 enabled: ${config.enableV2Workflows}, can use V2: ${config.canUseV2}');

    if (config.canUseV2) {
      logger.logConsole('[WorkflowRouter] Routing postTransition to V2 (vNext)');
      
      // Extract instanceId from body or use current instance
      final instanceId = body['instanceId'] as String? ?? _getCurrentInstanceId();
      if (instanceId == null) {
        logger.logError('[WorkflowRouter] No instanceId available for V2 transition');
        return NeoErrorResponse(
          const NeoError(
            responseCode: 400,
            error: NeoErrorDetail(description: 'No instanceId available for vNext transition'),
          ),
          statusCode: 400,
          headers: {},
        );
      }

      final v2Response = await v2Client.postTransition(
        domain: config.vNextDomain!,
        workflowName: v1Manager.getWorkflowName(),
        instanceId: instanceId,
        transitionKey: transitionName,
        data: body,
        headers: headerParameters,
      );
      
      return _convertV2ToV1Response(v2Response, transitionName: transitionName);
    } else {
      logger.logConsole('[WorkflowRouter] Routing postTransition to V1 (NeoWorkflowManager)');
      return v1Manager.postTransition(
        transitionName: transitionName,
        body: body,
        headerParameters: headerParameters,
        isSubFlow: isSubFlow,
      );
    }
  }

  /// Get available transitions - routes to V1 or V2 based on configuration
  Future<NeoResponse> getAvailableTransitions({String? instanceId}) async {
    logger.logConsole('[WorkflowRouter] getAvailableTransitions called, V2 enabled: ${config.enableV2Workflows}, can use V2: ${config.canUseV2}');

    if (config.canUseV2) {
      logger.logConsole('[WorkflowRouter] Routing getAvailableTransitions to V2 (vNext)');
      
      final targetInstanceId = instanceId ?? _getCurrentInstanceId();
      if (targetInstanceId == null) {
        logger.logError('[WorkflowRouter] No instanceId available for V2 transitions');
        return const NeoErrorResponse(
          NeoError(
            responseCode: 400,
            error: NeoErrorDetail(description: 'No instanceId available for vNext transitions'),
          ),
          statusCode: 400,
          headers: {},
        );
      }

      final v2Response = await v2Client.getAvailableTransitions(
        domain: config.vNextDomain!,
        workflowName: v1Manager.getWorkflowName(),
        instanceId: targetInstanceId,
      );
      return _convertV2ToV1Response(v2Response);
    } else {
      logger.logConsole('[WorkflowRouter] Routing getAvailableTransitions to V1 (NeoWorkflowManager)');
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

  /// Get current instance ID (simplified for minimal implementation)
  /// In a real implementation, this would maintain state properly
  String? _getCurrentInstanceId() {
    // For now, delegate to V1 manager's instance ID
    return v1Manager.instanceId;
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

  /// Check if V2 is available and properly configured
  bool get isV2Available => config.canUseV2;

  /// Get current configuration
  WorkflowRouterConfig get routerConfig => config;
}