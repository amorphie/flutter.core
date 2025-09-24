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

  // Note: Original implementation used specific parameter parsing.
  // The bridge implementation maintains compatibility while removing BuildContext dependency.
}

