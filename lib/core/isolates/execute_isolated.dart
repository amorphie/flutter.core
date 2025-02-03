// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter/foundation.dart';
import 'package:neo_core/core/isolates/execute_isolated_stub.dart'
    if (dart.library.html) 'execute_isolated_web.dart'
    if (dart.library.io) 'execute_isolated_io.dart';
import 'package:neo_core/core/isolates/isolate_data.dart';

/// Executes a function in an isolated environment using the Flutter `compute` function.
///
/// This method is designed to run the provided function in a separate isolate,
/// which is useful for performing CPU-intensive tasks without blocking the main thread.
///
/// [function] parameter is the function to be executed in the isolate. It takes an `IsolateData` object as a parameter.
/// [data] parameter is the data model to be passed to the function, encapsulated in an `IsolateData` object.
/// Returns a `Future` that completes with the result of the function execution.
///
/// R is the type of the result returned by the function.
Future<R> executeIsolated<R>(Function(IsolateData) function, IsolateData data) async {
  return compute(
    (message) => executeIsolatedPlatform<R>(function, message),
    data,
  );
}
