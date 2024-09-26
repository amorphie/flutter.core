/*
 * neo_core
 *
 * Created on 15/1/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/util/device_util/device_util.dart';
import 'package:neo_core/core/util/device_util/models/neo_device_info.dart';
import 'package:neo_core/feature/device_registration/models/neo_core_register_device_request.dart';

abstract class _Constants {
  static const registerDeviceEndpoint = "register-device";
}

class NeoCoreRegisterDeviceUseCase {
  Future<void> call({
    required NeoNetworkManager networkManager,
    required NeoCoreSecureStorage secureStorage,
    required String deviceToken,
  }) async {
    try {
      final existingToken = await secureStorage.read(NeoCoreParameterKey.secureStorageDeviceRegistrationToken);
      if (deviceToken == existingToken) {
        return;
      }

      final deviceUtil = DeviceUtil();

      final resultArray = await Future.wait([
        secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
        secureStorage.read(NeoCoreParameterKey.secureStorageInstallationId),
        deviceUtil.getDeviceInfo(),
      ]);
      final deviceId = resultArray[0] as String? ?? "";
      final installationId = resultArray[1] as String? ?? "";
      final deviceInfo = resultArray[2] as NeoDeviceInfo?;

      await Future.wait([
        networkManager.call(
          NeoHttpCall(
            endpoint: _Constants.registerDeviceEndpoint,
            body: NeoCoreRegisterDeviceRequest(
              deviceId: deviceId,
              installationId: installationId,
              deviceToken: deviceToken,
              deviceModel: deviceInfo?.model ?? "",
              devicePlatform: deviceInfo?.platform ?? "",
              deviceVersion: deviceInfo?.version ?? "",
            ).toJson(),
          ),
        ),
        secureStorage.write(key: NeoCoreParameterKey.secureStorageDeviceRegistrationToken, value: deviceToken),
      ]);
    } catch (e) {
      // No-op
    }
  }
}
