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
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/util/device_util.dart';
import 'package:neo_core/feature/device_registration/models/neo_core_register_device_request.dart';

abstract class _Constants {
  static const registerDeviceEndpoint = "register-device";
}

class NeoCoreRegisterDeviceUseCase {
  Future<void> call({required NeoNetworkManager networkManager, required String deviceToken}) async {
    try {
      final secureStorage = NeoCoreSecureStorage();
      final existingToken = await secureStorage.getDeviceRegistrationToken();
      if (deviceToken == existingToken) {
        return;
      }

      final deviceUtil = DeviceUtil();
      final String? deviceId;
      final String? tokenId;
      final String? deviceModel;

      final resultArray = await Future.wait([
        secureStorage.getDeviceId(),
        secureStorage.getTokenId(),
        deviceUtil.getDeviceInfo(),
      ]);
      deviceId = resultArray[0] ?? "";
      tokenId = resultArray[1] ?? "";
      deviceModel = resultArray[2] ?? "";

      final devicePlatform = deviceUtil.getPlatformName();
      await networkManager.call(
        NeoHttpCall(
          endpoint: _Constants.registerDeviceEndpoint,
          body: NeoCoreRegisterDeviceRequest(
            deviceId: deviceId,
            installationId: tokenId,
            deviceToken: deviceToken,
            deviceModel: deviceModel,
            devicePlatform: devicePlatform,
          ).toJson(),
        ),
      );
      await secureStorage.setDeviceRegistrationToken(registrationToken: deviceToken);
    } catch (e) {
      // No-op
    }
  }
}
