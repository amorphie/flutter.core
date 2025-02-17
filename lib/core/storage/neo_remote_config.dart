import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';

abstract class _Constants {
  static const Duration fetchTimeout = Duration(minutes: 1);
  static const Duration minimumFetchInterval = Duration(minutes: 5);
  static const String initializationFailMessage = "[NeoRemoteConfig]: FirebaseRemoteConfig fetchAndActivate failed!";
  static const String setDefaultsFailMessage = "[NeoRemoteConfig]: FirebaseRemoteConfig setDefaults failed!";
}

class NeoRemoteConfig {
  final NeoLogger neoLogger;
  NeoRemoteConfig({required this.neoLogger});

  late final FirebaseRemoteConfig _firebaseRemoteConfig = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    try {
      await _firebaseRemoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: _Constants.fetchTimeout,
          minimumFetchInterval: _Constants.minimumFetchInterval,
        ),
      );

      final bool isSuccess = await _firebaseRemoteConfig.fetchAndActivate();
      if (!isSuccess) {
        neoLogger.logError(_Constants.initializationFailMessage);
      }
    } catch (e) {
      neoLogger.logError("${_Constants.initializationFailMessage} Error: $e");
    }
  }

  Future<void> setDefaults({required Map<String, dynamic> defaultValues}) async {
    try {
      await _firebaseRemoteConfig.setDefaults(defaultValues);
    } catch (e) {
      neoLogger.logError("${_Constants.setDefaultsFailMessage} Error: $e");
    }
  }

  RemoteConfigValue getValue({required String key}) => _firebaseRemoteConfig.getValue(key);
}
