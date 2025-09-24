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

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/network/models/neo_error.dart';

/// Client for communicating with vNext backend workflow services
class VNextWorkflowClient {
  final String baseUrl;
  final http.Client httpClient;
  final dynamic logger;

  VNextWorkflowClient({
    required this.baseUrl,
    required this.httpClient,
    required this.logger,
  });

  /// Initialize (start) a workflow instance in vNext backend
  /// Endpoint: POST /api/v1/{domain}/workflows/{workflowName}/instances/start
  Future<NeoResponse> initWorkflow({
    required String domain,
    required String workflowName,
    required String key,
    Map<String, dynamic> attributes = const {},
    List<String> tags = const [],
    Map<String, String>? headers,
  }) async {
    try {
      logger.logConsole('[VNextWorkflowClient] Starting workflow: $workflowName in domain: $domain');
      
      final uri = Uri.parse('$baseUrl/api/v1/$domain/workflows/$workflowName/instances/start');
      final requestBody = {
        'key': key,
        'attributes': attributes,
        'tags': tags,
      };

      final response = await httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'tr-TR',
          'X-Request-Id': _generateUUID(),
          'X-Device-Id': _generateUUID(), 
          'X-Token-Id': _generateUUID(),
          'X-Device-Info': 'Flutter Client',
          ...?headers,
        },
        body: jsonEncode(requestBody),
      );

      logger.logConsole('[VNextWorkflowClient] Start workflow response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        logger.logConsole('[VNextWorkflowClient] Start workflow successful: $responseData');
        
        return NeoSuccessResponse(responseData, statusCode: response.statusCode, headers: {});
      } else {
        final errorMessage = 'Failed to start workflow: ${response.statusCode} - ${response.body}';
        logger.logError('[VNextWorkflowClient] Start workflow failed: $errorMessage');
        
        return NeoErrorResponse(
          NeoError(
            responseCode: response.statusCode,
            error: NeoErrorDetail(description: errorMessage),
          ),
          statusCode: response.statusCode,
          headers: {},
        );
      }
    } catch (e, stackTrace) {
      final errorMessage = 'Exception during workflow start: $e';
      logger.logError('[VNextWorkflowClient] Exception: $errorMessage', error: e, stackTrace: stackTrace);
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: errorMessage),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Make a transition on a workflow instance
  /// Endpoint: PATCH /api/v1/{domain}/workflows/{workflowName}/instances/{instanceId}/transitions/{transitionKey}
  Future<NeoResponse> postTransition({
    required String domain,
    required String workflowName,
    required String instanceId,
    required String transitionKey,
    Map<String, dynamic> data = const {},
    Map<String, String>? headers,
  }) async {
    try {
      logger.logConsole('[VNextWorkflowClient] Making transition: $transitionKey for instance: $instanceId');
      
      final uri = Uri.parse('$baseUrl/api/v1/$domain/workflows/$workflowName/instances/$instanceId/transitions/$transitionKey');
      final requestBody = data.isNotEmpty ? jsonEncode(data) : null;

      logger.logConsole('[VNextWorkflowClient] HTTP PATCH to: $uri');
      logger.logConsole('[VNextWorkflowClient] Request body: $requestBody');
      logger.logConsole('[VNextWorkflowClient] Request headers: ${headers.toString()}');

      final response = await httpClient.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'tr-TR',
          'X-Request-Id': _generateUUID(),
          'X-Device-Id': _generateUUID(),
          'X-Token-Id': _generateUUID(),
          'X-Device-Info': 'Flutter Client',
          ...?headers,
        },
        body: requestBody,
      );

      logger.logConsole('[VNextWorkflowClient] HTTP Response status: ${response.statusCode}');
      logger.logConsole('[VNextWorkflowClient] HTTP Response headers: ${response.headers}');
      logger.logConsole('[VNextWorkflowClient] HTTP Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        logger.logConsole('[VNextWorkflowClient] Transition successful: $responseData');
        
        return NeoSuccessResponse(responseData, statusCode: response.statusCode, headers: {});
      } else {
        final errorMessage = 'Failed to make transition: ${response.statusCode} - ${response.body}';
        logger.logError('[VNextWorkflowClient] Transition failed: $errorMessage');
        
        return NeoErrorResponse(
          NeoError(
            responseCode: response.statusCode,
            error: NeoErrorDetail(description: errorMessage),
          ),
          statusCode: response.statusCode,
          headers: {},
        );
      }
    } catch (e, stackTrace) {
      final errorMessage = 'Exception during transition: $e';
      logger.logError('[VNextWorkflowClient] Exception: $errorMessage', error: e, stackTrace: stackTrace);
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: errorMessage),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Get available transitions for a workflow instance
  /// Endpoint: GET /api/v1/{domain}/workflows/{workflowName}/instances/{instanceId}/transitions
  Future<NeoResponse> getAvailableTransitions({
    required String domain,
    required String workflowName,
    required String instanceId,
    Map<String, String>? headers,
  }) async {
    try {
      logger.logConsole('[VNextWorkflowClient] Getting available transitions for instance: $instanceId');
      
      final uri = Uri.parse('$baseUrl/api/v1/$domain/workflows/$workflowName/instances/$instanceId/transitions');

      final response = await httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Accept-Language': 'tr-TR',
          'X-Request-Id': _generateUUID(),
          'X-Device-Id': _generateUUID(),
          'X-Token-Id': _generateUUID(),
          'X-Device-Info': 'Flutter Client',
          ...?headers,
        },
      );

      logger.logConsole('[VNextWorkflowClient] Get transitions response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        logger.logConsole('[VNextWorkflowClient] Get transitions successful: $responseData');
        
        return NeoSuccessResponse(responseData, statusCode: response.statusCode, headers: {});
      } else {
        final errorMessage = 'Failed to get available transitions: ${response.statusCode} - ${response.body}';
        logger.logError('[VNextWorkflowClient] Get transitions failed: $errorMessage');
        
        return NeoErrorResponse(
          NeoError(
            responseCode: response.statusCode,
            error: NeoErrorDetail(description: errorMessage),
          ),
          statusCode: response.statusCode,
          headers: {},
        );
      }
    } catch (e, stackTrace) {
      final errorMessage = 'Exception during get transitions: $e';
      logger.logError('[VNextWorkflowClient] Exception: $errorMessage', error: e, stackTrace: stackTrace);
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: errorMessage),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Get workflow instance details
  /// Endpoint: GET /api/v1/{domain}/workflows/{workflowName}/instances/{instanceId}
  Future<NeoResponse> getWorkflowInstance({
    required String domain,
    required String workflowName,
    required String instanceId,
    Map<String, String>? headers,
  }) async {
    try {
      logger.logConsole('[VNextWorkflowClient] Getting workflow instance: $instanceId');
      
      final uri = Uri.parse('$baseUrl/api/v1/$domain/workflows/$workflowName/instances/$instanceId');

      final response = await httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Accept-Language': 'tr-TR',
          'X-Request-Id': _generateUUID(),
          'X-Device-Id': _generateUUID(),
          'X-Token-Id': _generateUUID(),
          'X-Device-Info': 'Flutter Client',
          ...?headers,
        },
      );

      logger.logConsole('[VNextWorkflowClient] Get instance response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        logger.logConsole('[VNextWorkflowClient] Get instance successful: $responseData');
        
        return NeoSuccessResponse(responseData, statusCode: response.statusCode, headers: {});
      } else {
        final errorMessage = 'Failed to get workflow instance: ${response.statusCode} - ${response.body}';
        logger.logError('[VNextWorkflowClient] Get instance failed: $errorMessage');
        
        return NeoErrorResponse(
          NeoError(
            responseCode: response.statusCode,
            error: NeoErrorDetail(description: errorMessage),
          ),
          statusCode: response.statusCode,
          headers: {},
        );
      }
    } catch (e, stackTrace) {
      final errorMessage = 'Exception during get instance: $e';
      logger.logError('[VNextWorkflowClient] Exception: $errorMessage', error: e, stackTrace: stackTrace);
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: errorMessage),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// List all instances for a specific workflow
  /// Endpoint: GET /api/v1/{domain}/workflows/{workflowName}/instances
  Future<NeoResponse> listWorkflowInstances({
    required String domain,
    required String workflowName,
    String? filter,
    int? page,
    int? pageSize,
    Map<String, String>? headers,
  }) async {
    logger.logConsole('[VNextWorkflowClient] Listing instances for workflow: $workflowName in domain: $domain');

    final queryParams = <String, String>{};
    if (filter != null) queryParams['filter'] = filter;
    if (page != null) queryParams['page'] = page.toString();
    if (pageSize != null) queryParams['pageSize'] = pageSize.toString();

    final uri = Uri.parse('$baseUrl/api/v1/$domain/workflows/$workflowName/instances')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Accept-Language': 'tr-TR',
          'X-Request-Id': _generateUUID(),
          'X-Device-Id': _generateUUID(),
          'X-Token-Id': _generateUUID(),
          'X-Device-Info': 'Flutter Client',
          ...?headers,
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          logger.logConsole('[VNextWorkflowClient] Successfully listed workflow instances');
          
          return NeoSuccessResponse(
            responseData,
            statusCode: response.statusCode,
            headers: {},
          );
        } catch (e) {
          final errorMessage = 'Failed to parse response JSON: $e';
          logger.logError('[VNextWorkflowClient] $errorMessage');
          
          return NeoErrorResponse(
            NeoError(
              responseCode: response.statusCode,
              error: NeoErrorDetail(description: errorMessage),
            ),
            statusCode: response.statusCode,
            headers: {},
          );
        }
      } else {
        final errorMessage = 'List instances failed with status ${response.statusCode}: ${response.body}';
        logger.logError('[VNextWorkflowClient] $errorMessage');
        
        return NeoErrorResponse(
          NeoError(
            responseCode: response.statusCode,
            error: NeoErrorDetail(description: errorMessage),
          ),
          statusCode: response.statusCode,
          headers: {},
        );
      }
    } catch (e, stackTrace) {
      final errorMessage = 'Exception during list instances: $e';
      logger.logError('[VNextWorkflowClient] $errorMessage', error: e, stackTrace: stackTrace);
      
      return NeoErrorResponse(
        NeoError(
          responseCode: 500,
          error: NeoErrorDetail(description: errorMessage),
        ),
        statusCode: 500,
        headers: {},
      );
    }
  }

  /// Generate a UUID for request headers
  String _generateUUID() {
    // Simple UUID generation for headers
    return '${DateTime.now().millisecondsSinceEpoch}-${1000 + (999 * (DateTime.now().microsecond / 1000000)).round()}';
  }
}
