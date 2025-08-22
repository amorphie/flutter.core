import 'dart:developer';

import 'package:neo_core/core/network/models/http_client_config.dart';

class CachedPageManager {
  const CachedPageManager({required this.httpClientConfig});

  final HttpClientConfig httpClientConfig;

  // Getter is required, config may change at runtime
  bool get _isEnabled => httpClientConfig.config.cachePages;

  static final _cachedPages = <String, Map<String, dynamic>>{};

  void cachePage({
    required String pageId,
    required Map<String, dynamic> componentsMap,
    String? source,
    String? workflowNameSuffix,
  }) {
    if (!_isEnabled) {
      return;
    }

    final pageName = _getPageName(pageId, source, workflowNameSuffix);
    _cachedPages[pageName] = componentsMap;
    log("'$pageName' is cached.", name: "CachedPageManager");
  }

  Map<String, dynamic>? getCachedPage({
    required String pageId,
    String? source,
    String? workflowNameSuffix,
  }) {
    if (!_isEnabled) {
      return null;
    }

    final pageName = _getPageName(pageId, source, workflowNameSuffix);
    final cachedPage = _cachedPages[pageName];

    if (cachedPage != null) {
      log("The cache is being used to retrieve '$pageName'.", name: "CachedPageManager");
    }

    return cachedPage;
  }

  String _getPageName(String pageId, String? source, String? workflowNameSuffix) {
    return "$pageId${source != null ? '-$source' : ''}${workflowNameSuffix != null ? '-$workflowNameSuffix' : ''}";
  }
}
