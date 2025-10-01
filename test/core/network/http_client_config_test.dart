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
  group('HttpClientConfig Tests', () {
    late List<HttpHostDetails> testHosts;
    late List<HttpService> testServices;
    late HttpClientConfigParameters testConfig;

    setUp(() {
      testHosts = [
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

      testServices = [
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

      testConfig = HttpClientConfigParameters.fromJson({
        'cache-storage': true,
        'enable-mtls': false,
        'log-level': 'all'
      });
    });

    group('Factory Constructor', () {
      test('should create HttpClientConfig with workflow configurations', () {
        final rawWorkflowConfigs = {
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
            'config': <String, dynamic>{}
          }
        };

        final httpClientConfig = HttpClientConfig.fromJson(
          hosts: testHosts,
          services: testServices,
          config: testConfig,
          rawWorkflowConfigs: rawWorkflowConfigs,
        );

        expect(httpClientConfig.hosts, equals(testHosts));
        expect(httpClientConfig.services, equals(testServices));
        expect(httpClientConfig.config, equals(testConfig));
        expect(httpClientConfig.workflowConfigs, hasLength(3));
        expect(httpClientConfig.workflowConfigs['ecommerce-workflow']?.isVNext, isTrue);
        expect(httpClientConfig.workflowConfigs['oauth-workflow']?.isVNext, isTrue);
        expect(httpClientConfig.workflowConfigs['traditional-workflow']?.isVNext, isFalse);
      });

      test('should handle null workflow configurations', () {
        final httpClientConfig = HttpClientConfig.fromJson(
          hosts: testHosts,
          services: testServices,
          config: testConfig,
          rawWorkflowConfigs: null,
        );

        expect(httpClientConfig.workflowConfigs, isEmpty);
        expect(httpClientConfig.defaultWorkflowConfig.engine, equals('amorphie'));
      });

      test('should handle empty workflow configurations', () {
        final httpClientConfig = HttpClientConfig.fromJson(
          hosts: testHosts,
          services: testServices,
          config: testConfig,
          rawWorkflowConfigs: {},
        );

        expect(httpClientConfig.workflowConfigs, isEmpty);
        expect(httpClientConfig.defaultWorkflowConfig.engine, equals('amorphie'));
      });
    });

    group('Workflow Configuration Access', () {
      late HttpClientConfig httpClientConfig;

      setUp(() {
        final rawWorkflowConfigs = {
          'ecommerce-workflow': {
            'engine': 'vnext',
            'config': {'domain': 'ecommerce', 'baseUrl': 'https://api.example.com'}
          },
          'oauth-authentication-workflow': {
            'engine': 'vnext',
            'config': {'domain': 'oauth', 'baseUrl': 'https://api.example.com'}
          },
          'scheduled-payments-workflow': {
            'engine': 'vnext',
            'config': {'domain': 'payments', 'baseUrl': 'https://api.example.com'}
          }
        };

        httpClientConfig = HttpClientConfig.fromJson(
          hosts: testHosts,
          services: testServices,
          config: testConfig,
          rawWorkflowConfigs: rawWorkflowConfigs,
        );
      });

      test('should get workflow configuration for vNext workflows', () {
        final ecommerceConfig = httpClientConfig.getWorkflowConfig('ecommerce-workflow');
        
        expect(ecommerceConfig.workflowName, equals('ecommerce-workflow'));
        expect(ecommerceConfig.engine, equals('vnext'));
        expect(ecommerceConfig.isVNext, isTrue);
        expect(ecommerceConfig.vNextDomain, equals('ecommerce'));
      });

      test('should return default configuration for unknown workflows', () {
        final unknownConfig = httpClientConfig.getWorkflowConfig('unknown-workflow');
        
        expect(unknownConfig.workflowName, equals('default')); // Default config keeps its original name
        expect(unknownConfig.engine, equals('amorphie'));
        expect(unknownConfig.isVNext, isFalse);
      });

      test('should use exact matching only', () {
        // These should all return default (Amorphie) configuration
        final partialMatch1 = httpClientConfig.getWorkflowConfig('ecommerce');
        final partialMatch2 = httpClientConfig.getWorkflowConfig('ecommerce-workflow-v2');
        final partialMatch3 = httpClientConfig.getWorkflowConfig('my-ecommerce-workflow');

        expect(partialMatch1.isVNext, isFalse);
        expect(partialMatch2.isVNext, isFalse);
        expect(partialMatch3.isVNext, isFalse);
      });

      test('should validate workflow configurations', () {
        final errors = httpClientConfig.validateWorkflowConfigs();
        
        // All our test configurations should be valid
        expect(errors, isEmpty);
      });

      test('should generate workflow configuration summary', () {
        final summary = httpClientConfig.getWorkflowConfigSummary();
        
        expect(summary['totalConfigs'], equals(4)); // 3 defined + 1 default
        expect(summary['defaultEngine'], equals('amorphie'));
        expect(summary['engines'], isA<Map<String, int>>());
        
        final engines = summary['engines'] as Map<String, int>;
        expect(engines['vnext'], equals(3)); // 3 vNext workflows
        expect(engines['amorphie'], equals(1)); // 1 default amorphie
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
        };

        final httpClientConfig = HttpClientConfig.fromJson(
          hosts: testHosts,
          services: testServices,
          config: testConfig,
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
