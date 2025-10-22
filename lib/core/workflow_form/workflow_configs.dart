/*
 * neo_core
 *
 * Created on 22/9/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'workflow_config.dart';
import 'workflow_engine.dart';

/// Hardcoded configuration for workflow engines
/// 
/// This class provides a simple way to configure which workflows
/// should use the vNext engine vs the Amorphie engine.
/// 
/// To add a new vNext workflow, simply add it to the [vnextWorkflows] list.
class WorkflowConfigs {
  /// List of workflows that should use the vNext engine
  static const List<WorkflowConfig> vnextWorkflows = [
    WorkflowConfig(
      name: 'account-opening',
      engine: WorkflowEngine.vnext,
      domain: 'core',
      version: '1.0.0',
    ),
    WorkflowConfig(
      name: 'oauth-workflow',
      engine: WorkflowEngine.vnext,
      domain: 'core',
      version: '1.0.0',
    ),
    // Add more vNext workflows here as needed
  ];

  /// Checks if a workflow should use the vNext engine
  /// 
  /// Returns true if the workflow name exists in [vnextWorkflows],
  /// false otherwise (defaults to Amorphie).
  /// 
  /// Example:
  /// ```dart
  /// bool isVNext = WorkflowConfigs.isVNextWorkflow('account-opening'); // true
  /// bool isAmorphie = WorkflowConfigs.isVNextWorkflow('unknown-workflow'); // false
  /// ```
  static bool isVNextWorkflow(String workflowName) {
    return vnextWorkflows.any((config) => config.name == workflowName);
  }

  /// Gets the configuration for a specific workflow
  /// 
  /// Returns the WorkflowConfig if found, null otherwise.
  static WorkflowConfig? getWorkflowConfig(String workflowName) {
    try {
      return vnextWorkflows.firstWhere((config) => config.name == workflowName);
    } catch (e) {
      return null;
    }
  }

  /// Gets all workflow names that use the vNext engine
  static List<String> getVNextWorkflowNames() {
    return vnextWorkflows.map((config) => config.name).toList();
  }

  /// Gets all workflow names that use the Amorphie engine
  /// 
  /// Note: This is a placeholder since we don't maintain a list of Amorphie workflows.
  /// All workflows not in [vnextWorkflows] are considered Amorphie by default.
  static List<String> getAmorphieWorkflowNames() {
    // In practice, this would be all workflows not in vnextWorkflows
    // For now, we return an empty list since we don't track Amorphie workflows explicitly
    return [];
  }
}
