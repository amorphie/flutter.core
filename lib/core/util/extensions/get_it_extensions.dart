import 'package:get_it/get_it.dart';

extension GetItExtension on GetIt {
  T? getIfReady<T extends Object>({String? instanceName}) {
    final hasRegistration = isRegistered<T>(instanceName: instanceName);
    final isReady = isReadySync<T>(instanceName: instanceName);
    return (hasRegistration && isReady) ? get<T>(instanceName: instanceName) : null;
  }
}
