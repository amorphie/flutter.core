/*
 * neo_core
 *
 * Created on 18/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:collection/collection.dart';
import 'package:neo_core/core/network/helpers/mtls_helper.dart';
import 'package:neo_core/core/network/models/http_client_config_parameters.dart';
import 'package:neo_core/core/network/models/http_host_details.dart';
import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/core/network/models/http_service.dart';
import 'package:neo_core/core/network/models/mtls_enabled_transition.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:neo_core/core/workflow_form/workflow_engine_config.dart';

class HttpClientConfig {
  final List<HttpHostDetails> hosts;
  final List<HttpService> services;
  final List<MtlsEnabledTransition> mtlsEnabledTransitions;
  final Map<String, WorkflowEngineConfig> workflowConfigs;
  final WorkflowEngineConfig defaultWorkflowConfig;
  final List<HttpHostDetails> vNextHosts;

  HttpClientConfigParameters _config;

  HttpClientConfig({
    required this.hosts,
    required HttpClientConfigParameters config,
    required this.services,
    this.mtlsEnabledTransitions = const [],
    this.workflowConfigs = const {},
    WorkflowEngineConfig? defaultWorkflowConfig,
    this.vNextHosts = const [],
  }) : _config = config,
       defaultWorkflowConfig = defaultWorkflowConfig ?? WorkflowEngineConfig(
         workflowName: 'default',
         engine: 'amorphie',
         config: {},
       );

  HttpClientConfigParameters get config => _config;

  HttpClientConfig copyWith({
    List<HttpHostDetails>? hosts,
    HttpClientConfigParameters? config,
    List<HttpService>? services,
    List<MtlsEnabledTransition>? mtlsEnabledTransitions,
    Map<String, WorkflowEngineConfig>? workflowConfigs,
    WorkflowEngineConfig? defaultWorkflowConfig,
    List<HttpHostDetails>? vNextHosts,
  }) {
    return HttpClientConfig(
      hosts: hosts ?? this.hosts,
      config: config ?? this.config,
      services: services ?? this.services,
      mtlsEnabledTransitions: mtlsEnabledTransitions ?? this.mtlsEnabledTransitions,
      workflowConfigs: workflowConfigs ?? this.workflowConfigs,
      defaultWorkflowConfig: defaultWorkflowConfig ?? this.defaultWorkflowConfig,
      vNextHosts: vNextHosts ?? this.vNextHosts,
    );
  }

  void updateConfig(HttpClientConfig newConfig) {
    hosts
      ..clear()
      ..addAll(newConfig.hosts);
    _config = newConfig.config;
    services
      ..clear()
      ..addAll(newConfig.services);
    mtlsEnabledTransitions
      ..clear()
      ..addAll(newConfig.mtlsEnabledTransitions);
    workflowConfigs
      ..clear()
      ..addAll(newConfig.workflowConfigs);
    vNextHosts
      ..clear()
      ..addAll(newConfig.vNextHosts);
  }

  HttpMethod? getServiceMethodByKey(String key) {
    return _findServiceByKey(key)?.method;
  }

  Future<void> setMtlsStatusForHttpCall(
    NeoHttpCall neoHttpCall,
    MtlsHelper mtlsHelper,
    NeoCoreSecureStorage secureStorage,
  ) async {
    final service = _findServiceByKey(neoHttpCall.endpoint);
    if (service == null) {
      return;
    }
    final mtlsConfig = service.key == NeoWorkflowManager.endpointPostTransition
        ? mtlsEnabledTransitions
            .firstWhereOrNull(
              (transition) =>
                  transition.transitionName ==
                  neoHttpCall.pathParameters?[NeoWorkflowManager.pathParameterTransitionName],
            )
            ?.config
        : null;
    final isMtlsEnabledTransition = mtlsConfig?.enableMtls ?? false;
    final shouldSignTransitionForMtls = mtlsConfig?.signForMtls ?? false;

    bool enableMtls = isMtlsEnabledTransition || service.enableMtls;
    if (enableMtls) {
      final result = await Future.wait([
        secureStorage.read(NeoCoreParameterKey.secureStorageCustomerId),
        secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
      ]);

      final userReference = result[0];
      final deviceId = result[1];
      final clientKeyTag = "$deviceId$userReference";
      final certificate = await mtlsHelper.getCertificate(clientKeyTag: clientKeyTag);
      enableMtls &= certificate != null;
    }

    final signForMtls = shouldSignTransitionForMtls || service.signForMtls;

    neoHttpCall.setMtlsStatus(enableMtls: enableMtls, signForMtls: signForMtls);
  }

  String? getServiceUrlByKey(
    String key, {
    required bool enableMtls,
    Map<String, String>? parameters,
    bool useHttps = true,
  }) {
    final prefix = useHttps ? "https://" : "http://";
    final service = _findServiceByKey(key);
    if (service == null) {
      return null;
    }

    final baseUrl = _getBaseUrlByHost(service.host, enableMtls);
    if (baseUrl == null) {
      return null;
    }
    String fullUrl = prefix + baseUrl + service.name;
    parameters?.forEach((key, value) {
      fullUrl = fullUrl.replaceAll('{$key}', value);
    });
    return fullUrl;
  }

  int getRetryCountByKey(String key) {
    final service = _findServiceByKey(key);
    if (service == null) {
      return 0;
    }
    if (service.retryCount != null) {
      return service.retryCount!;
    }
    return _getRetryCountByHost(service.host) ?? 0;
  }

  HttpService? _findServiceByKey(String key) {
    return services.firstWhereOrNull((element) => element.key == key);
  }

  String? _getBaseUrlByHost(String host, bool enableMtls) {
    final activeHost = hosts.firstWhereOrNull((element) => element.key == host)?.activeHosts.firstOrNull;
    return enableMtls ? activeHost?.mtlsHost : activeHost?.host;
  }

  int? _getRetryCountByHost(String host) {
    return hosts.firstWhereOrNull((element) => element.key == host)?.activeHosts.firstOrNull?.retryCount;
  }

  // Workflow configuration methods

  /// Get workflow engine configuration for a specific workflow name
  WorkflowEngineConfig getWorkflowConfig(String workflowName) {
    return WorkflowEngineConfigParser.getConfigForWorkflow(
      workflowName,
      workflowConfigs,
      defaultWorkflowConfig,
    );
  }


  /// Check if any workflow is configured to use vNext
  bool get hasVNextWorkflows {
    if (defaultWorkflowConfig.isVNext) {
      return true;
    }
    return workflowConfigs.values.any((config) => config.isVNext);
  }

  /// Get all workflow names configured for a specific engine
  List<String> getWorkflowsForEngine(String engine) {
    final workflows = <String>[];
    
    for (final entry in workflowConfigs.entries) {
      if (entry.value.engine == engine) {
        workflows.add(entry.key);
      }
    }
    
    return workflows;
  }

  /// Get workflow configuration summary
  Map<String, dynamic> getWorkflowConfigSummary() {
    return WorkflowEngineConfigParser.getConfigSummary(workflowConfigs, defaultWorkflowConfig);
  }

  /// Validate all workflow configurations
  List<String> validateWorkflowConfigs() {
    return WorkflowEngineConfigParser.validateConfigs(workflowConfigs);
  }
}
