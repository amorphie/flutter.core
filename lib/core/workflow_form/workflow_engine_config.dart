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

/// Configuration for a specific workflow's engine selection and settings
class WorkflowEngineConfig {
  final String workflowName;
  final String engine; // "vnext" or "amorphie"
  final Map<String, dynamic> config;

  WorkflowEngineConfig({
    required this.workflowName,
    required this.engine,
    required this.config,
  });

  /// Create configuration from JSON
  factory WorkflowEngineConfig.fromJson(String workflowName, Map<String, dynamic> json) {
    return WorkflowEngineConfig(
      workflowName: workflowName,
      engine: json['engine'] as String? ?? 'amorphie',
      config: json['config'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert configuration to JSON
  Map<String, dynamic> toJson() {
    return {
      'engine': engine,
      'config': config,
    };
  }

  /// Check if this configuration uses vNext engine
  bool get isVNext => engine.toLowerCase() == 'vnext';

  /// Check if this configuration uses amorphie engine
  bool get isAmorphie => engine.toLowerCase() == 'amorphie';

  /// Get vNext domain from config (if applicable)
  String? get vNextDomain => isVNext ? config['domain'] as String? : null;

  /// Get vNext base URL from config (if applicable)
  String? get vNextBaseUrl => isVNext ? config['baseUrl'] as String? : null;

  /// Check if the configuration is valid and complete
  bool get isValid {
    if (isVNext) {
      // vNext requires domain and baseUrl
      return vNextDomain != null && 
             vNextDomain!.isNotEmpty && 
             vNextBaseUrl != null && 
             vNextBaseUrl!.isNotEmpty;
    } else if (isAmorphie) {
      // Amorphie is always valid (uses existing infrastructure)
      return true;
    }
    
    return false;
  }

  @override
  String toString() => 'WorkflowEngineConfig(workflow: $workflowName, engine: $engine, valid: $isValid)';

  WorkflowEngineConfig copyWith({
    String? workflowName,
    String? engine,
    Map<String, dynamic>? config,
  }) {
    return WorkflowEngineConfig(
      workflowName: workflowName ?? this.workflowName,
      engine: engine ?? this.engine,
      config: config ?? this.config,
    );
  }
}

/// Parser for workflow engine configurations from HTTP client config
class WorkflowEngineConfigParser {
  /// Parse workflow configurations from http_client_config
  static Map<String, WorkflowEngineConfig> parseWorkflowConfigs(
    Map<String, dynamic> httpClientConfig,
  ) {
    final workflowsConfig = httpClientConfig['workflows'] as Map<String, dynamic>?;
    if (workflowsConfig == null) {
      return {};
    }

    final configs = <String, WorkflowEngineConfig>{};

    workflowsConfig.forEach((workflowName, config) {
      if (workflowName != 'default' && config is Map<String, dynamic>) {
        try {
          configs[workflowName] = WorkflowEngineConfig.fromJson(workflowName, config);
        } catch (e) {
          // Skip invalid configurations
          print('[WorkflowEngineConfigParser] Invalid config for $workflowName: $e');
        }
      }
    });

    return configs;
  }

  /// Parse default workflow configuration
  static WorkflowEngineConfig parseDefaultConfig(
    Map<String, dynamic> httpClientConfig,
  ) {
    final workflowsConfig = httpClientConfig['workflows'] as Map<String, dynamic>?;
    final defaultConfig = workflowsConfig?['default'] as Map<String, dynamic>?;

    if (defaultConfig != null) {
      return WorkflowEngineConfig.fromJson('default', defaultConfig);
    }

    // Return amorphie as default if no configuration found
    return WorkflowEngineConfig(
      workflowName: 'default',
      engine: 'amorphie',
      config: {},
    );
  }

  /// Get engine configuration for a specific workflow name
  static WorkflowEngineConfig getConfigForWorkflow(
    String workflowName,
    Map<String, WorkflowEngineConfig> workflowConfigs,
    WorkflowEngineConfig defaultConfig,
  ) {
    // Check for exact workflow name match
    if (workflowConfigs.containsKey(workflowName)) {
      return workflowConfigs[workflowName]!;
    }

    // Check for pattern matches (e.g., workflow names containing certain keywords)
    for (final entry in workflowConfigs.entries) {
      final configWorkflowName = entry.key;
      
      // Check if workflow name starts with config name (e.g., "ecommerce" matches "ecommerce-checkout")
      if (workflowName.startsWith(configWorkflowName)) {
        return entry.value;
      }
      
      // Check if workflow name contains config name (e.g., "payment" matches "user-payment-flow")
      if (workflowName.contains(configWorkflowName)) {
        return entry.value;
      }
    }

    // Return default configuration if no match found
    return defaultConfig;
  }

  /// Validate all workflow configurations
  static List<String> validateConfigs(Map<String, WorkflowEngineConfig> configs) {
    final errors = <String>[];

    for (final entry in configs.entries) {
      final config = entry.value;

      if (!config.isValid) {
        if (config.isVNext) {
          if (config.vNextBaseUrl == null || config.vNextBaseUrl!.isEmpty) {
            errors.add('${config.workflowName}: vNext configuration missing baseUrl');
          }
          if (config.vNextDomain == null || config.vNextDomain!.isEmpty) {
            errors.add('${config.workflowName}: vNext configuration missing domain');
          }
        } else {
          errors.add('${config.workflowName}: Invalid engine configuration');
        }
      }
    }

    return errors;
  }

  /// Get summary of workflow configurations
  static Map<String, dynamic> getConfigSummary(
    Map<String, WorkflowEngineConfig> configs,
    WorkflowEngineConfig defaultConfig,
  ) {
    final summary = <String, dynamic>{
      'totalConfigs': configs.length + 1, // +1 for default config
      'defaultEngine': defaultConfig.engine,
      'engines': <String, int>{},
      'validConfigs': 0,
      'invalidConfigs': 0,
    };

    // Count default config
    if (defaultConfig.isValid) {
      summary['validConfigs'] = (summary['validConfigs'] as int) + 1;
    } else {
      summary['invalidConfigs'] = (summary['invalidConfigs'] as int) + 1;
    }

    final engines = summary['engines'] as Map<String, int>;
    engines[defaultConfig.engine] = (engines[defaultConfig.engine] ?? 0) + 1;

    // Count workflow configs
    for (final config in configs.values) {
      if (config.isValid) {
        summary['validConfigs'] = (summary['validConfigs'] as int) + 1;
      } else {
        summary['invalidConfigs'] = (summary['invalidConfigs'] as int) + 1;
      }

      engines[config.engine] = (engines[config.engine] ?? 0) + 1;
    }

    return summary;
  }
}
