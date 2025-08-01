import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';
import 'package:universal_io/io.dart';

abstract class _Constants {
  static const List<String> nonCriticalErrorMessages = [
    'operation timed out',
    'connection closed while receiving data',
    'network is unreachable',
    'host is unreachable',
    'connection refused',
    'connection timeout',
    'request timeout',
  ];
}

extension HttpExceptionExtensions on HttpException {
  NeoLogger? get _neoLogger => GetIt.I.getIfReady<NeoLogger>();

  bool get isNonCriticalError {
    final message = this.message.toLowerCase();
    _neoLogger?.logCustom("HTTP Exception Handled:\n$message", logLevel: Level.fatal);

    return _Constants.nonCriticalErrorMessages.any(message.contains);
  }
}
