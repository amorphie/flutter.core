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
import 'package:neo_core/core/network/models/http_client_config.dart';
import 'package:neo_core/core/network/models/http_client_config_parameters.dart';
import 'package:neo_core/core/network/models/http_host_details.dart';
import 'package:neo_core/core/network/models/http_service.dart';

void main() {
  group('Workflow Configuration Tests', () {
    late HttpClientConfig httpClientConfig;

    setUp(() {
      // Create test configuration with vNext and Amorphie workflows
      httpClientConfig = _createTestHttpClientConfig();
    });

    group('Configuration Loading', () {
      test('should correctly parse vNext workflow configuration', () {
        final config = httpClientConfig.getWorkflowConfig('ecommerce-workflow');
        
        expect(config.workflowName, equals('ecommerce-workflow'));
        expect(config.engine, equals('vnext'));
        expect(config.isVNext, isTrue);
        expect(config.isValid, isTrue);
        expect(config.vNextDomain, equals('ecommerce'));
      });

      test('should correctly parse multiple vNext workflows', () {
        final ecommerceConfig = httpClientConfig.getWorkflowConfig('ecommerce-workflow');
        final oauthConfig = httpClientConfig.getWorkflowConfig('oauth-authentication-workflow');
        final paymentsConfig = httpClientConfig.getWorkflowConfig('scheduled-payments-workflow');

        expect(ecommerceConfig.isVNext, isTrue);
        expect(ecommerceConfig.vNextDomain, equals('ecommerce'));

        expect(oauthConfig.isVNext, isTrue);
        expect(oauthConfig.vNextDomain, equals('oauth'));

        expect(paymentsConfig.isVNext, isTrue);
        expect(paymentsConfig.vNextDomain, equals('payments'));
      });

      test('should return default Amorphie config for unknown workflows', () {
        final config = httpClientConfig.getWorkflowConfig('unknown-workflow');
        
        expect(config.workflowName, equals('default')); // Default config keeps its original name
        expect(config.engine, equals('amorphie'));
        expect(config.isVNext, isFalse);
        expect(config.isValid, isTrue);
      });

      test('should use exact matching only (no pattern matching)', () {
        // Test that partial matches don't work
        final config1 = httpClientConfig.getWorkflowConfig('ecommerce'); // Missing '-workflow'
        final config2 = httpClientConfig.getWorkflowConfig('ecommerce-workflow-v2'); // Extra suffix
        final config3 = httpClientConfig.getWorkflowConfig('my-ecommerce-workflow'); // Extra prefix

        expect(config1.isVNext, isFalse); // Should default to Amorphie
        expect(config2.isVNext, isFalse); // Should default to Amorphie
        expect(config3.isVNext, isFalse); // Should default to Amorphie
      });
    });

    group('Configuration Validation', () {
      test('should validate workflow configurations', () {
        final errors = httpClientConfig.validateWorkflowConfigs();
        
        // All our test configurations should be valid
        expect(errors, isEmpty);
      });

      test('should generate workflow configuration summary', () {
        final summary = httpClientConfig.getWorkflowConfigSummary();
        
        expect(summary['totalConfigs'], equals(4)); // 3 defined + 1 default
        final engines = summary['engines'] as Map<String, int>;
        expect(engines['vnext'], equals(3));
        expect(engines['amorphie'], equals(1)); // 1 default amorphie config
        expect(summary['defaultEngine'], equals('amorphie'));
        expect(summary['validConfigs'], equals(4)); // All should be valid
      });

      test('should handle invalid vNext configurations', () {
        // Create config with invalid vNext workflow (missing domain)
        final invalidConfig = HttpClientConfig.fromJson(
          hosts: _createTestHosts(),
          services: _createTestServices(),
          config: _createTestConfigParameters(),
          rawWorkflowConfigs: {
            'invalid-vnext-workflow': {
              'engine': 'vnext',
              'config': <String, dynamic>{} // Missing domain
            }
          },
        );

        final config = invalidConfig.getWorkflowConfig('invalid-vnext-workflow');
        expect(config.isVNext, isTrue);
        expect(config.isValid, isFalse); // Should be invalid due to missing domain
        expect(config.vNextDomain, isNull);
      });
    });

    group('Integration with Real Configuration', () {
      test('should handle NeoClient configuration structure', () {
        // This simulates the exact structure that would come from NeoClient's JSON
        final realWorldRawConfigs = {
          'ecommerce-workflow': {
            'engine': 'vnext',
            'config': {
              'domain': 'ecommerce',
              'baseUrl': 'https://vnext.example.com'
            }
          },
          'oauth-authentication-workflow': {
            'engine': 'vnext',
            'config': {
              'domain': 'oauth',
              'baseUrl': 'https://vnext.example.com'
            }
          },
          'scheduled-payments-workflow': {
            'engine': 'vnext',
            'config': {
              'domain': 'payments',
              'baseUrl': 'https://vnext.example.com'
            }
          }
        };

        final httpClientConfig = HttpClientConfig.fromJson(
          hosts: _createTestHosts(),
          services: _createTestServices(),
          config: _createTestConfigParameters(),
          rawWorkflowConfigs: realWorldRawConfigs,
        );

        // Test that WorkflowRouter would get correct configurations
        final ecommerceConfig = httpClientConfig.getWorkflowConfig('ecommerce-workflow');
        final oauthConfig = httpClientConfig.getWorkflowConfig('oauth-authentication-workflow');
        final paymentsConfig = httpClientConfig.getWorkflowConfig('scheduled-payments-workflow');
        final unknownConfig = httpClientConfig.getWorkflowConfig('some-legacy-workflow');

        // vNext workflows should route to vNext
        expect(ecommerceConfig.isVNext, isTrue);
        expect(ecommerceConfig.vNextDomain, equals('ecommerce'));
        
        expect(oauthConfig.isVNext, isTrue);
        expect(oauthConfig.vNextDomain, equals('oauth'));
        
        expect(paymentsConfig.isVNext, isTrue);
        expect(paymentsConfig.vNextDomain, equals('payments'));

        // Unknown workflows should route to Amorphie
        expect(unknownConfig.isVNext, isFalse);
        expect(unknownConfig.engine, equals('amorphie'));

        // All configurations should be valid
        final errors = httpClientConfig.validateWorkflowConfigs();
        expect(errors, isEmpty);
      });
    });
  });
}

/// Helper function to create test HttpClientConfig with vNext workflows
HttpClientConfig _createTestHttpClientConfig() {
  return HttpClientConfig.fromJson(
    hosts: _createTestHosts(),
    services: _createTestServices(),
    config: _createTestConfigParameters(),
    rawWorkflowConfigs: {
      'ecommerce-workflow': {
        'engine': 'vnext',
        'config': {
          'domain': 'ecommerce',
          'baseUrl': 'https://vnext.example.com'
        }
      },
      'oauth-authentication-workflow': {
        'engine': 'vnext',
        'config': {
          'domain': 'oauth',
          'baseUrl': 'https://vnext.example.com'
        }
      },
      'scheduled-payments-workflow': {
        'engine': 'vnext',
        'config': {
          'domain': 'payments',
          'baseUrl': 'https://vnext.example.com'
        }
      }
    },
  );
}

/// Helper function to create test hosts
List<HttpHostDetails> _createTestHosts() {
  return [
    HttpHostDetails.fromJson({
      'key': 'bff',
      'active-hosts': [
        {
          'host': 'test-bff.example.com',
          'mtls-host': 'test-bff.example.com',
          'retry-count': 2
        }
      ]
    }),
    HttpHostDetails.fromJson({
      'key': 'vnext',
      'active-hosts': [
        {
          'host': 'test-vnext.example.com',
          'mtls-host': 'test-vnext.example.com',
          'retry-count': 2
        }
      ]
    }),
  ];
}

/// Helper function to create test services
List<HttpService> _createTestServices() {
  return [
    HttpService.fromJson({
      'key': 'init-workflow',
      'method': 'GET',
      'host': 'bff',
      'name': '/ebanking/flow/instance/workflow/{WORKFLOW_NAME}/init'
    }),
    HttpService.fromJson({
      'key': 'vnext-init-workflow',
      'method': 'POST',
      'host': 'vnext',
      'name': '/api/v1/{DOMAIN}/workflows/{WORKFLOW_NAME}/instances'
    }),
  ];
}

/// Helper function to create test config parameters
HttpClientConfigParameters _createTestConfigParameters() {
  return HttpClientConfigParameters.fromJson({
    'cache-storage': true,
    'enable-mtls': false,
    'log-level': 'all'
  });
}
