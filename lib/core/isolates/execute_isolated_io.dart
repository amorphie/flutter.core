import 'package:flutter/services.dart' show BackgroundIsolateBinaryMessenger;
import 'package:meta/meta.dart';
import 'package:neo_core/core/isolates/isolate_data.dart';

@visibleForTesting
Future<R> executeIsolatedPlatform<R>(Function(IsolateData) function, IsolateData params) {
  BackgroundIsolateBinaryMessenger.ensureInitialized(params.token);

  return function(params);
}
