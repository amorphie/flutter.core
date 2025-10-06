import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/storage/neo_user_internet_usage_storage.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';

abstract class _Constants {
  static const String isolateFunctionTypeFieldName = "type";
  static const String isolateAddUsageFunctionName = "add_usage";
  static const String isolateShutdownFunctionName = "shutdown";
  static const String totalBytesUsedFieldName = "totalBytesUsed";
  static const String isSuccessFieldName = "isSuccess";
  static const String endpointFieldName = "endpoint";
}

class NeoUserInternetUsageInterceptor {
  final NeoUserInternetUsageStorage? _usageStorage;

  NeoUserInternetUsageInterceptor() : _usageStorage = GetIt.I.getIfReady<NeoUserInternetUsageStorage>();

  bool _enableLog = false;
  NeoLogger? get _neoLogger => GetIt.I.getIfReady<NeoLogger>();

  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  bool _isIsolateInitialized = false;

  void init({required bool? isEnabled}) {
    _enableLog = isEnabled ?? _enableLog;

    if (_enableLog) {
      _initializeIsolate();
    }
  }

  // Top-level init function for persistent isolate entry point
  Future<void> _isolateEntryPoint(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((data) async {
      try {
        if (data is Map<String, dynamic>) {
          final type = data[_Constants.isolateFunctionTypeFieldName] as String;
          switch (type) {
            case _Constants.isolateAddUsageFunctionName:
              await _usageStorage?.addUsage(
                bytesUsed: data[_Constants.totalBytesUsedFieldName] as int,
                isSuccess: data[_Constants.isSuccessFieldName] as bool,
                endpoint: data[_Constants.endpointFieldName] as String,
              );
              break;
            case _Constants.isolateShutdownFunctionName:
              receivePort.close();
              break;
          }
        }
      } catch (e) {
        // Silent error handling - no response needed
      }
    });
  }

  Future<void> _initializeIsolate() async {
    try {
      _receivePort = ReceivePort();
      _isolate = await Isolate.spawn(_isolateEntryPoint, _receivePort!.sendPort);

      _receivePort!.listen((data) {
        if (data is SendPort) {
          _isIsolateInitialized = true;
          _sendPort = data;
        }
      });
    } catch (e) {
      _neoLogger?.logError("[NeoUserInternetUsageInterceptor]: Failed to initialize isolate: $e");
      _isIsolateInitialized = false;
    }
  }

  void _sendToIsolate(Map<String, dynamic> data) {
    if (_isIsolateInitialized) {
      _sendPort?.send(data);
    } else {
      // Fallback to direct processing if isolate is not ready
      _processDirectly(data);
    }
  }

  void _processDirectly(Map<String, dynamic> data) {
    if (data[_Constants.isolateFunctionTypeFieldName] == _Constants.isolateAddUsageFunctionName) {
      unawaited(
        _usageStorage?.addUsage(
          bytesUsed: data[_Constants.totalBytesUsedFieldName] as int,
          isSuccess: data[_Constants.isSuccessFieldName] as bool,
          endpoint: data[_Constants.endpointFieldName] as String,
        ),
      );
    }
  }

  /// Intercept response and add usage data
  void interceptResponse(
    NeoHttpCall neoCall,
    Response response,
    String endpoint,
  ) {
    if (!_enableLog) {
      return;
    }

    try {
      final totalBytes = _calculateTotalBytes(neoCall, response);
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

      _sendToIsolate({
        _Constants.isolateFunctionTypeFieldName: _Constants.isolateAddUsageFunctionName,
        _Constants.totalBytesUsedFieldName: totalBytes,
        _Constants.isSuccessFieldName: isSuccess,
        _Constants.endpointFieldName: endpoint,
      });
    } catch (e) {
      _neoLogger?.logError("[NeoUserInternetUsageInterceptor]: Failed to intercept response: $e");
    }
  }

  /// Intercept error and add usage data for failed requests
  void interceptError(
    NeoHttpCall neoCall,
    Object error,
    String endpoint,
  ) {
    if (!_enableLog) {
      return;
    }

    try {
      final requestBytes = _calculateRequestBytes(neoCall);

      _sendToIsolate({
        _Constants.isolateFunctionTypeFieldName: _Constants.isolateAddUsageFunctionName,
        _Constants.totalBytesUsedFieldName: requestBytes,
        _Constants.isSuccessFieldName: false,
        _Constants.endpointFieldName: endpoint,
      });
    } catch (e) {
      _neoLogger?.logError("[NeoUserInternetUsageInterceptor]: Failed to intercept error: $e");
    }
  }

  /// Intercept hub transitions and add usage data
  void interceptTransitions(
    List<Object?> transitions,
    String endpoint,
  ) {
    if (!_enableLog) {
      return;
    }

    try {
      final int totalTransitionBytes = _calculateTransitionsBytes(transitions);

      _sendToIsolate({
        _Constants.isolateFunctionTypeFieldName: _Constants.isolateAddUsageFunctionName,
        _Constants.totalBytesUsedFieldName: totalTransitionBytes,
        _Constants.isSuccessFieldName: true,
        _Constants.endpointFieldName: endpoint,
      });
    } catch (e) {
      _neoLogger?.logError("[NeoUserInternetUsageInterceptor]: Failed to intercept transitions: $e");
    }
  }

  /// Intercept network image and add usage data
  void interceptNetworkImage(
    Response response,
    String endpoint,
  ) {
    if (!_enableLog) {
      return;
    }

    try {
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final int totalImageBytes = _calculateResponseBytes(response);

      _sendToIsolate({
        _Constants.isolateFunctionTypeFieldName: _Constants.isolateAddUsageFunctionName,
        _Constants.totalBytesUsedFieldName: totalImageBytes,
        _Constants.isSuccessFieldName: isSuccess,
        _Constants.endpointFieldName: endpoint,
      });
    } catch (e) {
      _neoLogger?.logError("[NeoUserInternetUsageInterceptor]: Failed to intercept network image: $e");
    }
  }

  /// Intercept webview network resources as byte (like images, CSS, JS files, etc.)
  void interceptWebviewDataAsByte(
    Uint8List byte,
    String endpoint, {
    required bool isSuccess,
  }) {
    if (!_enableLog) {
      return;
    }

    try {
      final int totalBytes = byte.lengthInBytes;

      _sendToIsolate({
        _Constants.isolateFunctionTypeFieldName: _Constants.isolateAddUsageFunctionName,
        _Constants.totalBytesUsedFieldName: totalBytes,
        _Constants.isSuccessFieldName: isSuccess,
        _Constants.endpointFieldName: endpoint,
      });
    } catch (e) {
      _neoLogger?.logError("[NeoUserInternetUsageInterceptor]: Failed to intercept webview network data as byte: $e");
    }
  }

  /// Intercept webview network data as string (for URLs or text content)
  void interceptWebviewDataAsString(
    String data,
    String endpoint, {
    required bool isSuccess,
  }) {
    if (!_enableLog) {
      return;
    }

    try {
      final int totalBytes = _calculateStringBytes(data);

      _sendToIsolate({
        _Constants.isolateFunctionTypeFieldName: _Constants.isolateAddUsageFunctionName,
        _Constants.totalBytesUsedFieldName: totalBytes,
        _Constants.isSuccessFieldName: true,
        _Constants.endpointFieldName: endpoint,
      });
    } catch (e) {
      _neoLogger?.logError("[NeoUserInternetUsageInterceptor]: Failed to intercept webview network data as string: $e");
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
    size += _calculateStringBytes(neoCall.endpoint);

    // Calculate headers size
    for (final entry in neoCall.headerParameters.entries) {
      size += _calculateStringBytes(entry.key) + _calculateStringBytes(entry.value) + 4; // +4 for ": " and "\r\n"
    }

    // Calculate body size
    if (neoCall.body.isNotEmpty) {
      try {
        final bodyJson = jsonEncode(neoCall.body);
        size += _calculateStringBytes(bodyJson);
      } catch (e) {
        // If JSON encoding fails, estimate based on object
        size += _calculateStringBytes(neoCall.body.toString());
      }
    }

    // Calculate query parameters size
    for (final queryProvider in neoCall.queryProviders) {
      for (final entry in queryProvider.queryParameters.entries) {
        size += _calculateStringBytes(entry.key) + _calculateStringBytes(entry.value.toString()) + 1; // +1 for "="
      }
    }

    return size;
  }

  int _calculateResponseBytes(Response response) {
    int size = 0;

    // Calculate response body size
    size += response.bodyBytes.lengthInBytes;

    // Calculate headers size
    for (final entry in response.headers.entries) {
      size += _calculateStringBytes(entry.key) + _calculateStringBytes(entry.value) + 4; // +4 for ": " and "\r\n"
    }

    // Add status line size (approximate)
    return size += 20; // "HTTP/1.1 200 OK\r\n"
  }

  int _calculateTransitionsBytes(List<Object?> transitions) {
    final fullJsonString = jsonEncode(transitions);
    final transitionsSize = _calculateStringBytes(fullJsonString);

    return transitionsSize;
  }

  int _calculateStringBytes(String data) => utf8.encode(data).length;

  Future<void> resetUsage() async {
    await _usageStorage?.resetUsage();
  }

  /// Dispose the isolate
  void dispose() {
    if (!_enableLog) {
      return;
    }

    _sendToIsolate({_Constants.isolateFunctionTypeFieldName: _Constants.isolateShutdownFunctionName});
    _receivePort?.close();
    _isolate?.kill();
    _isIsolateInitialized = false;
  }
}
