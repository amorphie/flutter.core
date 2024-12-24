import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_io/io.dart';

class PackageUtil {
  static PackageInfo? _packageInfo;

  static String? _appVersionWithBuildNumber;
  static String? buildNo;
  late final NeoLogger _neoLogger = GetIt.I.get();
  static const _errMessageNull = "[PackageUtil]: Version code cannot be null";
  static const _errMessageNegative = "[PackageUtil]: Version code cannot be negative";

  Future<String> getAppVersionWithBuildNumber() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    if (Platform.isAndroid) {
      buildNo ??= _getBuildNoFromFormattedVersionCode(_packageInfo?.buildNumber);
    } else {
      buildNo ??= _packageInfo?.buildNumber;
    }
    return _appVersionWithBuildNumber ??= '${_packageInfo?.version}+$buildNo';
  }

  String _getBuildNoFromFormattedVersionCode(String? versionCode) {
    if (versionCode == null) {
      _neoLogger.logError(_errMessageNull);
      throw ArgumentError(_errMessageNull);
    }
    final vCode = int.parse(versionCode);
    if (vCode < 0) {
      _neoLogger.logError(_errMessageNegative);
      throw ArgumentError(_errMessageNegative);
    }
    const majorMultiplier = 1000000;
    const minorMultiplier = 10000;
    const patchMultiplier = 100;

    final int major = vCode ~/ majorMultiplier;
    final int minor = (vCode % majorMultiplier) ~/ minorMultiplier;
    final int patch = (vCode % minorMultiplier) ~/ patchMultiplier;
    final int calculatedVersionCode = major * majorMultiplier + minor * minorMultiplier + patch * patchMultiplier;
    return (vCode - calculatedVersionCode).toString();
  }
}
