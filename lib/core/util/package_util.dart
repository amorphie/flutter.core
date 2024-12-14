import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../analytics/neo_logger.dart';

class PackageUtil {
  static PackageInfo? _packageInfo;

  static String? _appVersionWithBuildNumber;
  late final NeoLogger _neoLogger = GetIt.I.get();
  static const _errMessage = "[PackageUtil]: versionCode cannot be null";

  Future<String> getAppVersionWithBuildNumber() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    debugPrint("DELETE: ${_packageInfo?.version} - ${_packageInfo?.buildNumber}");
    debugPrint("DELETE: ${_packageInfo?.version}+${_packageInfo?.buildNumber}");
    if (Platform.isAndroid) {
      return _getBuildNoFromFormattedVersionCode(_packageInfo?.buildNumber);
    } else {
      return _appVersionWithBuildNumber ??= '${_packageInfo?.version}+${_packageInfo?.buildNumber}';
    }
  }

  String _getBuildNoFromFormattedVersionCode(String? versionCode) {
    if (versionCode == null) {
      _neoLogger.logError(_errMessage);
      throw ArgumentError(_errMessage);
    }
    final vCode = int.parse(versionCode);
    final major = vCode / 1000000 as int;
    final minor = (vCode % 1000000) / 10000 as int;
    final patch = (vCode % 10000) / 100 as int;
    return (vCode - (major + minor + patch)).toString();
  }
}
