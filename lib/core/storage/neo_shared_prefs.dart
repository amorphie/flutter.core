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

  Future<SharedPreferences> init() async {
    if (_preferences != null) {
      return _preferences!;
    }
    _preferences = await SharedPreferences.getInstance();
    return _preferences!;
  }

  Object? read(String key) {
    return _preferences!.get(key);
  }

  Future<bool> write(String key, Object value) async {
    bool resultStatus = false;
    try {
      if (value is bool) {
        resultStatus = await _preferences!.setBool(key, value);
      } else if (value is int) {
        resultStatus = await _preferences!.setInt(key, value);
      } else if (value is double) {
        resultStatus = await _preferences!.setDouble(key, value);
      } else if (value is String) {
        resultStatus = await _preferences!.setString(key, value);
      }
    } catch (e) {
      const errorMessage = "[NeoSharedPrefs: Write error]";
      debugPrint(errorMessage);
      NeoLogger().logError(errorMessage);
    }
    return resultStatus;
  }

  Future<bool> delete(String key) {
    return _preferences!.remove(key);
  }

  Future<bool> clear() {
    return _preferences!.clear();
  }
}
