import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  Future<String?> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      final webBrowserInfo = await deviceInfo.webBrowserInfo;
      return webBrowserInfo.platform;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.utsname.machine;
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
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
