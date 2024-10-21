import "package:get_it/get_it.dart";
import "package:logger/logger.dart";
import "package:neo_core/core/analytics/neo_logger.dart";
import "package:neo_core/core/network/managers/neo_network_manager.dart";
import "package:neo_core/core/network/models/neo_http_call.dart";
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import "package:neo_core/core/storage/neo_core_secure_storage.dart";
import "package:package_info_plus/package_info_plus.dart";

abstract class _Constants {
  static const endpoint = "elastic";
}

class NeoElastic {
  NeoElastic({required this.neoNetworkManager, required this.secureStorage});

  final NeoNetworkManager neoNetworkManager;
  final NeoCoreSecureStorage secureStorage;

  NeoLogger get _neoLogger => GetIt.I.get();

  Future<void> logCustom(dynamic message, String level, {Map<String, dynamic>? parameters}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final results = await Future.wait([
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
      secureStorage.read(NeoCoreParameterKey.secureStorageInstallationId),
    ]);
    final deviceId = results[0];
    final tokenId = results[1];

    // ignore: do_not_use_environment
    const environment = String.fromEnvironment('environment');

    final body = {
      "message": message,
      "level": level,
      "deviceId": deviceId,
      "tokenId": tokenId,
      "applicationName": environment,
      'appVersion': packageInfo.version,
      'appBuildNumber': packageInfo.buildNumber,
      if (parameters != null) ...parameters,
    };

    try {
      await neoNetworkManager.call(NeoHttpCall(endpoint: _Constants.endpoint, body: body));
    } catch (e) {
      _neoLogger.logConsole("Failed to log message: $e", logLevel: Level.error);
    }
  }
}
