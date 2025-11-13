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

import 'workflow_engine.dart';

/// Configuration for a workflow specifying which engine should handle it
class WorkflowConfig {
  /// The name of the workflow (e.g., 'account-opening', 'oauth-workflow')
  final String name;
  
  /// The engine that should handle this workflow
  final WorkflowEngine engine;
  
  /// Optional domain for the workflow (e.g., 'core', 'banking')
  final String? domain;
  
  /// Optional version for the workflow (e.g., '1.0.0', '2.1.0')
  final String? version;

  const WorkflowConfig({
    required this.name,
    required this.engine,
    this.domain,
    this.version,
  });

  /// Creates a WorkflowConfig from JSON
  /// 
  /// Supports both 'engine' and 'type' fields for backward compatibility:
  /// ```json
  /// {
  ///   "name": "account-opening",
  ///   "engine": "vnext",
  ///   "domain": "core",
  ///   "version": "1.0.0"
  /// }
  /// ```
  factory WorkflowConfig.fromJson(Map<String, dynamic> json) {
    return WorkflowConfig(
      name: json['name'] as String,
      engine: WorkflowEngine.fromString(json['engine'] ?? json['type'] ?? 'amorphie'),
      domain: json['domain'] as String?,
      version: json['version'] as String?,
    );
  }

  /// Converts the WorkflowConfig to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'engine': engine.toString(),
      if (domain != null) 'domain': domain,
      if (version != null) 'version': version,
    };
  }

  @override
  String toString() {
    return 'WorkflowConfig(name: $name, engine: $engine, domain: $domain, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkflowConfig &&
        other.name == name &&
        other.engine == engine &&
        other.domain == domain &&
        other.version == version;
  }

  @override
  int get hashCode {
    return Object.hash(name, engine, domain, version);
  }
}
