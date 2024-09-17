/*
 * neo_core
 *
 * Created on 7/2/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/util/uuid_util.dart';

class GetWorkflowQueryParametersUseCase {
  Future<String> call(NeoCoreSecureStorage secureStorage) async {
    final results = await Future.wait([
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
      secureStorage.read(NeoCoreParameterKey.secureStorageInstallationId),
      secureStorage.read(NeoCoreParameterKey.secureStorageAuthToken),
    ]);

    final deviceId = results[0] ?? "";
    final installationId = results[1] ?? "";
    final authToken = results[2] ?? "";

    return "?${NeoNetworkHeaderKey.deviceId}=$deviceId&"
        "${NeoNetworkHeaderKey.tokenId}=$installationId&" // TODO: Delete tokenId after the backend changes are done
        "${NeoNetworkHeaderKey.installationId}=$installationId&"
        "${NeoNetworkHeaderKey.requestId}=${UuidUtil.generateUUIDWithoutHypen()}&"
        "${NeoNetworkHeaderKey.accessToken}=$authToken";
  }
}
