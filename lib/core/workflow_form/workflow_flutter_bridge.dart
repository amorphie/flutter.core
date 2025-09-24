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

import 'dart:async';

import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';
import 'package:neo_core/core/workflow_form/workflow_service.dart';
import 'package:neo_core/core/workflow_form/workflow_ui_events.dart';

/// Bridge between pure workflow business logic and Flutter UI layer
class WorkflowFlutterBridge {
  final WorkflowService _workflowService;
  final NeoLogger _logger;
  final StreamController<WorkflowUIEvent> _uiEventController;

  /// Stream of UI events for Flutter layer to listen to
  Stream<WorkflowUIEvent> get uiEvents => _uiEventController.stream;

  WorkflowFlutterBridge({
    required WorkflowService workflowService,
    required NeoLogger logger,
  })  : _workflowService = workflowService,
        _logger = logger,
        _uiEventController = StreamController<WorkflowUIEvent>.broadcast();

  /// Initialize a workflow - used by custom functions and widgets
  /// This replaces direct BLoC calls in CustomFunctionRegisterer
  Future<void> initWorkflow({
    required String workflowName,
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    bool isSubFlow = false,
    WorkflowUIConfig? uiConfig,
    Map<String, dynamic>? initialData,
  }) async {
    final config = uiConfig ?? const WorkflowUIConfig();
    
    _logger.logConsole('[WorkflowFlutterBridge] ========== INIT WORKFLOW START ==========');
    _logger.logConsole('[WorkflowFlutterBridge] Workflow: $workflowName');
    _logger.logConsole('[WorkflowFlutterBridge] Parameters: $parameters');
    _logger.logConsole('[WorkflowFlutterBridge] Headers: $headers');
    _logger.logConsole('[WorkflowFlutterBridge] IsSubFlow: $isSubFlow');
    _logger.logConsole('[WorkflowFlutterBridge] InitialData: $initialData');
    _logger.logConsole('[WorkflowFlutterBridge] UIConfig: displayLoading=${config.displayLoading}, navigationType=${config.navigationType}');
    
    try {
      // Emit loading event if requested
      if (config.displayLoading) {
        _logger.logConsole('[WorkflowFlutterBridge] Emitting loading event: true');
        _emitLoadingEvent(true, instanceId: null);
      }

      _logger.logConsole('[WorkflowFlutterBridge] Calling WorkflowService.initWorkflow...');

      // Call pure business logic
      final result = await _workflowService.initWorkflow(
        workflowName: workflowName,
        parameters: parameters,
        headers: headers,
        isSubFlow: isSubFlow,
      );

      _logger.logConsole('[WorkflowFlutterBridge] WorkflowService.initWorkflow completed');
      _logger.logConsole('[WorkflowFlutterBridge] Result.isSuccess: ${result.isSuccess}');
      _logger.logConsole('[WorkflowFlutterBridge] Result.instanceId: ${result.instanceId}');
      _logger.logConsole('[WorkflowFlutterBridge] Result.data: ${result.data}');
      _logger.logConsole('[WorkflowFlutterBridge] Result.error: ${result.error}');

      if (result.isSuccess) {
        _logger.logConsole('[WorkflowFlutterBridge] Processing successful result...');
        
        // Extract navigation information from result
        final data = result.data ?? {};
        final pageId = data['page']?['pageId'] as String? ?? 
                      data['init-page-name'] as String?;
        
        _logger.logConsole('[WorkflowFlutterBridge] Extracted pageId: $pageId');
        
        if (pageId != null) {
          _logger.logConsole('[WorkflowFlutterBridge] Emitting navigation event to pageId: $pageId');
          
          // Emit navigation event
          _uiEventController.add(WorkflowUIEvent.navigate(
            pageId: pageId,
            instanceId: result.instanceId,
            navigationType: config.navigationType ?? NeoNavigationType.push,
            useSubNavigator: config.useSubNavigator,
            pageData: _buildPageData(data, initialData),
            queryParameters: parameters,
          ));
        } else {
          _logger.logConsole('[WorkflowFlutterBridge] No pageId found, emitting silent event');
          
          // Silent success - no navigation needed
          _uiEventController.add(WorkflowUIEvent.silent(
            instanceId: result.instanceId,
            data: data,
          ));
        }

        _logger.logConsole('[WorkflowFlutterBridge] Workflow started successfully: ${result.instanceId}');
      } else {
        _logger.logError('[WorkflowFlutterBridge] Workflow failed with error: ${result.error}');
        
        // Emit error event
        _emitErrorEvent(result.error ?? 'Unknown workflow error');
      }
    } catch (e, stackTrace) {
      _logger.logError('[WorkflowFlutterBridge] Exception during workflow init: $e');
      _logger.logError('[WorkflowFlutterBridge] Stack trace: $stackTrace');
      _emitErrorEvent('Workflow initialization failed: $e');
    } finally {
      // Always hide loading
      if (config.displayLoading) {
        _logger.logConsole('[WorkflowFlutterBridge] Emitting loading event: false');
        _emitLoadingEvent(false, instanceId: null);
      }
      _logger.logConsole('[WorkflowFlutterBridge] ========== INIT WORKFLOW END ==========');
    }
  }

  /// Post a transition - used by custom functions and widgets
  /// This replaces direct BLoC calls in CustomFunctionRegisterer
  Future<void> postTransition({
    required String transitionName,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    bool isSubFlow = false,
    WorkflowUIConfig? uiConfig,
  }) async {
    final config = uiConfig ?? const WorkflowUIConfig();
    final instanceId = body['instanceId'] as String?;
    
    _logger.logConsole('[WorkflowFlutterBridge] ========== POST TRANSITION START ==========');
    _logger.logConsole('[WorkflowFlutterBridge] Transition: $transitionName');
    _logger.logConsole('[WorkflowFlutterBridge] Body: $body');
    _logger.logConsole('[WorkflowFlutterBridge] Headers: $headers');
    _logger.logConsole('[WorkflowFlutterBridge] InstanceId: $instanceId');
    _logger.logConsole('[WorkflowFlutterBridge] IsSubFlow: $isSubFlow');
    _logger.logConsole('[WorkflowFlutterBridge] UIConfig: displayLoading=${config.displayLoading}');
    
    try {
      // Emit loading event if requested
      if (config.displayLoading) {
        _logger.logConsole('[WorkflowFlutterBridge] Emitting loading event: true');
        _emitLoadingEvent(true, instanceId: instanceId);
      }

      _logger.logConsole('[WorkflowFlutterBridge] Calling WorkflowService.postTransition...');

      // Call pure business logic
      final result = await _workflowService.postTransition(
        transitionName: transitionName,
        body: body,
        headers: headers,
        isSubFlow: isSubFlow,
      );

      _logger.logConsole('[WorkflowFlutterBridge] WorkflowService.postTransition completed');
      _logger.logConsole('[WorkflowFlutterBridge] Result.isSuccess: ${result.isSuccess}');
      _logger.logConsole('[WorkflowFlutterBridge] Result.instanceId: ${result.instanceId}');
      _logger.logConsole('[WorkflowFlutterBridge] Result.data: ${result.data}');
      _logger.logConsole('[WorkflowFlutterBridge] Result.error: ${result.error}');

      if (result.isSuccess) {
        _logger.logConsole('[WorkflowFlutterBridge] Processing successful result...');
        
        // Extract navigation information from result
        final data = result.data ?? {};
        final navigation = data['navigation'] as String?;
        final pageId = data['page']?['pageId'] as String?;

        _logger.logConsole('[WorkflowFlutterBridge] Extracted navigation: $navigation, pageId: $pageId');

        if (navigation != null && pageId != null) {
          final navigationType = _parseNavigationType(navigation);
          
          _logger.logConsole('[WorkflowFlutterBridge] Emitting navigation event to pageId: $pageId, navigationType: $navigationType');
          
          // Emit navigation event
          _uiEventController.add(WorkflowUIEvent.navigate(
            pageId: pageId,
            instanceId: result.instanceId ?? instanceId,
            navigationType: navigationType,
            useSubNavigator: config.useSubNavigator,
            pageData: _buildPageData(data, null),
          ));
        } else {
          _logger.logConsole('[WorkflowFlutterBridge] No navigation/pageId found, emitting update data event');
          
          // Silent success - update data only
          _uiEventController.add(WorkflowUIEvent.updateData(
            pageData: data,
            instanceId: result.instanceId ?? instanceId,
          ));
        }

        _logger.logConsole('[WorkflowFlutterBridge] Transition posted successfully: ${result.instanceId ?? instanceId}');
      } else {
        _logger.logError('[WorkflowFlutterBridge] Transition failed with error: ${result.error}');
        
        // Emit error event
        _emitErrorEvent(result.error ?? 'Unknown transition error', instanceId: instanceId);
      }
    } catch (e, stackTrace) {
      _logger.logError('[WorkflowFlutterBridge] Exception during transition: $e');
      _logger.logError('[WorkflowFlutterBridge] Stack trace: $stackTrace');
      _emitErrorEvent('Transition failed: $e', instanceId: instanceId);
    } finally {
      // Always hide loading
      if (config.displayLoading) {
        _logger.logConsole('[WorkflowFlutterBridge] Emitting loading event: false');
        _emitLoadingEvent(false, instanceId: instanceId);
      }
      _logger.logConsole('[WorkflowFlutterBridge] ========== POST TRANSITION END ==========');
    }
  }

  /// Handle errors and emit error events
  void handleError(dynamic error, {String? instanceId}) {
    _emitErrorEvent(error.toString(), instanceId: instanceId);
  }

  /// Get active workflows for debugging/monitoring
  List<Map<String, dynamic>> getActiveWorkflows() {
    return _workflowService.getActiveWorkflows().map((instance) => {
      'instanceId': instance.instanceId,
      'workflowName': instance.workflowName,
      'engine': instance.engine.toString(),
      'status': instance.status.toString(),
      'currentState': instance.currentState,
      'createdAt': instance.createdAt.toIso8601String(),
    }).toList();
  }

  /// Dispose resources
  void dispose() {
    _uiEventController.close();
  }

  // Private helper methods
  void _emitLoadingEvent(bool isLoading, {String? instanceId}) {
    _uiEventController.add(WorkflowUIEvent.loading(
      isLoading: isLoading,
      instanceId: instanceId,
    ));
  }

  void _emitErrorEvent(String error, {String? instanceId}) {
    _logger.logError('[WorkflowFlutterBridge] Error: $error');
    _uiEventController.add(WorkflowUIEvent.error(
      error: error,
      instanceId: instanceId,
      displayAsPopup: true,
    ));
  }

  NeoNavigationType _parseNavigationType(String? navigation) {
    switch (navigation?.toLowerCase()) {
      case 'push':
        return NeoNavigationType.push;
      case 'replace':
        return NeoNavigationType.pushReplacement;
      case 'pop':
        return NeoNavigationType.pop;
      default:
        return NeoNavigationType.push;
    }
  }

  Map<String, dynamic> _buildPageData(Map<String, dynamic> workflowData, Map<String, dynamic>? initialData) {
    final pageData = <String, dynamic>{};
    
    // Add workflow response data
    pageData.addAll(workflowData);
    
    // Add initial data if provided
    if (initialData != null) {
      pageData.addAll(initialData);
    }
    
    // Ensure required fields exist
    if (!pageData.containsKey('viewSource')) {
      pageData['viewSource'] = workflowData['view-source'] ?? '';
    }
    
    return pageData;
  }
}
