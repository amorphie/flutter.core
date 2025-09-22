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

import 'dart:async';
import 'package:neo_core/core/analytics/neo_logger.dart';

/// Represents a workflow instance entity for tracking and management
class WorkflowInstanceEntity {
  final String instanceId;
  final String workflowName;
  final String engine; // "amorphie" or "vnext"
  final String status;
  final String? currentState;
  final Map<String, dynamic> attributes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? vNextDomain;
  final Map<String, dynamic> metadata;

  WorkflowInstanceEntity({
    required this.instanceId,
    required this.workflowName,
    required this.engine,
    required this.status,
    this.currentState,
    this.attributes = const {},
    required this.createdAt,
    required this.updatedAt,
    this.vNextDomain,
    this.metadata = const {},
  });

  WorkflowInstanceEntity copyWith({
    String? instanceId,
    String? workflowName,
    String? engine,
    String? status,
    String? currentState,
    Map<String, dynamic>? attributes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? vNextDomain,
    Map<String, dynamic>? metadata,
  }) {
    return WorkflowInstanceEntity(
      instanceId: instanceId ?? this.instanceId,
      workflowName: workflowName ?? this.workflowName,
      engine: engine ?? this.engine,
      status: status ?? this.status,
      currentState: currentState ?? this.currentState,
      attributes: attributes ?? this.attributes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      vNextDomain: vNextDomain ?? this.vNextDomain,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'WorkflowInstance(id: ${instanceId.substring(0, 8)}..., workflow: $workflowName, engine: $engine, status: $status)';
}

/// Event types for workflow instance events
enum WorkflowInstanceEventType {
  created,
  updated,
  statusChanged,
  transitionExecuted,
  terminated,
  error,
}

/// Workflow instance event for tracking changes
class WorkflowInstanceEvent {
  final WorkflowInstanceEventType type;
  final WorkflowInstanceEntity instance;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WorkflowInstanceEvent({
    required this.type,
    required this.instance,
    this.data = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Listener for workflow instance events
typedef WorkflowInstanceEventListener = void Function(WorkflowInstanceEvent event);

/// Manages multiple workflow instances across different engines (amorphie and vNext)
/// 
/// This manager provides:
/// - Multi-instance tracking and search capabilities
/// - Cross-engine workflow management
/// - Event-driven instance updates
/// - Searchable workflow registry
class WorkflowInstanceManager {
  final NeoLogger _logger;
  final Map<String, WorkflowInstanceEntity> _instances = {};
  final List<WorkflowInstanceEventListener> _eventListeners = [];
  final StreamController<WorkflowInstanceEvent> _eventController = StreamController.broadcast();
  
  // Statistics
  int _totalInstancesCreated = 0;
  int _totalTransitionsExecuted = 0;
  final DateTime _managerStartTime = DateTime.now();

  WorkflowInstanceManager({
    required NeoLogger logger,
  }) : _logger = logger {
    _logger.logConsole('[WorkflowInstanceManager] Initialized');
  }

  /// Stream of workflow instance events for real-time monitoring
  Stream<WorkflowInstanceEvent> get eventStream => _eventController.stream;

  /// Add a listener for workflow instance events
  void addListener(WorkflowInstanceEventListener listener) {
    _eventListeners.add(listener);
  }

  /// Remove a listener for workflow instance events
  void removeListener(WorkflowInstanceEventListener listener) {
    _eventListeners.remove(listener);
  }

  /// Track a new workflow instance when created
  void trackInstance(WorkflowInstanceEntity instance) {
    _logger.logConsole('[WorkflowInstanceManager] Tracking new instance: ${instance.instanceId} (${instance.workflowName})');
    
    _instances[instance.instanceId] = instance;
    _totalInstancesCreated++;
    
    final event = WorkflowInstanceEvent(
      type: WorkflowInstanceEventType.created,
      instance: instance,
      data: {
        'totalInstances': _instances.length,
        'engine': instance.engine,
      },
    );
    
    _emitEvent(event);
  }

  /// Update instance when workflow events occur
  void updateInstanceOnEvent(String instanceId, {
    String? newStatus,
    String? newState,
    Map<String, dynamic>? additionalAttributes,
    Map<String, dynamic>? additionalMetadata,
  }) {
    final instance = _instances[instanceId];
    if (instance == null) {
      _logger.logConsole('[WorkflowInstanceManager] WARNING: Cannot update unknown instance: $instanceId');
      return;
    }

    final updatedInstance = instance.copyWith(
      status: newStatus ?? instance.status,
      currentState: newState ?? instance.currentState,
      attributes: additionalAttributes != null 
          ? {...instance.attributes, ...additionalAttributes}
          : instance.attributes,
      metadata: additionalMetadata != null
          ? {...instance.metadata, ...additionalMetadata}
          : instance.metadata,
      updatedAt: DateTime.now(),
    );

    _instances[instanceId] = updatedInstance;
    _totalTransitionsExecuted++;

    final event = WorkflowInstanceEvent(
      type: WorkflowInstanceEventType.updated,
      instance: updatedInstance,
      data: {
        'previousStatus': instance.status,
        'newStatus': updatedInstance.status,
        'previousState': instance.currentState,
        'newState': updatedInstance.currentState,
      },
    );

    _emitEvent(event);
    
    _logger.logConsole('[WorkflowInstanceManager] Updated instance: ${instanceId.substring(0, 8)}... (${instance.status} → ${updatedInstance.status})');
  }

  /// Mark instance as terminated and clean up
  void terminateInstance(String instanceId, {String? reason}) {
    final instance = _instances[instanceId];
    if (instance == null) {
      _logger.logConsole('[WorkflowInstanceManager] WARNING: Cannot terminate unknown instance: $instanceId');
      return;
    }

    final terminatedInstance = instance.copyWith(
      status: 'terminated',
      updatedAt: DateTime.now(),
      metadata: {
        ...instance.metadata,
        'terminationReason': reason ?? 'Manual termination',
        'terminatedAt': DateTime.now().toIso8601String(),
      },
    );

    _instances[instanceId] = terminatedInstance;

    final event = WorkflowInstanceEvent(
      type: WorkflowInstanceEventType.terminated,
      instance: terminatedInstance,
      data: {
        'reason': reason,
        'previousStatus': instance.status,
      },
    );

    _emitEvent(event);
    
    _logger.logConsole('[WorkflowInstanceManager] Terminated instance: ${instanceId.substring(0, 8)}... (reason: ${reason ?? 'not specified'})');

    // Schedule cleanup after 5 minutes
    Timer(const Duration(minutes: 5), () => _cleanupInstance(instanceId));
  }

  /// Search instances by various criteria
  List<WorkflowInstanceEntity> searchInstances({
    String? workflowName,
    String? status,
    String? engine,
    String? vNextDomain,
    Map<String, dynamic>? attributeFilters,
  }) {
    return _instances.values.where((instance) {
      // Filter by workflow name
      if (workflowName != null && instance.workflowName != workflowName) {
        return false;
      }

      // Filter by status
      if (status != null && instance.status != status) {
        return false;
      }

      // Filter by engine
      if (engine != null && instance.engine != engine) {
        return false;
      }

      // Filter by vNext domain
      if (vNextDomain != null && instance.vNextDomain != vNextDomain) {
        return false;
      }

      // Filter by attributes
      if (attributeFilters != null) {
        for (final entry in attributeFilters.entries) {
          if (!instance.attributes.containsKey(entry.key) ||
              instance.attributes[entry.key] != entry.value) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  /// Get all active workflows across engines
  List<WorkflowInstanceEntity> getActiveWorkflows() {
    return searchInstances(status: 'active');
  }

  /// Get all workflows for a specific engine
  List<WorkflowInstanceEntity> getWorkflowsByEngine(String engine) {
    return searchInstances(engine: engine);
  }

  /// Get workflow by instance ID
  WorkflowInstanceEntity? getInstance(String instanceId) {
    return _instances[instanceId];
  }

  /// Get all instances for a specific workflow name
  List<WorkflowInstanceEntity> getInstancesByWorkflow(String workflowName) {
    return searchInstances(workflowName: workflowName);
  }

  /// Get instance count statistics
  Map<String, int> getInstanceStats() {
    final stats = <String, int>{
      'total': _instances.length,
      'active': 0,
      'completed': 0,
      'terminated': 0,
      'failed': 0,
      'amorphie': 0,
      'vnext': 0,
    };

    for (final instance in _instances.values) {
      // Count by status
      if (instance.status == 'active') stats['active'] = stats['active']! + 1;
      else if (instance.status == 'completed') stats['completed'] = stats['completed']! + 1;
      else if (instance.status == 'terminated') stats['terminated'] = stats['terminated']! + 1;
      else if (instance.status == 'failed') stats['failed'] = stats['failed']! + 1;

      // Count by engine
      if (instance.engine == 'amorphie') stats['amorphie'] = stats['amorphie']! + 1;
      else if (instance.engine == 'vnext') stats['vnext'] = stats['vnext']! + 1;
    }

    return stats;
  }

  /// Get comprehensive manager statistics
  Map<String, dynamic> getManagerStats() {
    final uptime = DateTime.now().difference(_managerStartTime);
    final stats = getInstanceStats();
    
    return {
      'totalInstancesCreated': _totalInstancesCreated,
      'totalTransitionsExecuted': _totalTransitionsExecuted,
      'currentInstances': _instances.length,
      'activeInstances': stats['active'],
      'uptimeMinutes': uptime.inMinutes,
      'averageInstancesPerHour': uptime.inHours > 0 ? _totalInstancesCreated / uptime.inHours : 0,
      'engineDistribution': {
        'amorphie': stats['amorphie'],
        'vnext': stats['vnext'],
      },
      'statusDistribution': {
        'active': stats['active'],
        'completed': stats['completed'],
        'terminated': stats['terminated'],
        'failed': stats['failed'],
      },
    };
  }

  /// Clear all terminated instances (cleanup)
  void clearTerminatedInstances() {
    final terminatedIds = _instances.entries
        .where((entry) => entry.value.status == 'terminated')
        .map((entry) => entry.key)
        .toList();
    
    for (final instanceId in terminatedIds) {
      _cleanupInstance(instanceId);
    }
    
    _logger.logConsole('[WorkflowInstanceManager] Cleared ${terminatedIds.length} terminated instances');
  }

  /// Dispose the manager and clean up resources
  void dispose() {
    _logger.logConsole('[WorkflowInstanceManager] Disposing manager');
    
    _eventController.close();
    _eventListeners.clear();
    _instances.clear();
    
    final stats = getManagerStats();
    _logger.logConsole('[WorkflowInstanceManager] Disposed - Stats: $stats');
  }

  // Private helper methods

  void _emitEvent(WorkflowInstanceEvent event) {
    // Notify listeners
    for (final listener in _eventListeners) {
      try {
        listener(event);
      } catch (e, stackTrace) {
        _logger.logConsole('[WorkflowInstanceManager] ERROR in event listener: $e\nStackTrace: $stackTrace');
      }
    }

    // Emit to stream
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void _cleanupInstance(String instanceId) {
    final removed = _instances.remove(instanceId);
    if (removed != null) {
      _logger.logConsole('[WorkflowInstanceManager] Cleaned up instance: ${instanceId.substring(0, 8)}...');
    }
  }
}
