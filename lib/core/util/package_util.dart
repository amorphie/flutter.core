import 'package:package_info_plus/package_info_plus.dart';

class PackageUtil {
  static PackageInfo? _packageInfo;

  static String? _appVersionWithBuildNumber;

  Future<String> getAppVersionWithBuildNumber() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _appVersionWithBuildNumber ??= '${_packageInfo?.version}+${_packageInfo?.buildNumber}';
  }
}
