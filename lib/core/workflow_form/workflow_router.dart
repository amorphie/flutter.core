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

import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../analytics/neo_logger.dart';
import 'models/workflow_config.dart';
import 'workflow_configs.dart';

/// Single authority for determining which workflow engine should handle a workflow
/// 
/// This router provides a centralized decision point for workflow engine selection.
/// It uses hardcoded configuration to determine if a workflow should use vNext
/// or Amorphie engine.
/// 
/// Example usage:
/// ```dart
/// final router = WorkflowRouter(neoLogger);
/// bool isVNext = router.isVNextWorkflow('account-opening'); // true
/// bool isAmorphie = router.isVNextWorkflow('unknown-workflow'); // false
/// ```
class WorkflowRouter {
  final NeoLogger _logger;

  WorkflowRouter(this._logger);

  /// Determines which engine should handle the given workflow
  /// 
  /// Returns true for vNext engine, false for Amorphie engine.
  /// 
  /// The decision is based on hardcoded configuration in [WorkflowConfigs].
  /// All workflows not explicitly configured for vNext will use Amorphie.
  /// 
  /// Parameters:
  /// - [workflowName]: The name of the workflow to check
  /// 
  /// Returns:
  /// - true if the workflow should use vNext engine
  /// - false if the workflow should use Amorphie engine
  /// 
  /// Example:
  /// ```dart
  /// bool isVNext = router.isVNextWorkflow('account-opening'); // true
  /// bool isAmorphie = router.isVNextWorkflow('checking-account'); // false
  /// ```
  bool isVNextWorkflow(String workflowName) {
    final isVNext = WorkflowConfigs.isVNextWorkflow(workflowName);
    
    _logger.logConsole(
      'WorkflowRouter: "$workflowName" → ${isVNext ? "vNext" : "Amorphie"}',
      logLevel: Level.info,
    );
    
    return isVNext;
  }

  /// Gets the configuration for a specific workflow
  /// 
  /// Returns the WorkflowConfig if the workflow is configured for vNext,
  /// null if it should use Amorphie (default).
  WorkflowConfig? getWorkflowConfig(String workflowName) {
    final config = WorkflowConfigs.getWorkflowConfig(workflowName);
    
    if (config != null) {
      _logger.logConsole(
        'WorkflowRouter: Found config for "$workflowName": ${config.toString()}',
        logLevel: Level.debug,
      );
    } else {
      _logger.logConsole(
        'WorkflowRouter: No config found for "$workflowName", using Amorphie',
        logLevel: Level.debug,
      );
    }
    
    return config;
  }

  /// Gets all workflow names that are configured for vNext
  List<String> getVNextWorkflowNames() {
    return WorkflowConfigs.getVNextWorkflowNames();
  }

  /// Gets all workflow names that are configured for Amorphie
  /// 
  /// Note: This returns an empty list since we don't explicitly track
  /// Amorphie workflows. All workflows not in vNext config are Amorphie.
  List<String> getAmorphieWorkflowNames() {
    return WorkflowConfigs.getAmorphieWorkflowNames();
  }
}

/// Helper class for registering WorkflowRouter in dependency injection
class WorkflowRouterRegistration {
  /// Registers WorkflowRouter synchronously in GetIt
  /// 
  /// This method should be called after NeoLogger is registered.
  /// 
  /// Example:
  /// ```dart
  /// WorkflowRouterRegistration.register(getIt);
  /// ```
  static void register(GetIt getIt) {
    getIt.registerLazySingleton<WorkflowRouter>(
      () => WorkflowRouter(getIt.get<NeoLogger>()),
    );
  }

  /// Registers WorkflowRouter asynchronously in GetIt
  /// 
  /// This method should be called after NeoLogger is registered.
  /// 
  /// Example:
  /// ```dart
  /// await WorkflowRouterRegistration.registerAsync(getIt);
  /// ```
  static Future<void> registerAsync(GetIt getIt) async {
    getIt.registerLazySingletonAsync<WorkflowRouter>(
      () async => WorkflowRouter(getIt.get<NeoLogger>()),
    );
  }
}
