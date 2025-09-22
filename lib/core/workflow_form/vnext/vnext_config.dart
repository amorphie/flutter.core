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
  /// Base URL for vNext backend service
  final String? vNextBaseUrl;
  
  /// Domain for vNext workflows
  final String? vNextDomain;

  const VNextConfig({
    this.vNextBaseUrl,
    this.vNextDomain,
  });

  // TODO: this should be handled in an other entity
  // pass as paramaters, not configuration from env.
  /// Create configuration from environment variables
  factory VNextConfig.fromEnvironment() {
    return VNextConfig(
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
    String? vNextBaseUrl,
    String? vNextDomain,
  }) {
    return VNextConfig(
      vNextBaseUrl: vNextBaseUrl,
      vNextDomain: vNextDomain,
    );
  }

  /// Check if vNext is properly configured and can be used
  bool get isConfigured => 
      vNextBaseUrl != null && 
      vNextBaseUrl!.isNotEmpty &&
      vNextDomain != null && 
      vNextDomain!.isNotEmpty;

  /// Default configuration for development (pointing to local vNext runtime)
  static VNextConfig get development => VNextConfig.create(
    vNextBaseUrl: 'http://localhost:4201',
    vNextDomain: 'core',
  );

  /// Default configuration (empty, should be set via environment or config)
  static VNextConfig get empty => const VNextConfig();

  @override
  String toString() {
    return 'VNextConfig('
        'vNextBaseUrl: $vNextBaseUrl, '
        'vNextDomain: $vNextDomain, '
        'isConfigured: $isConfigured'
        ')';
  }

  /// Copy configuration with overrides
  VNextConfig copyWith({
    String? vNextBaseUrl,
    String? vNextDomain,
  }) {
    return VNextConfig(
      vNextBaseUrl: vNextBaseUrl ?? this.vNextBaseUrl,
      vNextDomain: vNextDomain ?? this.vNextDomain,
    );
  }
}
