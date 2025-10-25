/*
 * neo_core
 *
 * Created on 1/10/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Diagnostic tools for workflow instance management - Development/Debug use only
 */

import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';

/// Diagnostic interface for workflow instance analysis
/// 
/// ⚠️ WARNING: This is for DEVELOPMENT/DEBUGGING only!
/// These methods should NOT be used in production business logic.
/// 
/// Use cases:
/// - Development debugging
/// - Performance monitoring
/// - System health checks
/// - Testing/QA validation
class WorkflowDiagnostics {
  final WorkflowInstanceManager _manager;

  WorkflowDiagnostics(this._manager);

  /// 🔍 DIAGNOSTIC: Get all active workflows across engines
  /// Use case: Development debugging, system health monitoring
  List<WorkflowInstanceEntity> getActiveWorkflows() {
    return _manager.searchInstances(status: WorkflowInstanceStatus.active);
  }

  /// 🔍 DIAGNOSTIC: Get all workflows for a specific engine
  /// Use case: Engine-specific debugging, performance analysis
  List<WorkflowInstanceEntity> getWorkflowsByEngine(WorkflowEngine engine) {
    return _manager.searchInstances(engine: engine);
  }

  /// 🔍 DIAGNOSTIC: Get all instances for a specific workflow name
  /// Use case: Workflow-specific debugging, testing validation
  List<WorkflowInstanceEntity> getInstancesByWorkflow(String workflowName) {
    return _manager.searchInstances(workflowName: workflowName);
  }

  /// 📊 DIAGNOSTIC: Get instance count statistics
  /// Use case: Performance monitoring, system health dashboard
  Map<String, int> getInstanceStats() {
    final stats = <String, int>{
      'total': _manager.getTotalInstanceCount(),
      'active': 0,
      'completed': 0,
      'terminated': 0,
      'failed': 0,
      'amorphie': 0,
      'vnext': 0,
    };

    final allInstances = _manager.getAllInstances();
    for (final instance in allInstances) {
      // Count by status
      switch (instance.status) {
        case WorkflowInstanceStatus.active:
          stats['active'] = stats['active']! + 1;
        case WorkflowInstanceStatus.completed:
          stats['completed'] = stats['completed']! + 1;
        case WorkflowInstanceStatus.terminated:
          stats['terminated'] = stats['terminated']! + 1;
        case WorkflowInstanceStatus.failed:
          stats['failed'] = stats['failed']! + 1;
        case WorkflowInstanceStatus.pending:
          // Add pending to stats if needed
          break;
      }

      // Count by engine
      switch (instance.engine) {
        case WorkflowEngine.amorphie:
          stats['amorphie'] = stats['amorphie']! + 1;
        case WorkflowEngine.vnext:
          stats['vnext'] = stats['vnext']! + 1;
      }
    }

    return stats;
  }

  /// 📊 DIAGNOSTIC: Get comprehensive manager statistics
  /// Use case: System monitoring, performance analysis, health checks
  Map<String, dynamic> getManagerStats() {
    return _manager.getManagerStats();
  }

  /// 🧹 DIAGNOSTIC: Clear all terminated instances (cleanup)
  /// Use case: Memory management during development, testing cleanup
  void clearTerminatedInstances() {
    _manager.clearTerminatedInstances();
  }

  /// 📋 DIAGNOSTIC: Get detailed system report
  /// Use case: Debug reports, system health summaries
  Map<String, dynamic> getSystemReport() {
    final stats = getInstanceStats();
    final managerStats = getManagerStats();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'summary': {
        'totalInstances': stats['total'],
        'activeInstances': stats['active'],
        'engineDistribution': {
          'vnext': stats['vnext'],
          'amorphie': stats['amorphie'],
        },
        'statusDistribution': {
          'active': stats['active'],
          'completed': stats['completed'],
          'terminated': stats['terminated'],
          'failed': stats['failed'],
        },
      },
      'performance': {
        'totalCreated': managerStats['totalInstancesCreated'],
        'totalTransitions': managerStats['totalTransitionsExecuted'],
        'uptimeMinutes': managerStats['uptimeMinutes'],
        'averageInstancesPerHour': managerStats['averageInstancesPerHour'],
      },
      'activeWorkflows': getActiveWorkflows().map((instance) => {
        'instanceId': instance.instanceId.substring(0, 8) + '...',
        'workflowName': instance.workflowName,
        'engine': instance.engine.toString(),
        'status': instance.status.toString(),
        'currentState': instance.currentState,
        'domain': instance.domain,
      }).toList(),
    };
  }
}
