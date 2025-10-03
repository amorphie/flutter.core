/*
 * neo_core
 *
 * Created on 2/10/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * vNext workflow message handler - integrates long polling with existing workflow system
 */

import 'dart:async';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/managers/vnext_long_polling_manager.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_polling_config.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_workflow_message.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_message_command_factory.dart';
import 'package:neo_core/core/workflow_form/workflow_flutter_bridge.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';

/// Handles vNext workflow messages and integrates with existing workflow system
/// 
/// This class:
/// - Manages long polling sessions for vNext workflow instances
/// - Converts vNext messages to UI events
/// - Integrates with WorkflowInstanceManager for instance tracking
/// - Provides the same interface as SignalR for seamless integration
class VNextWorkflowMessageHandler {
  final VNextLongPollingManager _pollingManager;
  final VNextMessageCommandFactory _commandFactory;
  final WorkflowInstanceManager _instanceManager;
  final NeoLogger _logger;

  // Stream controllers for different event types
  final StreamController<WorkflowUIEvent> _uiEventController = StreamController.broadcast();
  final StreamController<VNextWorkflowMessage> _rawMessageController = StreamController.broadcast();

  // Subscription to polling manager messages
  StreamSubscription<VNextWorkflowMessage>? _messageSubscription;

  VNextWorkflowMessageHandler({
    required VNextLongPollingManager pollingManager,
    required VNextMessageCommandFactory commandFactory,
    required WorkflowInstanceManager instanceManager,
    required NeoLogger logger,
  }) : _pollingManager = pollingManager,
       _commandFactory = commandFactory,
       _instanceManager = instanceManager,
       _logger = logger {
    _setupMessageListener();
  }

  /// Stream of UI events (compatible with WorkflowFlutterBridge)
  Stream<WorkflowUIEvent> get uiEvents => _uiEventController.stream;

  /// Stream of raw vNext messages (for debugging/monitoring)
  Stream<VNextWorkflowMessage> get rawMessages => _rawMessageController.stream;

  /// Start message handling for a workflow instance
  /// 
  /// This should be called when a vNext workflow is initialized
  Future<void> startHandling(String instanceId, {required String workflowName, VNextPollingConfig? config}) async {
    _logger.logConsole('[VNextWorkflowMessageHandler] Starting message handling for instance: $instanceId');

    try {
      // Start long polling for this instance
      await _pollingManager.startPolling(instanceId, workflowName: workflowName, config: config);
      
      _logger.logConsole('[VNextWorkflowMessageHandler] Started polling for instance: $instanceId');
    } catch (e) {
      _logger.logError('[VNextWorkflowMessageHandler] Failed to start handling for instance $instanceId: $e');
      rethrow;
    }
  }

  /// Stop message handling for a workflow instance
  /// 
  /// This should be called when a vNext workflow is completed or terminated
  Future<void> stopHandling(String instanceId) async {
    _logger.logConsole('[VNextWorkflowMessageHandler] Stopping message handling for instance: $instanceId');

    try {
      await _pollingManager.stopPolling(instanceId);
      
      _logger.logConsole('[VNextWorkflowMessageHandler] Stopped polling for instance: $instanceId');
    } catch (e) {
      _logger.logError('[VNextWorkflowMessageHandler] Failed to stop handling for instance $instanceId: $e');
    }
  }

  /// Stop all message handling
  Future<void> stopAllHandling() async {
    _logger.logConsole('[VNextWorkflowMessageHandler] Stopping all message handling');
    
    try {
      await _pollingManager.stopAllPolling();
      _logger.logConsole('[VNextWorkflowMessageHandler] Stopped all polling');
    } catch (e) {
      _logger.logError('[VNextWorkflowMessageHandler] Failed to stop all handling: $e');
    }
  }

  /// Get active instances being handled
  List<String> getActiveInstances() {
    return _pollingManager.getActiveInstances();
  }

  /// Get polling statistics
  Map<String, dynamic> getHandlingStats() {
    final pollingStats = _pollingManager.getPollingStats();
    
    return {
      'activeInstances': pollingStats['activeInstances'],
      'sessions': pollingStats['sessions'],
      'handlerInfo': {
        'uiEventListeners': _uiEventController.hasListener,
        'rawMessageListeners': _rawMessageController.hasListener,
      },
    };
  }

  /// Setup message listener from polling manager
  void _setupMessageListener() {
    _messageSubscription = _pollingManager.messageStream.listen(
      _handleMessage,
      onError: _handleMessageError,
    );
  }

  /// Handle incoming vNext workflow message
  void _handleMessage(VNextWorkflowMessage message) {
    _logger.logConsole('[VNextWorkflowMessageHandler] Handling message: ${message.type} for instance: ${message.instanceId}');

    try {
      // Emit raw message for debugging/monitoring
      _rawMessageController.add(message);

      // Update instance manager if needed
      _updateInstanceManager(message);

      // Convert to UI event and emit
      final uiEvent = _commandFactory.convertToUIEvent(message);
      if (uiEvent != null) {
        _logger.logConsole('[VNextWorkflowMessageHandler] Emitting UI event: ${uiEvent.type} for instance: ${message.instanceId}');
        _uiEventController.add(uiEvent);
      }

      // Handle special message types
      _handleSpecialMessageTypes(message);

    } catch (e) {
      _logger.logError('[VNextWorkflowMessageHandler] Failed to handle message: $e');
    }
  }

  /// Handle message processing errors
  void _handleMessageError(dynamic error) {
    _logger.logError('[VNextWorkflowMessageHandler] Message stream error: $error');
  }

  /// Update instance manager based on message
  void _updateInstanceManager(VNextWorkflowMessage message) {
    try {
      final instance = _instanceManager.getInstance(message.instanceId);
      
      if (instance != null) {
        // Update existing instance
        WorkflowInstanceStatus? newStatus;
        String? newState = message.state;
        
        switch (message.type) {
          case VNextWorkflowMessageType.completion:
            newStatus = WorkflowInstanceStatus.completed;
            break;
          case VNextWorkflowMessageType.error:
            newStatus = WorkflowInstanceStatus.failed;
            break;
          case VNextWorkflowMessageType.transition:
          case VNextWorkflowMessageType.stateChange:
            // Keep existing status, just update state
            break;
          case VNextWorkflowMessageType.data:
            // No status change for data updates
            newState = null;
            break;
        }

        if (newStatus != null || newState != null) {
          _instanceManager.updateInstanceOnEvent(
            message.instanceId,
            newStatus: newStatus,
            newState: newState,
            additionalAttributes: message.data,
            additionalMetadata: {
              ...message.metadata,
              'lastMessageType': message.type.name,
              'lastMessageTime': message.timestamp.toIso8601String(),
            },
          );
        }
      }
    } catch (e) {
      _logger.logError('[VNextWorkflowMessageHandler] Failed to update instance manager: $e');
    }
  }

  /// Handle special message types that require specific actions
  void _handleSpecialMessageTypes(VNextWorkflowMessage message) {
    switch (message.type) {
      case VNextWorkflowMessageType.completion:
        // Automatically stop polling when workflow completes
        _logger.logConsole('[VNextWorkflowMessageHandler] Workflow completed, stopping polling for instance: ${message.instanceId}');
        stopHandling(message.instanceId);
        break;
        
      case VNextWorkflowMessageType.error:
        // Log error and potentially stop polling based on error type
        _logger.logError('[VNextWorkflowMessageHandler] Workflow error for instance ${message.instanceId}: ${message.error}');
        
        // Check if it's a fatal error that should stop polling
        final isFatal = message.metadata['fatal'] as bool? ?? false;
        if (isFatal) {
          _logger.logConsole('[VNextWorkflowMessageHandler] Fatal error, stopping polling for instance: ${message.instanceId}');
          stopHandling(message.instanceId);
        }
        break;
        
      default:
        // No special handling needed
        break;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    _logger.logConsole('[VNextWorkflowMessageHandler] Disposing message handler');
    
    await _messageSubscription?.cancel();
    await _pollingManager.dispose();
    await _uiEventController.close();
    await _rawMessageController.close();
  }
}
