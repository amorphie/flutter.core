import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/neo_logger_type.dart';

class NeoLog {
  final dynamic message;
  final Level logLevel;
  final List<NeoLoggerType> logTypes;
  final Map<String, dynamic>? properties;
  final Map<String, dynamic>? options;

  const NeoLog({
    required this.message,
    required this.logLevel,
    required this.logTypes,
    this.properties,
    this.options,
  });
}
