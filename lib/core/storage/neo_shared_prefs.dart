/*
 * neo_core
 *
 * Created on 1/3/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/http_client_config.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NeoSharedPrefs {
  NeoSharedPrefs();

  // Getter is required, config may change at runtime
  bool get _enableCaching => httpClientConfig?.config.cacheStorage ?? false;

  HttpClientConfig? get httpClientConfig => GetIt.I.getIfReady<HttpClientConfig>();
  NeoLogger? get _neoLogger => GetIt.I.getIfReady<NeoLogger>();

  SharedPreferences? _preferences;

  final Map<String, dynamic> _cachedValues = {};

  Future<void> init() async {
    if (_preferences != null) {
      return;
    }
    _preferences = await SharedPreferences.getInstance();
  }

  Object? read(String key) {
    if (_enableCaching && _cachedValues.containsKey(key)) {
      return _cachedValues[key];
    }

    final data = _preferences!.get(key);
    _cachedValues[key] = data;

    return data;
  }

  Future<bool> write(String key, Object value) {
    if (_enableCaching) {
      _cachedValues[key] = value;
    }

    try {
      if (value is bool) {
        return _preferences!.setBool(key, value);
      } else if (value is int) {
        return _preferences!.setInt(key, value);
      } else if (value is double) {
        return _preferences!.setDouble(key, value);
      } else if (value is String) {
        return _preferences!.setString(key, value);
      }

      return Future.value(false);
    } catch (e) {
      const errorMessage = "[NeoSharedPrefs: Write error]";
      _neoLogger?.logConsole(errorMessage, logLevel: Level.error);
      return Future.value(false);
    }
  }

  Future<bool> delete(String key) {
    if (_enableCaching) {
      _cachedValues.remove(key);
    }

    return _preferences!.remove(key);
  }

  Future<bool> clear() {
    if (_enableCaching) {
      _cachedValues.clear();
    }

    return _preferences!.clear();
  }
}
