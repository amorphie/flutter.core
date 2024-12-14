import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PackageUtil {
  static PackageInfo? _packageInfo;

  static String? _appVersionWithBuildNumber;

  Future<String> getAppVersionWithBuildNumber() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    debugPrint("DELETE: ${_packageInfo?.version} - ${_packageInfo?.buildNumber}");
    debugPrint("DELETE: ${_packageInfo?.version}+${_packageInfo?.buildNumber}");
    debugPrint("DELETE: $")
    return _appVersionWithBuildNumber ??= '${_packageInfo?.version}+${_packageInfo?.buildNumber}';
  }

  String convertToVersionName(int versionCode) {

    final major = versionCode / 1000000 as int;
    final minor = (versionCode % 1000000) / 10000 as int;
    final patch = (versionCode % 10000) / 100 as int;
    return "$major.$minor.$patch";
  }
}
