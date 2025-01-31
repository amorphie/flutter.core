// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter/foundation.dart';
import 'package:neo_core/core/isolates/execute_isolated_stub.dart'
    if (dart.library.html) 'execute_isolated_web.dart'
    if (dart.library.io) 'execute_isolated_io.dart';
import 'package:neo_core/core/isolates/isolate_data.dart';

Future<R> executeIsolated<R>(Function(IsolateData) function, IsolateData params) async {
  return compute(
    (message) => executeIsolatedPlatform<R>(function, message),
    params,
  );
}
