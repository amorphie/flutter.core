import 'dart:async';
import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/storage/neo_user_internet_usage_storage.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';

class NeoUserInternetUsageInterceptor {
  final NeoUserInternetUsageStorage? _usageStorage;

  NeoUserInternetUsageInterceptor() : _usageStorage = GetIt.I.getIfReady<NeoUserInternetUsageStorage>();

  NeoLogger? get _neoLogger => GetIt.I.getIfReady<NeoLogger>();

  /// Intercept response and add usage data
  void interceptResponse(
    NeoHttpCall neoCall,
    Response response,
    String endpoint,
  ) {
    if (_usageStorage == null) {
      return;
    }

    try {
      final totalBytes = _calculateTotalBytes(neoCall, response);
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

      unawaited(
        _usageStorage.addUsage(
          bytesUsed: totalBytes,
          isSuccess: isSuccess,
          endpoint: neoCall.endpoint,
        ),
      );
    } catch (e) {
      _neoLogger?.logError("[UserInternetUsageInterceptor]: Failed to intercept response: $e");
    }
  }

  /// Intercept error and add usage data for failed requests
  void interceptError(
    NeoHttpCall neoCall,
    Object error,
    String httpMethod,
  ) {
    if (_usageStorage == null) {
      return;
    }

    try {
      final requestBytes = _calculateRequestBytes(neoCall);

      unawaited(
        _usageStorage.addUsage(
          bytesUsed: requestBytes,
          isSuccess: false,
          endpoint: neoCall.endpoint,
        ),
      );
    } catch (e) {
      _neoLogger?.logError("[UserInternetUsageInterceptor]: Failed to intercept error: $e");
    }
  }

  /// Intercept hub transitions and add usage data
  void interceptTransitions(
    List<Object?> transitions,
    String endpoint,
  ) {
    if (_usageStorage == null) {
      return;
    }

    try {
      final int totalTransitionBytes = _calculateTransitionsBytes(transitions);

      unawaited(
        _usageStorage.addUsage(
          bytesUsed: totalTransitionBytes,
          isSuccess: true,
          endpoint: endpoint,
        ),
      );
    } catch (e) {
      _neoLogger?.logError("[UserInternetUsageInterceptor]: Failed to intercept transitions: $e");
    }
  }

  int _calculateTotalBytes(NeoHttpCall neoCall, Response response) {
    int totalBytes = 0;

    totalBytes += _calculateRequestBytes(neoCall);
    totalBytes += _calculateResponseBytes(response);

    return totalBytes;
  }

  int _calculateRequestBytes(NeoHttpCall neoCall) {
    int size = 0;

    // Calculate URL size
    size += neoCall.endpoint.length;

    // Calculate headers size
    for (final entry in neoCall.headerParameters.entries) {
      size += entry.key.length + entry.value.length + 4; // +4 for ": " and "\r\n"
    }

    // Calculate body size
    if (neoCall.body.isNotEmpty) {
      try {
        final bodyJson = jsonEncode(neoCall.body);
        size += bodyJson.length;
      } catch (e) {
        // If JSON encoding fails, estimate based on object
        size += neoCall.body.toString().length;
      }
    }

    // Calculate query parameters size
    for (final queryProvider in neoCall.queryProviders) {
      for (final entry in queryProvider.queryParameters.entries) {
        size += entry.key.length + entry.value.toString().length + 1; // +1 for "="
      }
    }

    return size;
  }

  int _calculateResponseBytes(Response response) {
    int size = 0;

    // Calculate response body size
    size += response.bodyBytes.length;

    // Calculate headers size
    for (final entry in response.headers.entries) {
      size += entry.key.length + entry.value.length + 4; // +4 for ": " and "\r\n"
    }

    // Add status line size (approximate)
    return size += 20; // "HTTP/1.1 200 OK\r\n"
  }

  int _calculateTransitionsBytes(List<Object?> transitions) {
    final fullJsonString = jsonEncode(transitions);
    final transitionsSize = utf8.encode(fullJsonString).length;

    return transitionsSize;
  }

  Future<void> resetUsage() async {
    await _usageStorage?.resetUsage();
  }
}
