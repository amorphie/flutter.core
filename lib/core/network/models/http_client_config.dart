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
import 'package:neo_core/core/network/models/http_client_config_parameters.dart';
import 'package:neo_core/core/network/models/http_host_details.dart';
import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/core/network/models/http_service.dart';
import 'package:neo_core/core/network/models/mtls_enabled_transition.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';

class HttpClientConfig {
  final List<HttpHostDetails> hosts;
  final List<HttpService> services;
  final List<MtlsEnabledTransition> mtlsEnabledTransitions;

  HttpClientConfigParameters _config;

  HttpClientConfig({
    required this.hosts,
    required HttpClientConfigParameters config,
    required this.services,
    this.mtlsEnabledTransitions = const [],
  }) : _config = config;

  HttpClientConfigParameters get config => _config;

  HttpClientConfig copyWith({
    List<HttpHostDetails>? hosts,
    HttpClientConfigParameters? config,
    List<HttpService>? services,
    List<MtlsEnabledTransition>? mtlsEnabledTransitions,
  }) {
    return HttpClientConfig(
      hosts: hosts ?? this.hosts,
      config: config ?? this.config,
      services: services ?? this.services,
      mtlsEnabledTransitions: mtlsEnabledTransitions ?? this.mtlsEnabledTransitions,
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
  }

  HttpMethod? getServiceMethodByKey(String key) {
    return _findServiceByKey(key)?.method;
  }

  String? getServiceUrlByKey(String key, {Map<String, String>? parameters, bool useHttps = true}) {
    final prefix = useHttps ? "https://" : "http://";
    final service = _findServiceByKey(key);
    if (service == null) {
      return null;
    }
    final isMtlsEnabledTransition = service.key == NeoWorkflowManager.endpointPostTransition &&
        (mtlsEnabledTransitions
                .firstWhereOrNull(
                  (transition) =>
                      transition.transitionName == parameters?[NeoWorkflowManager.pathParameterTransitionName],
                )
                ?.config
                .mtls ??
            false);
    final enableMtls = isMtlsEnabledTransition || service.enableMtls;
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

  String? _getBaseUrlByHost(String host, bool mtlsEnabled) {
    final activeHost = hosts.firstWhereOrNull((element) => element.key == host)?.activeHosts.firstOrNull;
    return mtlsEnabled ? activeHost?.mtlsHost : activeHost?.host;
  }

  int? _getRetryCountByHost(String host) {
    return hosts.firstWhereOrNull((element) => element.key == host)?.activeHosts.firstOrNull?.retryCount;
  }
}
