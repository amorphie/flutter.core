/*
 * neo_core
 *
 * Created on 22/9/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/http_client_config.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';

export 'core/bus/neo_bus.dart';
export 'core/network/neo_network.dart';
export 'core/storage/neo_storage.dart';
export 'core/util/neo_util.dart';
export 'core/widgets/neo_widgets.dart';

class NeoCore {
  static init({required HttpClientConfig httpClientConfig}) async {
    await NeoCoreSecureStorage.init();
    NeoNetworkManager.init(httpClientConfig);
  }
}
