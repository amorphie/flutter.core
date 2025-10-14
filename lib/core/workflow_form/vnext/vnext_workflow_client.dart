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
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/network/query_providers/http_query_provider.dart';

/// Client for communicating with vNext backend workflow services
/// Now uses NeoNetworkManager for unified network handling with authentication,
/// headers, security, and error handling.
class VNextWorkflowClient {
  final NeoNetworkManager networkManager;
  final NeoLogger logger;

  VNextWorkflowClient({
    required this.networkManager,
    required this.logger,
  });

  /// Initialize (start) a workflow instance in vNext backend
  Future<NeoResponse> initWorkflow({
    required String domain,
    required String workflowName,
    required String key,
    Map<String, dynamic> attributes = const {},
    List<String> tags = const [],
    String? version, // Workflow version (e.g., "1.0.0")
    Map<String, String>? headers,
  }) async {
    logger.logConsole('[VNextWorkflowClient] Starting workflow: $workflowName in domain: $domain${version != null ? " version: $version" : ""}');
    
    final requestBody = {
      'key': key,
      'attributes': attributes,
      'tags': tags,
    };

    logger.logConsole('[VNextWorkflowClient] Request body: $requestBody');
    logger.logConsole('[VNextWorkflowClient] Request headers: $headers');

    final queryParams = <String, dynamic>{};
    if (version != null) {
      queryParams['version'] = version;
    }

    logger.logConsole('[VNextWorkflowClient] Calling endpoint: vnext-init-workflow');
    logger.logConsole('[VNextWorkflowClient] Path params: {DOMAIN: $domain, WORKFLOW_NAME: $workflowName}');
    logger.logConsole('[VNextWorkflowClient] Query params: $queryParams');

    final response = await networkManager.call(
      NeoHttpCall(
        endpoint: 'vnext-init-workflow',
        pathParameters: {
          'DOMAIN': domain,
          'WORKFLOW_NAME': workflowName,
        },
        queryProviders: queryParams.isNotEmpty ? [HttpQueryProvider(queryParams)] : [],
        body: requestBody,
        headerParameters: headers ?? {},
      ),
    );

    if (response is NeoSuccessResponse) {
      logger.logConsole('[VNextWorkflowClient] ✅ SUCCESS: ${response.statusCode}');
      logger.logConsole('[VNextWorkflowClient] Response data: ${response.data}');
    } else if (response is NeoErrorResponse) {
      logger.logConsole('[VNextWorkflowClient] ❌ ERROR: ${response.statusCode}');
      logger.logConsole('[VNextWorkflowClient] Error details: ${response.error}');
      logger.logConsole('[VNextWorkflowClient] Error description: ${response.error.error?.description ?? "No description"}');
    }

    return response;
  }

  /// Make a transition on a workflow instance
  Future<NeoResponse> postTransition({
    required String domain,
    required String workflowName,
    required String instanceId,
    required String transitionKey,
    Map<String, dynamic> data = const {},
    String? version, // Workflow version (e.g., "1.0.0")
    Map<String, String>? headers,
  }) async {
    logger.logConsole('[VNextWorkflowClient] Making transition: $transitionKey for instance: $instanceId${version != null ? " version: $version" : ""}');

    final queryParams = <String, dynamic>{};
    if (version != null) {
      queryParams['version'] = version;
    }

    return networkManager.call(
      NeoHttpCall(
        endpoint: 'vnext-post-transition',
        pathParameters: {
          'DOMAIN': domain,
          'WORKFLOW_NAME': workflowName,
          'INSTANCE_ID': instanceId,
          'TRANSITION_KEY': transitionKey,
        },
        queryProviders: queryParams.isNotEmpty ? [HttpQueryProvider(queryParams)] : [],
        body: data,
        headerParameters: headers ?? {},
      ),
    );
  }

  /// Get available transitions for a workflow instance
  Future<NeoResponse> getAvailableTransitions({
    required String domain,
    required String workflowName,
    required String instanceId,
    String? version, // Workflow version (e.g., "1.0.0")
    Map<String, String>? headers,
  }) async {
    logger.logConsole('[VNextWorkflowClient] Getting available transitions for instance: $instanceId${version != null ? " version: $version" : ""}');

    final queryParams = <String, dynamic>{};
    if (version != null) {
      queryParams['version'] = version;
    }

    return networkManager.call(
      NeoHttpCall(
        endpoint: 'vnext-get-available-transitions',
        pathParameters: {
          'DOMAIN': domain,
          'WORKFLOW_NAME': workflowName,
          'INSTANCE_ID': instanceId,
        },
        queryProviders: queryParams.isNotEmpty ? [HttpQueryProvider(queryParams)] : [],
        headerParameters: headers ?? {},
      ),
    );
  }

  /// Get workflow instance details
  Future<NeoResponse> getWorkflowInstance({
    required String domain,
    required String workflowName,
    required String instanceId,
    Map<String, String>? headers,
  }) async {
    logger.logConsole('[VNextWorkflowClient] Getting workflow instance: $instanceId');

    return networkManager.call(
      NeoHttpCall(
        endpoint: 'vnext-get-workflow-instance',
        pathParameters: {
          'DOMAIN': domain,
          'WORKFLOW_NAME': workflowName,
          'INSTANCE_ID': instanceId,
        },
        headerParameters: headers ?? {},
      ),
    );
  }

  /// List all instances for a specific workflow with enhanced filtering support
  /// 
  /// Enhanced filtering supports vNext query operators:
  /// - eq (equal): attributes=status=eq:active
  /// - ne (not equal): attributes=status=ne:inactive  
  /// - gt (greater than): attributes=amount=gt:100
  /// - ge (greater equal): attributes=score=ge:80
  /// - lt (less than): attributes=count=lt:10
  /// - le (less equal): attributes=age=le:65
  /// - between: attributes=amount=between:50,200
  /// - like (contains): attributes=name=like:john
  /// - startswith: attributes=email=startswith:test
  /// - endswith: attributes=email=endswith:.com
  /// - in (value in list): attributes=status=in:active,pending
  /// - nin (not in list): attributes=type=nin:test,debug
  Future<NeoResponse> listWorkflowInstances({
    required String domain,
    required String workflowName,
    Map<String, String>? attributeFilters,
    String? filter, // Legacy filter support
    int? page,
    int? pageSize,
    String? sortBy,
    String? sortOrder, // 'asc' or 'desc'
    Map<String, String>? headers,
  }) async {
    logger.logConsole('[VNextWorkflowClient] Listing instances for workflow: $workflowName in domain: $domain');
    
    if (attributeFilters != null && attributeFilters.isNotEmpty) {
      logger.logConsole('[VNextWorkflowClient] Using enhanced attribute filters: $attributeFilters');
    }

    final queryParams = <String, dynamic>{};
    
    // Enhanced attribute filtering
    if (attributeFilters != null && attributeFilters.isNotEmpty) {
      for (final entry in attributeFilters.entries) {
        queryParams['filter'] = 'attributes=${entry.key}=${entry.value}';
        // Note: vNext supports multiple filters, but we'll add one at a time for now
        // Future enhancement could support multiple concurrent filters
        break; // For now, take the first filter
      }
    }
    
    // Legacy filter support (backward compatibility)
    if (filter != null && !queryParams.containsKey('filter')) {
      queryParams['filter'] = filter;
    }
    
    // Pagination
    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;
    
    // Sorting support
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

    return await networkManager.call(
      NeoHttpCall(
        endpoint: 'vnext-list-workflow-instances',
        pathParameters: {
          'DOMAIN': domain,
          'WORKFLOW_NAME': workflowName,
        },
        queryProviders: queryParams.isNotEmpty ? [HttpQueryProvider(queryParams)] : [],
        headerParameters: headers ?? {},
      ),
    );
  }

  /// Get workflow instance history and state transitions
  Future<NeoResponse> getInstanceHistory({
    required String domain,
    required String workflowName,
    required String instanceId,
    Map<String, String>? headers,
  }) async {
    logger.logConsole('[VNextWorkflowClient] Getting instance history for: $instanceId');

    return await networkManager.call(
      NeoHttpCall(
        endpoint: 'vnext-get-instance-history',
        pathParameters: {
          'DOMAIN': domain,
          'WORKFLOW_NAME': workflowName,
          'INSTANCE_ID': instanceId,
        },
        headerParameters: headers ?? {},
      ),
    );
  }

  /// Get system health status
  Future<NeoResponse> getSystemHealth({
    Map<String, String>? headers,
  }) async {
    logger.logConsole('[VNextWorkflowClient] Getting system health');

    return await networkManager.call(
      NeoHttpCall(
        endpoint: 'vnext-get-system-health',
        headerParameters: headers ?? {},
      ),
    );
  }

  /// Get system metrics
  Future<NeoResponse> getSystemMetrics({
    Map<String, String>? headers,
  }) async {
    logger.logConsole('[VNextWorkflowClient] Getting system metrics');

    return await networkManager.call(
      NeoHttpCall(
        endpoint: 'vnext-get-system-metrics',
        headerParameters: headers ?? {},
      ),
    );
  }

}
