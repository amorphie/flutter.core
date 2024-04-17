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

import 'package:flutter/cupertino.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NeoSharedPrefs {
  static final NeoSharedPrefs _singleton = NeoSharedPrefs._internal();

  factory NeoSharedPrefs() {
    return _singleton;
  }

  NeoSharedPrefs._internal();

  SharedPreferences? _preferences;

  final Map<String, dynamic> _cachedValues = {};

  Future<SharedPreferences> init() async {
    if (_preferences != null) {
      return _preferences!;
    }
    _preferences = await SharedPreferences.getInstance();
    return _preferences!;
  }

  Object? read(String key) {
    if (_cachedValues.containsKey(key)) {
      return _cachedValues[key];
    }

    final data = _preferences!.get(key);
    _cachedValues[key] = data;

    return data;
  }

  void write(String key, Object value) {
    _cachedValues[key] = value;

    try {
      if (value is bool) {
        _preferences!.setBool(key, value);
      } else if (value is int) {
        _preferences!.setInt(key, value);
      } else if (value is double) {
        _preferences!.setDouble(key, value);
      } else if (value is String) {
        _preferences!.setString(key, value);
      }
    } catch (e) {
      const errorMessage = "[NeoSharedPrefs: Write error]";
      debugPrint(errorMessage);
      NeoLogger().logError(errorMessage);
    }
  }

  void delete(String key) {
    _cachedValues.remove(key);
    _preferences!.remove(key);
  }

  void clear() {
    _cachedValues.clear();
    _preferences!.clear();
  }
}
