/*
 * neo_core
 *
 * Created on 23/9/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Unit tests for WorkflowFlutterBridge - UI integration testing
 */


import 'package:flutter_test/flutter_test.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';
import 'package:neo_core/core/workflow_form/workflow_flutter_bridge.dart';
import 'package:neo_core/core/workflow_form/workflow_service.dart';
import 'package:neo_core/core/workflow_form/workflow_ui_events.dart';

import 'mock_neo_logger.dart';

// Mock implementations

class MockWorkflowService implements WorkflowService {
  String? lastWorkflowName;
  Map<String, dynamic>? lastParameters;
  String? lastTransitionName;
  Map<String, dynamic>? lastBody;
  bool shouldReturnError = false;
  String? errorMessage;
  WorkflowResult? mockResult;

  @override
  Future<WorkflowResult> initWorkflow({
    required String workflowName,
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    bool isSubFlow = false,
  }) async {
    lastWorkflowName = workflowName;
    lastParameters = parameters;
    
    if (shouldReturnError) {
      return WorkflowResult.error(errorMessage ?? 'Test error');
    }
    
    return mockResult ?? WorkflowResult.success(
      instanceId: 'test-instance-123',
      data: {
        'page': {'pageId': 'welcome-page'},
        'state': 'initialized',
        'view-source': 'dynamic',
      },
    );
  }

  @override
  Future<WorkflowResult> postTransition({
    required String transitionName,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    bool isSubFlow = false,
  }) async {
    lastTransitionName = transitionName;
    lastBody = body;
    
    if (shouldReturnError) {
      return WorkflowResult.error(errorMessage ?? 'Transition failed');
    }
    
    return mockResult ?? WorkflowResult.success(
      instanceId: body['instanceId'] as String? ?? 'test-instance-123',
      data: {
        'page': {'pageId': 'result-page'},
        'navigation': 'push',
        'state': 'completed',
      },
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('WorkflowFlutterBridge Tests', () {
    late WorkflowFlutterBridge bridge;
    late MockWorkflowService mockWorkflowService;
    late MockNeoLogger mockLogger;
    late List<WorkflowUIEvent> capturedEvents;

    setUp(() {
      mockWorkflowService = MockWorkflowService();
      mockLogger = MockNeoLogger();
      
      bridge = WorkflowFlutterBridge(
        workflowService: mockWorkflowService,
        logger: mockLogger,
      );
      
      capturedEvents = [];
      bridge.uiEvents.listen((event) {
        capturedEvents.add(event);
      });
    });

    tearDown(() {
      bridge.dispose();
    });

    group('initWorkflow', () {
      test('should emit loading and navigation events for successful workflow init', () async {
        // Arrange
        const workflowName = 'loan-application';
        final parameters = {'amount': 50000};
        final uiConfig = WorkflowUIConfig(
          navigationType: NeoNavigationType.push,
          displayLoading: true,
        );

        // Act
        await bridge.initWorkflow(
          workflowName: workflowName,
          parameters: parameters,
          uiConfig: uiConfig,
        );

        // Wait for all events to be processed
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(capturedEvents.length, 3); // loading(true), navigate, loading(false)
        
        // Check loading start event
        final loadingStartEvent = capturedEvents[0];
        expect(loadingStartEvent.type, WorkflowUIEventType.loading);
        expect(loadingStartEvent.isLoading, true);
        
        // Check navigation event
        final navigationEvent = capturedEvents[1];
        expect(navigationEvent.type, WorkflowUIEventType.navigate);
        expect(navigationEvent.pageId, 'welcome-page');
        expect(navigationEvent.instanceId, 'test-instance-123');
        expect(navigationEvent.navigationType, NeoNavigationType.push);
        expect(navigationEvent.pageData?['view-source'], 'dynamic');
        
        // Check loading end event
        final loadingEndEvent = capturedEvents[2];
        expect(loadingEndEvent.type, WorkflowUIEventType.loading);
        expect(loadingEndEvent.isLoading, false);

        // Verify service interaction
        expect(mockWorkflowService.lastWorkflowName, workflowName);
        expect(mockWorkflowService.lastParameters, parameters);
        expect(mockLogger.logs.any((log) => log.contains('[WorkflowFlutterBridge] Workflow: $workflowName')), true);
      });

      test('should emit silent event when no pageId is provided', () async {
        // Arrange
        mockWorkflowService.mockResult = WorkflowResult.success(
          instanceId: 'silent-instance',
          data: {'state': 'initialized'}, // No page info
        );

        // Act
        await bridge.initWorkflow(
          workflowName: 'silent-workflow',
          uiConfig: const WorkflowUIConfig(displayLoading: false),
        );

        // Wait for events
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(capturedEvents.length, 1); // Only silent event (no loading)
        
        final silentEvent = capturedEvents[0];
        expect(silentEvent.type, WorkflowUIEventType.silent);
        expect(silentEvent.instanceId, 'silent-instance');
        expect(silentEvent.data['state'], 'initialized');
      });

      test('should emit error event on workflow initialization failure', () async {
        // Arrange
        mockWorkflowService.shouldReturnError = true;
        mockWorkflowService.errorMessage = 'Invalid workflow configuration';

        // Act
        await bridge.initWorkflow(
          workflowName: 'invalid-workflow',
          uiConfig: const WorkflowUIConfig(),
        );

        // Wait for events
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(capturedEvents.length, 3); // loading(true), error, loading(false)
        
        final errorEvent = capturedEvents[1];
        expect(errorEvent.type, WorkflowUIEventType.error);
        expect(errorEvent.error, 'Invalid workflow configuration');
        expect(errorEvent.displayAsPopup, true);
        
        expect(mockLogger.logs.any((log) => log.contains('ERROR: [WorkflowFlutterBridge] Error')), true);
      });

      test('should merge initial data with workflow response data', () async {
        // Arrange
        final initialData = {'userId': '123', 'theme': 'dark'};
        
        // Act
        await bridge.initWorkflow(
          workflowName: 'data-merge-test',
          initialData: initialData,
          uiConfig: const WorkflowUIConfig(displayLoading: false),
        );

        // Wait for events
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        final navigationEvent = capturedEvents.first;
        expect(navigationEvent.type, WorkflowUIEventType.navigate);
        expect(navigationEvent.pageData?['userId'], '123');
        expect(navigationEvent.pageData?['theme'], 'dark');
        expect(navigationEvent.pageData?['view-source'], 'dynamic'); // From workflow
        expect(navigationEvent.pageData?['state'], 'initialized'); // From workflow
      });
    });

    group('postTransition', () {
      test('should emit navigation event for successful transition', () async {
        // Arrange
        const transitionName = 'submit-form';
        final body = {
          'instanceId': 'test-instance-123',
          'formData': {'name': 'John', 'email': 'john@example.com'},
        };

        // Act
        await bridge.postTransition(
          transitionName: transitionName,
          body: body,
          uiConfig: const WorkflowUIConfig(displayLoading: true),
        );

        // Wait for events
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(capturedEvents.length, 3); // loading(true), navigate, loading(false)
        
        final navigationEvent = capturedEvents[1];
        expect(navigationEvent.type, WorkflowUIEventType.navigate);
        expect(navigationEvent.pageId, 'result-page');
        expect(navigationEvent.instanceId, 'test-instance-123');
        expect(navigationEvent.navigationType, NeoNavigationType.push);

        // Verify service interaction
        expect(mockWorkflowService.lastTransitionName, transitionName);
        expect(mockWorkflowService.lastBody, body);
      });

      test('should emit update data event when no navigation is needed', () async {
        // Arrange
        mockWorkflowService.mockResult = WorkflowResult.success(
          instanceId: 'update-instance',
          data: {'status': 'processed', 'timestamp': '2025-09-23T10:00:00Z'},
        );

        // Act
        await bridge.postTransition(
          transitionName: 'update-status',
          body: {'instanceId': 'update-instance'},
          uiConfig: const WorkflowUIConfig(displayLoading: false),
        );

        // Wait for events
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(capturedEvents.length, 1);
        
        final updateEvent = capturedEvents[0];
        expect(updateEvent.type, WorkflowUIEventType.updateData);
        expect(updateEvent.instanceId, 'update-instance');
        expect(updateEvent.pageData?['status'], 'processed');
        expect(updateEvent.pageData?['timestamp'], '2025-09-23T10:00:00Z');
      });

      test('should emit error event on transition failure', () async {
        // Arrange
        mockWorkflowService.shouldReturnError = true;
        mockWorkflowService.errorMessage = 'Invalid transition state';

        // Act
        await bridge.postTransition(
          transitionName: 'invalid-transition',
          body: {'instanceId': 'test-123'},
          uiConfig: const WorkflowUIConfig(displayLoading: true),
        );

        // Wait for events
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(capturedEvents.length, 3); // loading(true), error, loading(false)
        
        final errorEvent = capturedEvents[1];
        expect(errorEvent.type, WorkflowUIEventType.error);
        expect(errorEvent.error, 'Invalid transition state');
        expect(errorEvent.instanceId, 'test-123');
      });

      test('should parse different navigation types correctly', () async {
        // Test push replacement navigation
        mockWorkflowService.mockResult = WorkflowResult.success(
          instanceId: 'nav-test',
          data: {
            'page': {'pageId': 'new-page'},
            'navigation': 'replace',
          },
        );

        await bridge.postTransition(
          transitionName: 'replace-page',
          body: {'instanceId': 'nav-test'},
          uiConfig: const WorkflowUIConfig(displayLoading: false),
        );

        await Future.delayed(const Duration(milliseconds: 10));

        final navigationEvent = capturedEvents[0];
        expect(navigationEvent.navigationType, NeoNavigationType.pushReplacement);
      });
    });

    group('error handling', () {
      test('should handle errors via handleError method', () async {
        // Act
        bridge.handleError('Custom error message', instanceId: 'error-instance');

        // Wait for event to be processed
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(capturedEvents.length, 1);
        
        final errorEvent = capturedEvents[0];
        expect(errorEvent.type, WorkflowUIEventType.error);
        expect(errorEvent.error, 'Custom error message');
        expect(errorEvent.instanceId, 'error-instance');
      });
    });

    group('UI configuration', () {
      test('should respect displayLoading setting', () async {
        // Test with loading disabled
        await bridge.initWorkflow(
          workflowName: 'no-loading-test',
          uiConfig: const WorkflowUIConfig(displayLoading: false),
        );

        await Future.delayed(const Duration(milliseconds: 10));

        // Should only have navigation event, no loading events
        expect(capturedEvents.length, 1);
        expect(capturedEvents[0].type, WorkflowUIEventType.navigate);
      });

      test('should handle sub-navigator configuration', () async {
        await bridge.initWorkflow(
          workflowName: 'sub-nav-test',
          uiConfig: const WorkflowUIConfig(
            useSubNavigator: true,
            navigationType: NeoNavigationType.push,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 10));

        final navigationEvent = capturedEvents.firstWhere(
          (e) => e.type == WorkflowUIEventType.navigate,
        );
        expect(navigationEvent.useSubNavigator, true);
      });
    });
  });
}
