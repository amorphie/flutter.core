// ignore_for_file: cascade_invocations

/*
 * neo_core
 *
 * Created on 22/9/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Multi-Engine Workflow Test - Basic integration test for vNext and amorphie workflow creation
 * and message dispatch routing.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/workflow_form/workflow_engine_config.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';

import 'mock_neo_logger.dart';

void main() {
  group('Simple Multi-Engine Workflow Tests', () {
    late WorkflowInstanceManager instanceManager;
    late MockNeoLogger mockLogger;

    setUp(() {
      mockLogger = MockNeoLogger();
      instanceManager = WorkflowInstanceManager(logger: mockLogger);
    });

    tearDown(() {
      instanceManager.dispose();
    });

    test('should create and track vNext and amorphie workflows separately', () {
      // Arrange - Create vNext workflow instance
      final vNextInstance = WorkflowInstanceEntity(
        instanceId: 'vnext-ecommerce-123',
        workflowName: 'ecommerce',
        engine: WorkflowEngine.vnext,
        status: WorkflowInstanceStatus.active,
        currentState: 'product-selection',
        domain: 'core',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attributes: {
          'clientId': '123',
          'sessionToken': 'vnext-token-456',
        },
        metadata: {
          'engine': 'vnext',
          'baseUrl': 'http://localhost:4201',
        },
      );

      // Arrange - Create amorphie workflow instance
      final amorphieInstance = WorkflowInstanceEntity(
        instanceId: 'amorphie-banking-789',
        workflowName: 'banking',
        engine: WorkflowEngine.amorphie,
        status: WorkflowInstanceStatus.active,
        currentState: 'account-verification',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attributes: {
          'customerId': '789',
          'sessionToken': 'amorphie-token-abc',
        },
        metadata: {
          'engine': 'amorphie',
          'signalRConnection': 'active',
        },
      );

      // Act - Track both instances
      instanceManager.trackInstance(vNextInstance);
      instanceManager.trackInstance(amorphieInstance);

      // Assert - Both instances are tracked
      final stats = instanceManager.getInstanceStats();
      expect(stats['total'], equals(2));
      expect(stats['active'], equals(2));
      expect(stats['vnext'], equals(1));
      expect(stats['amorphie'], equals(1));

      // Verify instances can be retrieved by engine
      final vNextInstances = instanceManager.getWorkflowsByEngine(WorkflowEngine.vnext);
      final amorphieInstances = instanceManager.getWorkflowsByEngine(WorkflowEngine.amorphie);

      expect(vNextInstances, hasLength(1));
      expect(amorphieInstances, hasLength(1));
      
      expect(vNextInstances.first.workflowName, equals('ecommerce'));
      expect(amorphieInstances.first.workflowName, equals('banking'));
    });

    test('should dispatch messages to correct workflow engine based on instanceId', () {
      // Arrange - Create instances
      final vNextEcommerce = WorkflowInstanceEntity(
        instanceId: 'vnext-ecom-001',
        workflowName: 'ecommerce',
        engine: WorkflowEngine.vnext,
        status: WorkflowInstanceStatus.active,
        domain: 'core',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final amorphieBanking = WorkflowInstanceEntity(
        instanceId: 'amorphie-bank-002',
        workflowName: 'banking',
        engine: WorkflowEngine.amorphie,
        status: WorkflowInstanceStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      instanceManager.trackInstance(vNextEcommerce);
      instanceManager.trackInstance(amorphieBanking);

      // Act - Simulate message dispatch to vNext workflow
      final vNextTargetInstance = instanceManager.getInstance('vnext-ecom-001');
      expect(vNextTargetInstance, isNotNull);
      expect(vNextTargetInstance!.engine, equals(WorkflowEngine.vnext));

      // Simulate updating the vNext instance (as if a transition was processed)
      instanceManager.updateInstanceOnEvent(
        'vnext-ecom-001',
        newStatus: WorkflowInstanceStatus.active,
        newState: 'payment-processing',
        additionalAttributes: {
          'transitionType': 'add-to-cart',
          'productId': 'prod-123',
        },
        additionalMetadata: {
          'processedBy': 'vNext-engine',
          'transitionTime': DateTime.now().toIso8601String(),
        },
      );

      // Act - Simulate message dispatch to amorphie workflow
      final amorphieTargetInstance = instanceManager.getInstance('amorphie-bank-002');
      expect(amorphieTargetInstance, isNotNull);
      expect(amorphieTargetInstance!.engine, equals(WorkflowEngine.amorphie));

      // Simulate updating the amorphie instance (as if a SignalR message was received)
      instanceManager.updateInstanceOnEvent(
        'amorphie-bank-002',
        newStatus: WorkflowInstanceStatus.active,
        newState: 'transfer-initiated',
        additionalAttributes: {
          'transitionType': 'transfer-money',
          'amount': 1000,
        },
        additionalMetadata: {
          'processedBy': 'amorphie-engine',
          'signalREvent': 'transition-received',
        },
      );

      // Assert - Both instances updated correctly
      final updatedVNext = instanceManager.getInstance('vnext-ecom-001');
      final updatedAmorphie = instanceManager.getInstance('amorphie-bank-002');

      expect(updatedVNext!.currentState, equals('payment-processing'));
      expect(updatedVNext.attributes['productId'], equals('prod-123'));
      expect(updatedVNext.metadata['processedBy'], equals('vNext-engine'));

      expect(updatedAmorphie!.currentState, equals('transfer-initiated'));
      expect(updatedAmorphie.attributes['amount'], equals(1000));
      expect(updatedAmorphie.metadata['processedBy'], equals('amorphie-engine'));
    });

    test('should handle workflow configuration parsing', () {
      // Arrange - Create workflow configurations
      final ecommerceConfig = WorkflowEngineConfig(
        workflowName: 'ecommerce',
        engine: 'vnext',
        config: {
          'baseUrl': 'http://localhost:4201',
          'domain': 'core',
        },
      );

      final bankingConfig = WorkflowEngineConfig(
        workflowName: 'banking',
        engine: 'amorphie',
        config: {},
      );

      // Act & Assert - Verify configuration properties
      expect(ecommerceConfig.isVNext, isTrue);
      expect(ecommerceConfig.isAmorphie, isFalse);
      expect(ecommerceConfig.isValid, isTrue);
      expect(ecommerceConfig.vNextDomain, equals('core'));
      expect(ecommerceConfig.vNextBaseUrl, equals('http://localhost:4201'));

      expect(bankingConfig.isAmorphie, isTrue);
      expect(bankingConfig.isVNext, isFalse);
      expect(bankingConfig.isValid, isTrue);
    });

    test('should demonstrate engine-specific message routing simulation', () {
      // Arrange - Create multiple instances of different engines
      final instances = [
        WorkflowInstanceEntity(
          instanceId: 'vnext-shop-001',
          workflowName: 'ecommerce',
          engine: WorkflowEngine.vnext,
          status: WorkflowInstanceStatus.active,
          domain: 'shopping',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        WorkflowInstanceEntity(
          instanceId: 'vnext-pay-002',
          workflowName: 'payment',
          engine: WorkflowEngine.vnext,
          status: WorkflowInstanceStatus.active,
          domain: 'payments',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        WorkflowInstanceEntity(
          instanceId: 'amorphie-bank-003',
          workflowName: 'banking',
          engine: WorkflowEngine.amorphie,
          status: WorkflowInstanceStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        WorkflowInstanceEntity(
          instanceId: 'amorphie-kyc-004',
          workflowName: 'kyc',
          engine: WorkflowEngine.amorphie,
          status: WorkflowInstanceStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final instance in instances) {
        instanceManager.trackInstance(instance);
      }

      // Act - Simulate message routing logic
      final messageTargets = [
        {'instanceId': 'vnext-shop-001', 'message': 'add-product-to-cart'},
        {'instanceId': 'amorphie-bank-003', 'message': 'validate-transfer'},
        {'instanceId': 'vnext-pay-002', 'message': 'process-payment'},
        {'instanceId': 'amorphie-kyc-004', 'message': 'verify-identity'},
      ];

      final processedMessages = <Map<String, dynamic>>[];

      for (final target in messageTargets) {
        final instanceId = target['instanceId'] as String;
        final message = target['message'] as String;
        
        // Simulate finding the target instance
        final targetInstance = instanceManager.getInstance(instanceId);
        
        if (targetInstance != null) {
          // Simulate routing decision based on engine
          final routingDecision = {
            'instanceId': instanceId,
            'message': message,
            'routedTo': targetInstance.engine.name,
            'workflowName': targetInstance.workflowName,
            'domain': targetInstance.domain,
          };
          
          processedMessages.add(routingDecision);
          
          // Simulate processing the message
          instanceManager.updateInstanceOnEvent(
            instanceId,
            additionalMetadata: {
              'lastMessage': message,
              'processedAt': DateTime.now().toIso8601String(),
            },
          );
        }
      }

      // Assert - Verify correct routing
      expect(processedMessages, hasLength(4));
      
      // Verify vNext messages
      final vNextMessages = processedMessages.where((m) => m['routedTo'] == 'vnext').toList();
      expect(vNextMessages, hasLength(2));
      expect(vNextMessages.any((m) => m['workflowName'] == 'ecommerce'), isTrue);
      expect(vNextMessages.any((m) => m['workflowName'] == 'payment'), isTrue);
      
      // Verify amorphie messages
      final amorphieMessages = processedMessages.where((m) => m['routedTo'] == 'amorphie').toList();
      expect(amorphieMessages, hasLength(2));
      expect(amorphieMessages.any((m) => m['workflowName'] == 'banking'), isTrue);
      expect(amorphieMessages.any((m) => m['workflowName'] == 'kyc'), isTrue);

      // Verify all instances were updated
      final finalStats = instanceManager.getInstanceStats();
      expect(finalStats['total'], equals(4));
    });

    test('should handle workflow termination across engines', () {
      // Arrange
      final vNextInstance = WorkflowInstanceEntity(
        instanceId: 'vnext-term-001',
        workflowName: 'ecommerce',
        engine: WorkflowEngine.vnext,
        status: WorkflowInstanceStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final amorphieInstance = WorkflowInstanceEntity(
        instanceId: 'amorphie-term-002',
        workflowName: 'banking',
        engine: WorkflowEngine.amorphie,
        status: WorkflowInstanceStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      instanceManager.trackInstance(vNextInstance);
      instanceManager.trackInstance(amorphieInstance);

      // Act - Terminate both workflows
      instanceManager.terminateInstance('vnext-term-001', reason: 'User cancelled ecommerce flow');
      instanceManager.terminateInstance('amorphie-term-002', reason: 'Banking session timeout');

      // Assert
      final vNextTerminated = instanceManager.getInstance('vnext-term-001');
      final amorphieTerminated = instanceManager.getInstance('amorphie-term-002');

      expect(vNextTerminated!.status, equals(WorkflowInstanceStatus.terminated));
      expect(amorphieTerminated!.status, equals(WorkflowInstanceStatus.terminated));

      expect(vNextTerminated.metadata['terminationReason'], equals('User cancelled ecommerce flow'));
      expect(amorphieTerminated.metadata['terminationReason'], equals('Banking session timeout'));

      final stats = instanceManager.getInstanceStats();
      expect(stats['active'], equals(0));
      expect(stats['terminated'], equals(2));
    });
  });
}
