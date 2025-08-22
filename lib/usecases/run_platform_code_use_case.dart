import 'dart:io';

import 'package:flutter/foundation.dart';

/// `RunPlatformCodeUseCase` is a utility class that provides a method to execute platform-specific code.
///
/// This class is designed to handle the execution of code based on the platform the application is running on.
/// It provides a `call` method that accepts three optional parameters: `defaultPlatform`, `mobile`, and `web`.
/// Each of these parameters is a function that will be executed depending on the platform.
///
/// Usage:
/// ```dart
/// RunPlatformCodeUseCase().call(
///   defaultPlatform: () {
///     // Code to run on any platform
///   },
///   mobile: () {
///     // Code to run on mobile platforms
///   },
///   web: () {
///     // Code to run on web platform
///   },
/// );
/// ```
///
/// If the application is running on a web platform and the `web` function is provided, it will be executed.
/// If the application is running on a mobile platform and the `mobile` function is provided, it will be executed.
/// If neither `web` nor `mobile` functions are provided or the platform does not match any of these, the `defaultPlatform` function will be executed if provided.
class RunPlatformCodeUseCase {
  const RunPlatformCodeUseCase();

  dynamic call({
    Function? defaultPlatform,
    Function? mobile,
    Function? android,
    Function? ios,
    Function? web,
  }) {
    assert(
      mobile == null || !(android != null || ios != null),
      'Mobile and Android/iOS functions cannot be provided together',
    );

    Function? function;
    if (kIsWeb) {
      function = web;
    } else if (Platform.isAndroid) {
      function = android ?? mobile;
    } else if (Platform.isIOS) {
      function = ios ?? mobile;
    }
    function ??= defaultPlatform;

    return function?.call();
  }
}
