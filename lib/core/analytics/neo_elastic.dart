import "package:flutter/foundation.dart";
import 'package:neo_core/core/managers/parameter_manager/neo_core_parameter_key.dart';
import "package:neo_core/core/network/managers/neo_network_manager.dart";
import "package:neo_core/core/network/models/neo_http_call.dart";
import "package:neo_core/core/storage/neo_core_secure_storage.dart";
import "package:package_info_plus/package_info_plus.dart";

abstract class _Constants {
  static const endpoint = "elastic";
}

class NeoElastic {
  NeoElastic({required this.neoNetworkManager, required this.secureStorage});

  final NeoNetworkManager neoNetworkManager;
  final NeoCoreSecureStorage secureStorage;

  Future<void> logCustom(dynamic message, String level, {Map<String, dynamic>? parameters}) async {
    final token = await secureStorage.read(NeoCoreParameterKey.secureStorageAuthToken);
    if (token == null || token.isEmpty) {
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final results = await Future.wait([
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
      secureStorage.read(NeoCoreParameterKey.secureStorageInstallationId),
      secureStorage.read(NeoCoreParameterKey.secureStorageCustomerId),
      secureStorage.read(NeoCoreParameterKey.secureStorageUserId),
    ]);

    final deviceId = results[0];
    final tokenId = results[1];
    final customerId = results[2];
    final userId = results[3];

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
      'customerId': customerId,
      'userId': userId,
      if (parameters != null) ...parameters,
    };

    try {
      await neoNetworkManager.call(NeoHttpCall(endpoint: _Constants.endpoint, body: body));
    } catch (e) {
      debugPrint("Failed to log message: $e");
    }
  }
}
