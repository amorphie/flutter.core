import 'dart:io';

import 'package:burgan_core/burgan_core.dart';
import 'package:burgan_core/core/network/models/http_client_config.dart';

// STOPSHIP: Update it with real base url
final _baseUrlLocal = Platform.isAndroid ? "http://10.0.2.2:3000" : "http://localhost:3000";

class CoreNetworkManager extends NetworkManager {
  CoreNetworkManager() : super(baseURL: _baseUrlLocal);

  Future<HttpClientConfig?> fetchHttpClientConfig() async {
    try {
      final responseJson = await requestGet('http-client-config');
      return HttpClientConfig.fromJson(responseJson);
    } on Exception catch (_) {
      return null;
    }
  }
}
