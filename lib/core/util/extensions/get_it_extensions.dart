import 'package:get_it/get_it.dart';

extension GetItExtension on GetIt {
  T? getIfReady<T extends Object>({String? instanceName}) {
    try {
      final hasRegistration = isRegistered<T>(instanceName: instanceName);
      if (!hasRegistration) {
        return null;
      }
      final isReady = isReadySync<T>(instanceName: instanceName);
      return isReady ? get<T>(instanceName: instanceName) : null;
    } catch (e) {
      // If service is not registered or not ready, return null
      return null;
    }
  }
}
