import "package:flutter/foundation.dart";
import "package:get_it/get_it.dart";
import "package:neo_core/core/network/managers/neo_network_manager.dart";
import "package:neo_core/core/network/models/neo_http_call.dart";
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import "package:neo_core/core/storage/neo_core_secure_storage.dart";
import "package:package_info_plus/package_info_plus.dart";

abstract class _Constants {
  static const endpoint = "elastic";
}

class NeoElastic {
  NeoElastic();

  late final NeoNetworkManager _neoNetworkManager = GetIt.I.get<NeoNetworkManager>();

  Future<void> logCustom(dynamic message, String level, {Map<String, dynamic>? parameters}) async {
    final secureStorage = NeoCoreSecureStorage();
    final packageInfo = await PackageInfo.fromPlatform();
    final results = await Future.wait([
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
      secureStorage.read(NeoCoreParameterKey.secureStorageTokenId),
      secureStorage.read(NeoCoreParameterKey.secureStorageCustomerId),
    ]);
    final deviceId = results[0];
    final tokenId = results[1];
    final customerId = results[2];

    // ignore: do_not_use_environment
    const environment = String.fromEnvironment('environment');

    final body = {
      "message": message,
      "level": level,
      "deviceId": deviceId,
      "tokenId": tokenId,
      "customerId": customerId,
      "applicationName": environment,
      'appVersion': packageInfo.version,
      'appBuildNumber': packageInfo.buildNumber,
      if (parameters != null) ...parameters,
    };

    try {
      await _neoNetworkManager.call(NeoHttpCall(endpoint: _Constants.endpoint, body: body));
    } catch (e) {
      debugPrint("Failed to log message: $e");
    }
  }
}
