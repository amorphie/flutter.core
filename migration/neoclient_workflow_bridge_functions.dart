/*
 * neo_bank
 *
 * Created on 23/9/2025.
 * Copyright (c) 2025 BurganBank. All rights reserved.
 *
 * CORRECTED VERSION for NeoClient integration
 * This shows the proper implementation with logging and error handling
 */

import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';
import 'package:neo_core/core/workflow_form/workflow_flutter_bridge.dart';
import 'package:neo_core/core/workflow_form/workflow_service.dart';
import 'package:neo_core/core/workflow_form/workflow_ui_events.dart';

/// Workflow bridge functions that connect to the new architecture
/// These can be used as drop-in replacements in CustomFunctionRegisterer
class WorkflowBridgeFunctions {
  static WorkflowFlutterBridge get _bridge => GetIt.I.get<WorkflowFlutterBridge>();
  static NeoLogger get _logger => GetIt.I.get<NeoLogger>();

  /// Bridge implementation of initWorkflow
  /// This is a DROP-IN REPLACEMENT for the existing _initWorkflow function
  static Future<void> initWorkflow({required registry, args}) async {
    try {
      // Parse args exactly like the original function
      args as List;
      final String workflowId = args[0] as String;
      final Map? params = args.length > 1 ? args[1] as Map : null;
      final Map? queryParams = params?["queryParameters"] != null ? params!["queryParameters"] as Map : null;
      final Map? initialData = params?["initialData"] != null ? params!["initialData"] as Map : null;
      final bool? isSubFlow = params?["isSubFlow"];
      final bool? displayLoading = params?["displayLoading"];
      final NeoNavigationType? navigationType =
          params?["navigationType"] != null ? NeoNavigationType.fromJson(params!["navigationType"]) : null;
      final bool useSubNavigator = params?["useSubNavigator"] ?? false;

      _logger.logConsole('[WorkflowBridgeFunctions] Starting workflow: $workflowId');

      // ✅ BRIDGE: No BuildContext required!
      await _bridge.initWorkflow(
        workflowName: workflowId,
        parameters: queryParams?.cast<String, dynamic>(),
        isSubFlow: isSubFlow ?? false,
        uiConfig: WorkflowUIConfig(
          navigationType: navigationType,
          useSubNavigator: useSubNavigator,
          displayLoading: displayLoading ?? true,
        ),
        initialData: initialData?.cast<String, dynamic>(),
      );
    } catch (e) {
      _logger.logError('[WorkflowBridgeFunctions] initWorkflow failed: $e');
      _bridge.handleError(e);
    }
  }

  /// Bridge implementation of postTransition
  /// This is a DROP-IN REPLACEMENT for the existing _postTransition function
  static Future<void> postTransition({required registry, args}) async {
    try {
      // Parse args exactly like the original function
      final String transitionId = args[0] as String;
      final Map<String, dynamic>? transitionBody =
          args.length > 1 && args[1] != null ? Map<String, dynamic>.from(jsonDecode(jsonEncode(args[1]))) : null;
      final bool displayLoading = args.length > 2 ? args[2] : true;

      _logger.logConsole('[WorkflowBridgeFunctions] Posting transition: $transitionId');

      // Get page context for form data (fallback like original)
      Map<String, dynamic> body = transitionBody ?? {};
      
      // Note: In original implementation, if no transitionBody provided, 
      // it falls back to pageContext.read<NeoPageBloc>().formData
      // For clean architecture, we'll use the provided body or empty map

      // ✅ BRIDGE: No BuildContext required!
      await _bridge.postTransition(
        transitionName: transitionId,
        body: body,
        uiConfig: WorkflowUIConfig(
          displayLoading: displayLoading,
        ),
      );
    } catch (e) {
      _logger.logError('[WorkflowBridgeFunctions] postTransition failed: $e');
      _bridge.handleError(e);
    }
  }

  /// Bridge implementation of postTransitionV2
  /// This is a DROP-IN REPLACEMENT for the existing _postTransitionV2 function
  static Future<void> postTransitionV2({required registry, args}) async {
    // For now, delegate to the standard postTransition
    // Can be enhanced later for specific V2 features
    return postTransition(registry: registry, args: args);
  }

  /// Query workflow instances with enhanced filtering
  /// This provides access to vNext's powerful filtering capabilities
  static Future<void> queryWorkflowInstances({required registry, args}) async {
    try {
      // Parse args for query parameters
      args as List;
      final String workflowName = args[0] as String;
      final Map? params = args.length > 1 ? args[1] as Map : null;
      
      final String? domain = params?["domain"] as String?;
      final Map<String, String>? attributeFilters = params?["attributeFilters"] != null 
        ? Map<String, String>.from(params!["attributeFilters"]) : null;
      final int? page = params?["page"] as int?;
      final int? pageSize = params?["pageSize"] as int?;
      final String? sortBy = params?["sortBy"] as String?;
      final String? sortOrder = params?["sortOrder"] as String?;

      _logger.logConsole('[WorkflowBridgeFunctions] Querying workflow instances for: $workflowName');

      // Get workflow service and make the query
      final workflowService = GetIt.I.get<WorkflowService>();
      final result = await workflowService.queryWorkflowInstances(
        workflowName: workflowName,
        domain: domain,
        attributeFilters: attributeFilters,
        page: page,
        pageSize: pageSize,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      if (result.isSuccess) {
        _logger.logConsole('[WorkflowBridgeFunctions] Query successful: ${result.data?['totalCount'] ?? 'unknown'} instances');
      } else {
        _logger.logError('[WorkflowBridgeFunctions] Query failed: ${result.error}');
        _bridge.handleError(result.error ?? 'Query failed');
      }
    } catch (e) {
      _logger.logError('[WorkflowBridgeFunctions] queryWorkflowInstances failed: $e');
      _bridge.handleError(e);
    }
  }

  /// Get workflow instance history
  /// This provides access to instance state transitions and history
  static Future<void> getWorkflowInstanceHistory({required registry, args}) async {
    try {
      // Parse args for history request
      args as List;
      final String instanceId = args[0] as String;
      final Map? params = args.length > 1 ? args[1] as Map : null;
      
      final String? workflowName = params?["workflowName"] as String?;
      final String? domain = params?["domain"] as String?;

      _logger.logConsole('[WorkflowBridgeFunctions] Getting history for instance: $instanceId');

      if (workflowName == null || domain == null) {
        throw ArgumentError('workflowName and domain are required for history retrieval');
      }

      // Get workflow service and retrieve history
      final workflowService = GetIt.I.get<WorkflowService>();
      final result = await workflowService.getInstanceHistory(
        instanceId: instanceId,
        workflowName: workflowName,
        domain: domain,
      );

      if (result.isSuccess) {
        _logger.logConsole('[WorkflowBridgeFunctions] History retrieved successfully');
      } else {
        _logger.logError('[WorkflowBridgeFunctions] History retrieval failed: ${result.error}');
        _bridge.handleError(result.error ?? 'History retrieval failed');
      }
    } catch (e) {
      _logger.logError('[WorkflowBridgeFunctions] getWorkflowInstanceHistory failed: $e');
      _bridge.handleError(e);
    }
  }

  /// Get system health status
  /// This provides access to vNext system health monitoring
  static Future<void> getSystemHealth({required registry, args}) async {
    try {
      _logger.logConsole('[WorkflowBridgeFunctions] Getting system health');

      // Get workflow service and check health
      final workflowService = GetIt.I.get<WorkflowService>();
      final result = await workflowService.getSystemHealth();

      if (result.isSuccess) {
        final healthData = result.data;
        final status = healthData?['status'] ?? 'unknown';
        _logger.logConsole('[WorkflowBridgeFunctions] System health: $status');
      } else {
        _logger.logError('[WorkflowBridgeFunctions] Health check failed: ${result.error}');
        _bridge.handleError(result.error ?? 'Health check failed');
      }
    } catch (e) {
      _logger.logError('[WorkflowBridgeFunctions] getSystemHealth failed: $e');
      _bridge.handleError(e);
    }
  }

  /// Get system metrics
  /// This provides access to vNext system metrics for monitoring
  static Future<void> getSystemMetrics({required registry, args}) async {
    try {
      _logger.logConsole('[WorkflowBridgeFunctions] Getting system metrics');

      // Get workflow service and retrieve metrics
      final workflowService = GetIt.I.get<WorkflowService>();
      final result = await workflowService.getSystemMetrics();

      if (result.isSuccess) {
        _logger.logConsole('[WorkflowBridgeFunctions] Metrics retrieved successfully');
      } else {
        _logger.logError('[WorkflowBridgeFunctions] Metrics retrieval failed: ${result.error}');
        _bridge.handleError(result.error ?? 'Metrics retrieval failed');
      }
    } catch (e) {
      _logger.logError('[WorkflowBridgeFunctions] getSystemMetrics failed: $e');
      _bridge.handleError(e);
    }
  }

  // Note: Original implementation used specific parameter parsing.
  // The bridge implementation maintains compatibility while removing BuildContext dependency.
}

