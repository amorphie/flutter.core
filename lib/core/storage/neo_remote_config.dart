import 'package:firebase_remote_config/firebase_remote_config.dart';

abstract class _Constants {
  static const Duration fetchTimeout = Duration(minutes: 1);
  static const Duration minimumFetchInterval = Duration(minutes: 1);
}

class NeoRemoteConfig {
  NeoRemoteConfig();

  final FirebaseRemoteConfig _firebaseRemoteConfig = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    await _firebaseRemoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: _Constants.fetchTimeout,
        minimumFetchInterval: _Constants.minimumFetchInterval,
      ),
    );
    await _firebaseRemoteConfig.fetchAndActivate();
  }

  Future<void> setDefaults({required Map<String, dynamic> defaultValues}) async {
    await _firebaseRemoteConfig.setDefaults(defaultValues);
  }

  RemoteConfigValue getValue({required String key}) => _firebaseRemoteConfig.getValue(key);
}
