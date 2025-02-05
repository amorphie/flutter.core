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
import 'package:json_annotation/json_annotation.dart';
import 'package:neo_core/core/network/models/http_client_config_parameters.dart';
import 'package:neo_core/core/network/models/http_host_details.dart';
import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/core/network/models/http_service.dart';

part 'http_client_config.g.dart';

@JsonSerializable(createToJson: false)
class HttpClientConfig {
  @JsonKey(name: 'hosts', defaultValue: [])
  final List<HttpHostDetails> hosts;

  @JsonKey(name: 'config')
  HttpClientConfigParameters _config;

  @JsonKey(name: 'services', defaultValue: [])
  final List<HttpService> services;

  HttpClientConfig({required this.hosts, required HttpClientConfigParameters config, required this.services})
      : _config = config;

  HttpClientConfigParameters get config => _config;

  factory HttpClientConfig.fromJson(Map<String, dynamic> json) => _$HttpClientConfigFromJson(json);

  void updateConfig(HttpClientConfig newConfig) {
    hosts
      ..clear()
      ..addAll(newConfig.hosts);
    _config = newConfig.config;
    services
      ..clear()
      ..addAll(newConfig.services);
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
    final baseUrl = _getBaseUrlByHost(service.host);
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

  String? _getBaseUrlByHost(String host) {
    return hosts.firstWhereOrNull((element) => element.key == host)?.activeHosts.firstOrNull?.host;
  }

  int? _getRetryCountByHost(String host) {
    return hosts.firstWhereOrNull((element) => element.key == host)?.activeHosts.firstOrNull?.retryCount;
  }
}
