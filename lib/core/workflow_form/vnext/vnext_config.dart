/*
 * neo_core
 *
 * Created on 18/9/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

/// Configuration for vNext workflow integration
class VNextConfig {
  /// Enable V2 workflows (default: false)
  final bool enableV2Workflows;
  
  /// Base URL for vNext backend service
  final String? vNextBaseUrl;
  
  /// Domain for vNext workflows
  final String? vNextDomain;

  const VNextConfig({
    this.enableV2Workflows = false,
    this.vNextBaseUrl,
    this.vNextDomain,
  });

  /// Create configuration from environment variables
  factory VNextConfig.fromEnvironment() {
    return VNextConfig(
      enableV2Workflows: const bool.fromEnvironment(
        'ENABLE_V2_WORKFLOWS',
        defaultValue: false,
      ),
      vNextBaseUrl: const String.fromEnvironment(
        'VNEXT_BASE_URL',
        defaultValue: '',
      ).isEmpty ? null : const String.fromEnvironment('VNEXT_BASE_URL'),
      vNextDomain: const String.fromEnvironment(
        'VNEXT_DOMAIN',
        defaultValue: '',
      ).isEmpty ? null : const String.fromEnvironment('VNEXT_DOMAIN'),
    );
  }

  /// Create configuration with specific values
  factory VNextConfig.create({
    bool enableV2Workflows = false,
    String? vNextBaseUrl,
    String? vNextDomain,
  }) {
    return VNextConfig(
      enableV2Workflows: enableV2Workflows,
      vNextBaseUrl: vNextBaseUrl,
      vNextDomain: vNextDomain,
    );
  }

  /// Check if vNext is properly configured and can be used
  bool get isConfigured => 
      enableV2Workflows && 
      vNextBaseUrl != null && 
      vNextBaseUrl!.isNotEmpty &&
      vNextDomain != null && 
      vNextDomain!.isNotEmpty;

  /// Default configuration for development (pointing to local vNext runtime)
  static VNextConfig get development => VNextConfig.create(
    enableV2Workflows: true,
    vNextBaseUrl: 'http://localhost:4201',
    vNextDomain: 'core',
  );

  /// Default configuration with V2 disabled
  static VNextConfig get disabled => const VNextConfig(
    enableV2Workflows: false,
  );

  @override
  String toString() {
    return 'VNextConfig('
        'enableV2Workflows: $enableV2Workflows, '
        'vNextBaseUrl: $vNextBaseUrl, '
        'vNextDomain: $vNextDomain, '
        'isConfigured: $isConfigured'
        ')';
  }

  /// Copy configuration with overrides
  VNextConfig copyWith({
    bool? enableV2Workflows,
    String? vNextBaseUrl,
    String? vNextDomain,
  }) {
    return VNextConfig(
      enableV2Workflows: enableV2Workflows ?? this.enableV2Workflows,
      vNextBaseUrl: vNextBaseUrl ?? this.vNextBaseUrl,
      vNextDomain: vNextDomain ?? this.vNextDomain,
    );
  }
}
