/*
 * neo_core
 *
 * Created on 1/10/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:neo_core/core/workflow_form/workflow_engine_config.dart';

void main() {
  group('WorkflowEngineConfig Tests', () {
    test('should create vNext configuration correctly', () {
      final config = WorkflowEngineConfig.fromJson('ecommerce-workflow', {
        'engine': 'vnext',
        'config': {'domain': 'ecommerce', 'baseUrl': 'https://api.example.com'}
      });

      expect(config.workflowName, equals('ecommerce-workflow'));
      expect(config.engine, equals('vnext'));
      expect(config.isVNext, isTrue);
      expect(config.isValid, isTrue);
      expect(config.vNextDomain, equals('ecommerce'));
      expect(config.vNextBaseUrl, equals('https://api.example.com'));
    });

    test('should create Amorphie configuration correctly', () {
      final config = WorkflowEngineConfig.fromJson('traditional-workflow', {
        'engine': 'amorphie',
        'config': {'timeout': 30000}
      });

      expect(config.workflowName, equals('traditional-workflow'));
      expect(config.engine, equals('amorphie'));
      expect(config.isVNext, isFalse);
      expect(config.isValid, isTrue);
      expect(config.vNextDomain, isNull);
      expect(config.vNextBaseUrl, isNull);
    });

    test('should default to Amorphie when engine is not specified', () {
      final config = WorkflowEngineConfig.fromJson('default-workflow', {
        'config': {'some': 'value'}
      });

      expect(config.engine, equals('amorphie'));
      expect(config.isVNext, isFalse);
      expect(config.isValid, isTrue);
    });

    test('should handle empty configuration', () {
      final config = WorkflowEngineConfig.fromJson('empty-workflow', {});

      expect(config.workflowName, equals('empty-workflow'));
      expect(config.engine, equals('amorphie'));
      expect(config.isVNext, isFalse);
      expect(config.isValid, isTrue);
      expect(config.config, isEmpty);
    });

    test('should validate vNext configuration correctly', () {
      // Valid vNext config
      final validConfig = WorkflowEngineConfig.fromJson('valid-vnext', {
        'engine': 'vnext',
        'config': {'domain': 'test', 'baseUrl': 'https://api.example.com'}
      });
      expect(validConfig.isValid, isTrue);

      // Invalid vNext config (missing domain and baseUrl)
      final invalidConfig = WorkflowEngineConfig.fromJson('invalid-vnext', {
        'engine': 'vnext',
        'config': <String, dynamic>{}
      });
      expect(invalidConfig.isValid, isFalse);
    });

    test('should handle case-insensitive engine names', () {
      final config1 = WorkflowEngineConfig.fromJson('test1', {'engine': 'VNEXT'});
      final config2 = WorkflowEngineConfig.fromJson('test2', {'engine': 'VNext'});
      final config3 = WorkflowEngineConfig.fromJson('test3', {'engine': 'vnext'});

      expect(config1.isVNext, isTrue);
      expect(config2.isVNext, isTrue);
      expect(config3.isVNext, isTrue);
    });
  });

  group('WorkflowEngineConfigParser Tests', () {
    test('should parse workflow configurations from JSON', () {
      final httpClientConfig = {
        'workflows': {
          'ecommerce-workflow': {
            'engine': 'vnext',
            'config': {'domain': 'ecommerce', 'baseUrl': 'https://api.example.com'}
          },
          'oauth-workflow': {
            'engine': 'vnext',
            'config': {'domain': 'oauth', 'baseUrl': 'https://api.example.com'}
          },
          'traditional-workflow': {
            'engine': 'amorphie',
            'config': <String, dynamic>{'timeout': 30000}
          }
        }
      };

      final configs = WorkflowEngineConfigParser.parseWorkflowConfigs(httpClientConfig);

      expect(configs, hasLength(3));
      expect(configs['ecommerce-workflow']?.isVNext, isTrue);
      expect(configs['ecommerce-workflow']?.vNextDomain, equals('ecommerce'));
      expect(configs['oauth-workflow']?.isVNext, isTrue);
      expect(configs['oauth-workflow']?.vNextDomain, equals('oauth'));
      expect(configs['traditional-workflow']?.isVNext, isFalse);
    });

    test('should handle missing workflows section', () {
      final httpClientConfig = <String, dynamic>{};

      final configs = WorkflowEngineConfigParser.parseWorkflowConfigs(httpClientConfig);

      expect(configs, isEmpty);
    });

    test('should handle empty workflows section', () {
      final httpClientConfig = {
        'workflows': <String, dynamic>{}
      };

      final configs = WorkflowEngineConfigParser.parseWorkflowConfigs(httpClientConfig);

      expect(configs, isEmpty);
    });

    test('should create default configuration', () {
      final defaultConfig = WorkflowEngineConfig(
        workflowName: 'default',
        engine: 'amorphie',
        config: <String, dynamic>{},
      );

      expect(defaultConfig.workflowName, equals('default'));
      expect(defaultConfig.engine, equals('amorphie'));
      expect(defaultConfig.isVNext, isFalse);
      expect(defaultConfig.isValid, isTrue);
    });

    test('should get configuration for workflow with exact matching', () {
      final workflowConfigs = {
        'ecommerce-workflow': WorkflowEngineConfig.fromJson('ecommerce-workflow', {
          'engine': 'vnext',
          'config': {'domain': 'ecommerce', 'baseUrl': 'https://api.example.com'}
        }),
        'payment-flow': WorkflowEngineConfig.fromJson('payment-flow', {
          'engine': 'vnext',
          'config': {'domain': 'payments', 'baseUrl': 'https://api.example.com'}
        }),
      };
      final defaultConfig = WorkflowEngineConfig(
        workflowName: 'default',
        engine: 'amorphie',
        config: <String, dynamic>{},
      );

      // Test exact matches
      final ecommerceConfig = WorkflowEngineConfigParser.getConfigForWorkflow(
        'ecommerce-workflow',
        workflowConfigs,
        defaultConfig,
      );
      expect(ecommerceConfig.isVNext, isTrue);
      expect(ecommerceConfig.vNextDomain, equals('ecommerce'));

      // Test no partial matches (should return default)
      final partialConfig = WorkflowEngineConfigParser.getConfigForWorkflow(
        'ecommerce', // Missing '-workflow'
        workflowConfigs,
        defaultConfig,
      );
      expect(partialConfig.isVNext, isFalse); // Should be default (Amorphie)

      // Test unknown workflow (should return default)
      final unknownConfig = WorkflowEngineConfigParser.getConfigForWorkflow(
        'unknown-workflow',
        workflowConfigs,
        defaultConfig,
      );
      expect(unknownConfig.isVNext, isFalse); // Should be default (Amorphie)
    });

    test('should validate all configurations', () {
      final configs = {
        'valid-vnext': WorkflowEngineConfig.fromJson('valid-vnext', {
          'engine': 'vnext',
          'config': {'domain': 'test', 'baseUrl': 'https://api.example.com'}
        }),
        'invalid-vnext': WorkflowEngineConfig.fromJson('invalid-vnext', {
          'engine': 'vnext',
          'config': <String, dynamic>{} // Missing domain and baseUrl
        }),
        'valid-amorphie': WorkflowEngineConfig.fromJson('valid-amorphie', {
          'engine': 'amorphie',
          'config': <String, dynamic>{}
        }),
      };

      final errors = WorkflowEngineConfigParser.validateConfigs(configs);

      expect(errors, hasLength(2)); // Missing both domain and baseUrl
      expect(errors.any((error) => error.contains('invalid-vnext') && error.contains('missing domain')), isTrue);
      expect(errors.any((error) => error.contains('invalid-vnext') && error.contains('missing baseUrl')), isTrue);
    });

    test('should generate configuration summary', () {
      final configs = {
        'ecommerce-workflow': WorkflowEngineConfig.fromJson('ecommerce-workflow', {
          'engine': 'vnext',
          'config': {'domain': 'ecommerce', 'baseUrl': 'https://api.example.com'}
        }),
        'traditional-workflow': WorkflowEngineConfig.fromJson('traditional-workflow', {
          'engine': 'amorphie',
          'config': <String, dynamic>{}
        }),
      };
      final defaultConfig = WorkflowEngineConfig(
        workflowName: 'default',
        engine: 'amorphie',
        config: <String, dynamic>{},
      );

      final summary = WorkflowEngineConfigParser.getConfigSummary(configs, defaultConfig);

      expect(summary['totalConfigs'], equals(3)); // 2 defined + 1 default
      final engines = summary['engines'] as Map<String, int>;
      expect(engines['vnext'], equals(1));
      expect(engines['amorphie'], equals(2)); // 1 defined + 1 default
      expect(summary['defaultEngine'], equals('amorphie'));
      expect(summary['validConfigs'], equals(3)); // All should be valid
    });
  });

  group('Integration Tests', () {
    test('should handle real-world configuration structure', () {
      // Simulate the actual JSON structure from NeoClient
      final realWorldConfig = {
        'workflows': {
          'ecommerce-workflow': {
            'engine': 'vnext',
            'config': {
              'domain': 'ecommerce',
              'baseUrl': 'https://api.example.com'
            }
          },
          'oauth-authentication-workflow': {
            'engine': 'vnext',
            'config': {
              'domain': 'oauth',
              'baseUrl': 'https://api.example.com'
            }
          },
          'scheduled-payments-workflow': {
            'engine': 'vnext',
            'config': {
              'domain': 'payments',
              'baseUrl': 'https://api.example.com'
            }
          }
        }
      };

      final configs = WorkflowEngineConfigParser.parseWorkflowConfigs(realWorldConfig);
      final defaultConfig = WorkflowEngineConfig(
        workflowName: 'default',
        engine: 'amorphie',
        config: <String, dynamic>{},
      );

      // Test that all vNext workflows are parsed correctly
      expect(configs, hasLength(3));
      
      final ecommerceConfig = WorkflowEngineConfigParser.getConfigForWorkflow(
        'ecommerce-workflow',
        configs,
        defaultConfig,
      );
      expect(ecommerceConfig.isVNext, isTrue);
      expect(ecommerceConfig.vNextDomain, equals('ecommerce'));

      // Test that unknown workflows default to Amorphie
      final unknownConfig = WorkflowEngineConfigParser.getConfigForWorkflow(
        'some-legacy-workflow',
        configs,
        defaultConfig,
      );
      expect(unknownConfig.isVNext, isFalse);
      expect(unknownConfig.engine, equals('amorphie'));

      // Validate all configurations
      final errors = WorkflowEngineConfigParser.validateConfigs(configs);
      expect(errors, isEmpty); // All should be valid
    });
  });
}
