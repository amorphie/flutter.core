// ignore_for_file: cascade_invocations

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
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/network/query_providers/http_query_provider.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_error_handler.dart';

class VNextWorkflowClient {
  final NeoNetworkManager networkManager;
  final NeoLogger logger;
  final VNextErrorHandler? errorHandler;

  VNextWorkflowClient({
    required this.networkManager,
    required this.logger,
    VNextErrorHandler? errorHandler,
  }) : errorHandler = errorHandler ?? VNextErrorHandler(logger: logger);

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
    logger.logConsole('[VNextWorkflowClient] ===== initWorkflow CALLED =====');
    logger.logConsole('[VNextWorkflowClient] Domain: "$domain" (isEmpty: ${domain.isEmpty})');
    logger.logConsole('[VNextWorkflowClient] WorkflowName: "$workflowName" (isEmpty: ${workflowName.isEmpty})');
    logger.logConsole('[VNextWorkflowClient] Key: "$key"');
    logger.logConsole('[VNextWorkflowClient] Version: ${version ?? "null"}');
    logger.logConsole('[VNextWorkflowClient] Attributes: $attributes');
    logger.logConsole('[VNextWorkflowClient] Tags: $tags');
    logger.logConsole('[VNextWorkflowClient] Headers: ${headers?.keys.join(", ") ?? "none"}');
    
    // Validate inputs
    if (domain.isEmpty || workflowName.isEmpty) {
      logger.logError('[VNextWorkflowClient] ❌ ERROR: Domain or WorkflowName is empty!');
      logger.logError('[VNextWorkflowClient] Domain: "$domain", WorkflowName: "$workflowName"');
      return NeoResponse.error(
        NeoError(
          responseCode: 400,
          error: NeoErrorDetail(
            title: 'Invalid Request',
            description: 'Domain or WorkflowName is empty. Domain: "$domain", WorkflowName: "$workflowName"',
          ),
        ),
        responseHeaders: {},
      );
    }
    
    logger.logConsole('[VNextWorkflowClient] Building request body...');
    final requestBody = {
      'key': key,
      'attributes': attributes,
      'tags': tags,
    };
    logger.logConsole('[VNextWorkflowClient] Request body: $requestBody');

    logger.logConsole('[VNextWorkflowClient] Building query parameters...');
    final queryParams = <String, dynamic>{};
    if (version != null && version.isNotEmpty) {
      queryParams['version'] = version;
      logger.logConsole('[VNextWorkflowClient] Added version to query params: $version');
    }
    logger.logConsole('[VNextWorkflowClient] Query params: $queryParams');

    logger.logConsole('[VNextWorkflowClient] Building NeoHttpCall...');
    final httpCall = NeoHttpCall(
      endpoint: 'vnext-init-workflow',
      pathParameters: {
        'DOMAIN': domain,
        'WORKFLOW_NAME': workflowName,
      },
      queryProviders: queryParams.isNotEmpty ? [HttpQueryProvider(queryParams)] : [],
      body: requestBody,
      headerParameters: headers ?? {},
      useHttps: false,
    );
    logger.logConsole('[VNextWorkflowClient] NeoHttpCall created: endpoint=${httpCall.endpoint}, pathParams=${httpCall.pathParameters}');

    logger.logConsole('[VNextWorkflowClient] Calling networkManager.call()...');
    try {
      final response = await networkManager.call(httpCall);
      
      logger.logConsole('[VNextWorkflowClient] Network call completed: isSuccess=${response.isSuccess}');
      
      if (response is NeoSuccessResponse) {
        logger.logConsole('[VNextWorkflowClient] ✅ Init workflow successful, statusCode: ${response.statusCode}');
        logger.logConsole('[VNextWorkflowClient] Response data keys: ${response.data.keys.join(", ")}');
      } else if (response is NeoErrorResponse) {
        logger.logError('[VNextWorkflowClient] ❌ Init workflow failed, statusCode: ${response.statusCode}');
        logger.logError('[VNextWorkflowClient] Error title: ${response.error.error.title}');
        logger.logError('[VNextWorkflowClient] Error description: ${response.error.error.description}');
        logger.logError('[VNextWorkflowClient] Error body: ${response.error.body}');
        logger.logError('[VNextWorkflowClient] Error responseCode: ${response.error.responseCode}');
      }
      
      logger.logConsole('[VNextWorkflowClient] ===== initWorkflow COMPLETE =====');
      return response;
    } catch (e, stackTrace) {
      logger.logError('[VNextWorkflowClient] ❌ Exception during initWorkflow: $e');
      logger.logError('[VNextWorkflowClient] Exception type: ${e.runtimeType}');
      logger.logError('[VNextWorkflowClient] Stack trace: $stackTrace');
      rethrow;
    }
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
    logger.logConsole('[VNextWorkflowClient] ===== postTransition CALLED =====');
    logger.logConsole('[VNextWorkflowClient] Domain: "$domain" (isEmpty: ${domain.isEmpty})');
    logger.logConsole('[VNextWorkflowClient] WorkflowName: "$workflowName" (isEmpty: ${workflowName.isEmpty})');
    logger.logConsole('[VNextWorkflowClient] InstanceId: $instanceId');
    logger.logConsole('[VNextWorkflowClient] TransitionKey: $transitionKey');
    logger.logConsole('[VNextWorkflowClient] Making transition: $transitionKey for instance: $instanceId${version != null ? " version: $version" : ""}');
    
    if (domain.isEmpty || workflowName.isEmpty) {
      logger.logError('[VNextWorkflowClient] ❌ ERROR: Domain or WorkflowName is empty!');
      logger.logError('[VNextWorkflowClient] Domain: "$domain", WorkflowName: "$workflowName"');
      return NeoResponse.error(
        NeoError(
          responseCode: 400,
          error: NeoErrorDetail(
            title: 'Invalid Request',
            description: 'Domain or WorkflowName is empty. Domain: "$domain", WorkflowName: "$workflowName"',
          ),
        ),
        responseHeaders: {},
      );
    }

    // TODO(stop-ship): remove temporary UI-key filtering when all callers send clean formData
    final Map<String, dynamic> sanitized = <String, dynamic>{};
    data.forEach((k, v) {
      if (v == null) return;
      if (k == 'selectedOptionTitle') return;
      if (k.startsWith('__')) return;
      if (k.endsWith('selectedOption')) return;
      sanitized[k] = v;
    });

    final queryParams = <String, dynamic>{};
    if (version != null) {
      queryParams['version'] = version;
    }
    // Add sync=true for synchronous transitions (backend expects this for immediate response)
    queryParams['sync'] = true;

    try {
      final response = await networkManager.call(
        NeoHttpCall(
          endpoint: 'vnext-post-transition',
          pathParameters: {
            'DOMAIN': domain,
            'WORKFLOW_NAME': workflowName,
            'INSTANCE_ID': instanceId,
            // Match http_client_config placeholder name
            'TRANSITION_NAME': transitionKey,
          },
          queryProviders: queryParams.isNotEmpty ? [HttpQueryProvider(queryParams)] : [],
          body: sanitized,
          headerParameters: headers ?? {},
          useHttps: false,
        ),
      );
      
      if (response is NeoSuccessResponse) {
        logger.logConsole('[VNextWorkflowClient] Transition successful, statusCode: ${response.statusCode}');
      } else if (response is NeoErrorResponse) {
        logger.logError('[VNextWorkflowClient] Transition failed, statusCode: ${response.statusCode}, error: ${response.error.error.description}');
        logger.logConsole('[VNextWorkflowClient] Error handler available: ${errorHandler != null}');
        
        // Process error response to log validation error details for developers
        // Returns original error unchanged (UI shows standard RFC 7807 message)
        if (errorHandler != null) {
          logger.logConsole('[VNextWorkflowClient] Calling errorHandler.processErrorResponse()...');
          final processedResponse = errorHandler!.processErrorResponse(response);
          logger.logConsole('[VNextWorkflowClient] Error handler processing complete');
          return processedResponse;
        } else {
          logger.logError('[VNextWorkflowClient] ERROR: errorHandler is null!');
        }
      }
      return response;
    } catch (e, stackTrace) {
      logger.logError('[VNextWorkflowClient] Exception during postTransition: $e');
      logger.logError('[VNextWorkflowClient] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get available transitions for a workflow instance
  /// // todo: check if this is needed
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
        useHttps: false,
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

    try {
      final response = await networkManager.call(
        NeoHttpCall(
          endpoint: 'vnext-get-workflow-instance',
          pathParameters: {
            'DOMAIN': domain,
            'WORKFLOW_NAME': workflowName,
            'INSTANCE_ID': instanceId,
          },
          headerParameters: headers ?? {},
          useHttps: false,
        ),
      );
      
      if (response is NeoSuccessResponse) {
        logger.logConsole('[VNextWorkflowClient] Get workflow instance successful, statusCode: ${response.statusCode}');
      } else if (response is NeoErrorResponse) {
        logger.logError('[VNextWorkflowClient] Get workflow instance failed, statusCode: ${response.statusCode}, error: ${response.error.error.description}');
      }
      return response;
    } catch (e, stackTrace) {
      logger.logError('[VNextWorkflowClient] Exception during getWorkflowInstance: $e');
      logger.logError('[VNextWorkflowClient] Stack trace: $stackTrace');
      rethrow;
    }
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
        useHttps: false,
      ),
    );
  }

  /// Fetch any vNext resource by relative path (href from instance extensions)
  /// Example: href = "core/workflows/.../functions/view?async=false"
  /// Pass href as-is; this method will normalize and call configured host.
  Future<NeoResponse> fetchByPath({
    required String href,
    Map<String, String>? headers,
  }) async {
    logger.logConsole('[VNextWorkflowClient] ===== fetchByPath CALLED =====');
    logger.logConsole('[VNextWorkflowClient] href: $href');
    logger.logConsole('[VNextWorkflowClient] headers: ${headers?.keys.join(", ") ?? "none"}');
    
    // Normalize: remove a possible leading slash to match '/{PATH}' template
    final normalized = href.startsWith('/') ? href.substring(1) : href;
    logger.logConsole('[VNextWorkflowClient] normalized path: $normalized');
    
    try {
      final response = await networkManager.call(
        NeoHttpCall(
          endpoint: 'vnext-fetch-by-path',
          pathParameters: {
            'PATH': normalized,
          },
          headerParameters: headers ?? {},
          useHttps: false,
        ),
      );
      
      logger.logConsole('[VNextWorkflowClient] fetchByPath response: isSuccess=${response.isSuccess}');
      if (response.isError) {
        logger.logError('[VNextWorkflowClient] fetchByPath error: ${response.asError.error.error.description}');
      }
      logger.logConsole('[VNextWorkflowClient] ===== fetchByPath COMPLETE =====');
      return response;
    } catch (e, stackTrace) {
      logger.logError('[VNextWorkflowClient] Exception in fetchByPath: $e');
      logger.logError('[VNextWorkflowClient] Stack trace: $stackTrace');
      rethrow;
    }
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
        useHttps: false,
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
        useHttps: false,
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
        useHttps: false,
      ),
    );
  }
}
