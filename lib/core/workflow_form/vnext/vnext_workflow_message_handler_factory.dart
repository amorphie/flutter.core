/*
 * neo_core
 *
 * Created on 6/10/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/managers/vnext_long_polling_manager.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_message_command_factory.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_message_handler.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';

/// Factory for creating and managing VNextWorkflowMessageHandler instances
/// 
/// Provides:
/// - Singleton handler management
/// - Lazy initialization
/// - Dependency injection for all required components
/// - Lifecycle management
class VNextWorkflowMessageHandlerFactory {
  final NeoNetworkManager _networkManager;
  final WorkflowInstanceManager _instanceManager;
  final NeoLogger _logger;
  
  // Singleton instance
  VNextWorkflowMessageHandler? _handler;
  VNextLongPollingManager? _pollingManager;
  VNextMessageCommandFactory? _commandFactory;
  
  VNextWorkflowMessageHandlerFactory({
    required NeoNetworkManager networkManager,
    required WorkflowInstanceManager instanceManager,
    required NeoLogger logger,
  }) : _networkManager = networkManager,
       _instanceManager = instanceManager,
       _logger = logger {
    _logger.logConsole('[VNextWorkflowMessageHandlerFactory] Factory initialized');
  }

  /// Get or create the singleton message handler
  VNextWorkflowMessageHandler getOrCreateHandler() {
    if (_handler == null) {
      _logger.logConsole('[VNextWorkflowMessageHandlerFactory] Creating new message handler');
      
      // Create dependencies
      _pollingManager = VNextLongPollingManager(
        networkManager: _networkManager,
        logger: _logger,
      );
      
      _commandFactory = VNextMessageCommandFactory(
        logger: _logger,
      );
      
      // Create handler
      _handler = VNextWorkflowMessageHandler(
        pollingManager: _pollingManager!,
        commandFactory: _commandFactory!,
        instanceManager: _instanceManager,
        logger: _logger,
      );
      
      _logger.logConsole('[VNextWorkflowMessageHandlerFactory] Message handler created successfully');
    }
    
    return _handler!;
  }

  /// Check if handler is initialized
  bool get isInitialized => _handler != null;

  /// Get handler if already initialized, null otherwise
  VNextWorkflowMessageHandler? get handlerIfInitialized => _handler;

  /// Dispose the factory and all managed resources
  Future<void> dispose() async {
    _logger.logConsole('[VNextWorkflowMessageHandlerFactory] Disposing factory');
    
    if (_handler != null) {
      await _handler!.dispose();
      _handler = null;
    }
    
    if (_pollingManager != null) {
      await _pollingManager!.dispose();
      _pollingManager = null;
    }
    
    _commandFactory = null;
    
    _logger.logConsole('[VNextWorkflowMessageHandlerFactory] Factory disposed');
  }

  /// Reset the factory (for testing or cleanup)
  Future<void> reset() async {
    _logger.logConsole('[VNextWorkflowMessageHandlerFactory] Resetting factory');
    await dispose();
  }

  /// Get factory statistics
  Map<String, dynamic> getFactoryStats() {
    return {
      'isInitialized': isInitialized,
      'handler': _handler != null ? _handler!.getHandlingStats() : null,
      'pollingManager': _pollingManager != null ? _pollingManager!.getPollingStats() : null,
    };
  }
}

