// ignore_for_file: cascade_invocations

import 'package:neo_core/core/analytics/neo_logger.dart';

class MockNeoLogger implements NeoLogger {
  final List<String> logs = [];
  
  @override
  void logConsole(dynamic message, {dynamic logLevel}) {
    logs.add('$message');
  }

  @override
  void logError(String message, {Map<String, dynamic>? properties}) {
    logs.add('ERROR: $message');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
