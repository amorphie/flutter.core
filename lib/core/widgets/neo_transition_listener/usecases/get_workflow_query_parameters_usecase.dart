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
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:uuid/uuid.dart';

class GetWorkflowQueryParameters {
  Future<String> call() async {
    final secureStorage = NeoCoreSecureStorage();
    final results = await Future.wait([
      secureStorage.getDeviceId(),
      secureStorage.getTokenId(),
      secureStorage.getAuthToken(),
    ]);

    final deviceId = results[0] ?? "";
    final tokenId = results[1] ?? "";
    final authToken = results[2] ?? "";

    return "?${NeoNetworkHeaderKey.deviceId}=$deviceId&"
        "${NeoNetworkHeaderKey.tokenId}=$tokenId&"
        "${NeoNetworkHeaderKey.requestId}=${const Uuid().v1()}&"
        "${NeoNetworkHeaderKey.accessToken}=$authToken";
  }
}
