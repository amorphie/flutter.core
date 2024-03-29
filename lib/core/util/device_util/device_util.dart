/*
 * neo_core
 *
 * Created on 29/3/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:neo_core/core/util/device_util/models/neo_device_info.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';

class DeviceUtil {
  Future<String?> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      return const Uuid().v1();
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else {
      return null;
    }
  }

  Future<NeoDeviceInfo?> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      return const NeoDeviceInfo(model: "", platform: "WEB", version: "");
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return NeoDeviceInfo(model: iosInfo.name, platform: iosInfo.systemName, version: iosInfo.systemVersion);
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return NeoDeviceInfo(model: androidInfo.model, platform: androidInfo.type, version: androidInfo.version.codename);
    } else {
      return null;
    }
  }

  String getPlatformName() {
    if (kIsWeb) {
      return "WEB";
    } else if (Platform.isIOS) {
      return "IOS";
    } else if (Platform.isAndroid) {
      return "ANDROID";
    } else {
      return "UNKNOWN";
    }
  }
}
