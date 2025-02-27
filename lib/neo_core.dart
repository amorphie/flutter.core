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

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:neo_core/core/util/device_util/device_util.dart';
import 'package:universal_io/io.dart';

export 'core/bus/neo_bus.dart';
export 'core/network/neo_network.dart';
export 'core/storage/neo_storage.dart';
export 'core/util/device_util/device_util.dart';
export 'core/util/package_util.dart';
export 'core/widgets/neo_widgets.dart';

class NeoCore {
  NeoCore._();

  static Future init({String? androidId}) async {
    if (!kIsWeb && !Platform.isMacOS) {
      await Firebase.initializeApp();
    }
    if (androidId != null) {
      DeviceUtil.setAndroidId(androidId);
    }
  }
}
