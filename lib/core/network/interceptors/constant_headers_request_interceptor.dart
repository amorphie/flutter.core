import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/util/device_util/models/neo_device_info.dart';
import 'package:neo_core/core/util/package_util.dart';

abstract class _Constants {
  static const String headerValueContentType = "application/json";
  static const String languageCodeEn = "en";
}

/// Request interceptor that adds constant headers to every request.
class ConstantHeadersRequestInterceptor extends Interceptor {
  final Map<String, String> defaultHeaders;
  final NeoCoreSecureStorage secureStorage;
  final NeoSharedPrefs neoSharedPrefs;

  static Map<String, String>? _cachedHeaders;

  ConstantHeadersRequestInterceptor({
    required this.defaultHeaders,
    required this.secureStorage,
    required this.neoSharedPrefs,
  });

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers.addAll(_cachedHeaders ??= await _headers);
    handler.next(options);
  }

  Future<Map<String, String>> get _headers async {
    final results = await Future.wait([
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
      secureStorage.read(NeoCoreParameterKey.secureStorageInstallationId),
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceInfo),
      PackageUtil().getAppVersionWithBuildNumber(),
    ]);

    final deviceId = results[0] ?? "";
    final installationId = results[1] ?? "";
    final deviceInfo = results[2] != null ? NeoDeviceInfo.decode(results[2] ?? "") : null;
    final appVersion = results[3] ?? "";

    final userAgentHeader = kIsWeb
        ? <String, String>{}
        : {
            NeoNetworkHeaderKey.userAgent: "${deviceInfo?.platform ?? "-"}/"
                "${defaultHeaders[NeoNetworkHeaderKey.application]}/"
                "$appVersion/"
                "${deviceInfo?.version ?? "-"}/"
                "${deviceInfo?.model ?? "-"}",
          };

    return {
      NeoNetworkHeaderKey.contentType: _Constants.headerValueContentType,
      NeoNetworkHeaderKey.acceptLanguage: _languageCode,
      NeoNetworkHeaderKey.contentLanguage: _languageCode,
      NeoNetworkHeaderKey.applicationVersion: appVersion,
      NeoNetworkHeaderKey.deviceId: deviceId,
      NeoNetworkHeaderKey.installationId: installationId,
      NeoNetworkHeaderKey.tokenId: installationId, // TODO: Delete tokenId after the backend changes are done
      NeoNetworkHeaderKey.deviceInfo: deviceInfo?.model ?? "",
      NeoNetworkHeaderKey.deviceModel: deviceInfo?.model ?? "",
      NeoNetworkHeaderKey.deviceVersion: deviceInfo?.version ?? "",
      NeoNetworkHeaderKey.devicePlatform: deviceInfo?.platform ?? "",
      NeoNetworkHeaderKey.deployment: deviceInfo?.platform ?? "",
    }
      ..addAll(userAgentHeader)
      ..addAll(defaultHeaders);
  }

  String get _languageCode {
    final languageCodeReadResult = neoSharedPrefs.read(NeoCoreParameterKey.sharedPrefsLanguageCode);
    final String languageCode = languageCodeReadResult != null ? languageCodeReadResult as String : "";

    if (languageCode == _Constants.languageCodeEn) {
      return "$languageCode-US";
    } else {
      return '$languageCode-${languageCode.toUpperCase()}';
    }
  }
}
