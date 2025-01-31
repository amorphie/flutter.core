import 'package:meta/meta.dart';
import 'package:neo_core/core/isolates/isolate_data.dart';

@visibleForTesting
Future<R> executeIsolatedPlatform<R>(Function(IsolateData) function, IsolateData params) {
  return function(params);
}
