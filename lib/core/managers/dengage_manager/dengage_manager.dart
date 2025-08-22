// ignore_for_file: conditional_uri_does_not_exist
import 'package:neo_core/core/managers/dengage_manager/dengage_flutter.dart'
    if (dart.library.io) 'package:dengage_flutter/dengage_flutter.dart';
import 'package:neo_core/usecases/run_platform_code_use_case.dart';

class DengageManager {
  static void setContactKey(String contactKey) {
    const RunPlatformCodeUseCase().call(
      mobile: () => DengageFlutter.setContactKey(contactKey),
    );
  }

  static void setToken(String token) {
    const RunPlatformCodeUseCase().call(
      mobile: () => DengageFlutter.setToken(token),
    );
  }

  static void setNavigationWithName(String page) {
    const RunPlatformCodeUseCase().call(
      mobile: () => DengageFlutter.setNavigationWithName(page),
    );
  }
}
