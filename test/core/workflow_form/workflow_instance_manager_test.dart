/*
 * neo_core
 *
 * Created on 22/9/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';

// Simple mock logger for testing
class MockNeoLogger implements NeoLogger {
  final List<String> logs = [];
  
  @override
  void logConsole(dynamic message, {dynamic logLevel}) {
    logs.add('CONSOLE: $message');
  }

  @override
  void logError(String message, {Map<String, dynamic>? properties}) {
    logs.add('ERROR: $message');
  }

  // Use noSuchMethod to handle all other methods
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('WorkflowInstanceManager Basic Tests', () {
    late WorkflowInstanceManager manager;
    late MockNeoLogger mockLogger;

    setUp(() {
      mockLogger = MockNeoLogger();
      manager = WorkflowInstanceManager(logger: mockLogger);
    });

    tearDown(() {
      manager.dispose();
    });

    test('should initialize with empty instances', () {
      // Arrange & Act
      final stats = manager.getInstanceStats();
      
      // Assert
      expect(stats['total'], equals(0));
      expect(stats['active'], equals(0));
      expect(manager.getActiveWorkflows(), isEmpty);
    });

    test('should track a new workflow instance', () {
      // Arrange
      final instance = WorkflowInstanceEntity(
        instanceId: 'test-123',
        workflowName: 'ecommerce',
        engine: WorkflowEngine.vnext,
        status: WorkflowInstanceStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      manager.trackInstance(instance);

      // Assert
      final stats = manager.getInstanceStats();
      expect(stats['total'], equals(1));
      expect(stats['active'], equals(1));
      expect(stats['vnext'], equals(1));
      expect(stats['amorphie'], equals(0));
      
      final retrievedInstance = manager.getInstance('test-123');
      expect(retrievedInstance, isNotNull);
      expect(retrievedInstance!.workflowName, equals('ecommerce'));
      expect(retrievedInstance.engine, equals(WorkflowEngine.vnext));
    });

    test('should update instance status', () {
      // Arrange
      final instance = WorkflowInstanceEntity(
        instanceId: 'test-456',
        workflowName: 'banking',
        engine: WorkflowEngine.amorphie,
        status: WorkflowInstanceStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      manager..trackInstance(instance)

      // Act
      ..updateInstanceOnEvent(
        'test-456',
        newStatus: WorkflowInstanceStatus.completed,
        newState: 'final-state',
      );

      // Assert
      final updatedInstance = manager.getInstance('test-456');
      expect(updatedInstance!.status, equals(WorkflowInstanceStatus.completed));
      expect(updatedInstance.currentState, equals('final-state'));
      
      final stats = manager.getInstanceStats();
      expect(stats['active'], equals(0));
      expect(stats['completed'], equals(1));
    });

    test('should search instances by engine', () {
      // Arrange
      final vNextInstance = WorkflowInstanceEntity(
        instanceId: 'vnext-1',
        workflowName: 'ecommerce',
        engine: WorkflowEngine.vnext,
        status: WorkflowInstanceStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final amorphieInstance = WorkflowInstanceEntity(
        instanceId: 'amorphie-1',
        workflowName: 'banking',
        engine: WorkflowEngine.amorphie,
        status: WorkflowInstanceStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      manager
      ..trackInstance(vNextInstance)
      ..trackInstance(amorphieInstance);

      // Act
      final vNextInstances = manager.getWorkflowsByEngine(WorkflowEngine.vnext);
      final amorphieInstances = manager.getWorkflowsByEngine(WorkflowEngine.amorphie);

      // Assert
      expect(vNextInstances, hasLength(1));
      expect(vNextInstances.first.instanceId, equals('vnext-1'));
      
      expect(amorphieInstances, hasLength(1));
      expect(amorphieInstances.first.instanceId, equals('amorphie-1'));
    });

    test('should terminate instance and schedule cleanup', () {
      // Arrange
      final instance = WorkflowInstanceEntity(
        instanceId: 'test-terminate',
        workflowName: 'payment',
        engine: WorkflowEngine.vnext,
        status: WorkflowInstanceStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      manager
      ..trackInstance(instance)

      // Act
      ..terminateInstance('test-terminate', reason: 'Test termination');

      // Assert
      final terminatedInstance = manager.getInstance('test-terminate');
      expect(terminatedInstance!.status, equals(WorkflowInstanceStatus.terminated));
      expect(terminatedInstance.metadata['terminationReason'], equals('Test termination'));
      
      final stats = manager.getInstanceStats();
      expect(stats['active'], equals(0));
      expect(stats['terminated'], equals(1));
    });

    test('should emit events when instances are tracked and updated', () async {
      // Arrange
      final events = <WorkflowInstanceEvent>[];
      manager.eventStream.listen(events.add);

      final instance = WorkflowInstanceEntity(
        instanceId: 'event-test',
        workflowName: 'test-workflow',
        engine: WorkflowEngine.amorphie,
        status: WorkflowInstanceStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      manager
      ..trackInstance(instance)
      ..updateInstanceOnEvent('event-test', newStatus: WorkflowInstanceStatus.completed);
      
      // Wait a bit for events to be processed
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(events, hasLength(2));
      expect(events[0].type, equals(WorkflowInstanceEventType.created));
      expect(events[1].type, equals(WorkflowInstanceEventType.updated));
      expect(events[0].instance.instanceId, equals('event-test'));
      expect(events[1].instance.status, equals(WorkflowInstanceStatus.completed));
    });

    test('should handle multiple instances with different statuses', () {
      // Arrange & Act
      final instances = [
        WorkflowInstanceEntity(
          instanceId: 'multi-1',
          workflowName: 'ecommerce',
          engine: WorkflowEngine.vnext,
          status: WorkflowInstanceStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        WorkflowInstanceEntity(
          instanceId: 'multi-2',
          workflowName: 'banking',
          engine: WorkflowEngine.amorphie,
          status: WorkflowInstanceStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        WorkflowInstanceEntity(
          instanceId: 'multi-3',
          workflowName: 'payment',
          engine: WorkflowEngine.vnext,
          status: WorkflowInstanceStatus.failed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final instance in instances) {
        manager.trackInstance(instance);
      }

      // Assert
      final stats = manager.getInstanceStats();
      expect(stats['total'], equals(3));
      expect(stats['active'], equals(1));
      expect(stats['completed'], equals(1));
      expect(stats['failed'], equals(1));
      expect(stats['vnext'], equals(2));
      expect(stats['amorphie'], equals(1));

      final activeInstances = manager.searchInstances(status: WorkflowInstanceStatus.active);
      expect(activeInstances, hasLength(1));
      expect(activeInstances.first.instanceId, equals('multi-1'));

      final vNextInstances = manager.searchInstances(engine: WorkflowEngine.vnext);
      expect(vNextInstances, hasLength(2));
    });
  });
}
