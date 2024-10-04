import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';

abstract class _Constants {
  static const Duration fetchTimeout = Duration(seconds: 60000);
  static const Duration minimumFetchInterval = Duration.zero;
  static const String initializationFailMessage = "[NeoRemoteConfig]: FirebaseRemoteConfig fetchAndActivate failed!";
}

class NeoRemoteConfig {
  NeoRemoteConfig();

  final FirebaseRemoteConfig _firebaseRemoteConfig = FirebaseRemoteConfig.instance;

  NeoLogger get _neoLogger => GetIt.I.get();

  Future<void> init() async {
    await _firebaseRemoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: _Constants.fetchTimeout,
        minimumFetchInterval: _Constants.minimumFetchInterval,
      ),
    );

    final bool isSuccess = await _firebaseRemoteConfig.fetchAndActivate();
    if (!isSuccess) {
      _neoLogger.logError(_Constants.initializationFailMessage);
    }
  }

  Future<void> setDefaults({required Map<String, dynamic> defaultValues}) async {
    await _firebaseRemoteConfig.setDefaults(defaultValues);
  }

  RemoteConfigValue getValue({required String key}) => _firebaseRemoteConfig.getValue(key);
}
