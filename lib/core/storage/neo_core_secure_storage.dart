/*
 * neo_core
 *
 * Created on 3/11/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neo_core/neo_core.dart';
import 'package:uuid/uuid.dart';

class _Constants {
  static const StorageCipherAlgorithm storageCipherAlgorithm = StorageCipherAlgorithm.AES_GCM_NoPadding;
  static const String sharedPrefKeyLanguage = "shared_pref_key_language";
  static const String sharedPrefKeyDeviceId = "shared_pref_key_device_id";
  static const String sharedPrefKeyDeviceInfo = "shared_pref_key_device_info";
  static const String sharedPrefKeyTokenId = "shared_pref_key_token_id";
  static const String sharedPrefKeyAuthToken = "shared_pref_key_auth_token";
  static const String sharedPrefKeyRefreshToken = "shared_pref_key_refresh_token";
}

class NeoCoreSecureStorage {
  NeoCoreSecureStorage._();

  static NeoCoreSecureStorage shared = NeoCoreSecureStorage._();
  static FlutterSecureStorage? _storage;

  static init() async {
    if (_storage != null) {
      return;
    }
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        storageCipherAlgorithm: _Constants.storageCipherAlgorithm,
      ),
    );
    await _setInitialParameters();
  }

  static _setInitialParameters() async {
    final deviceUtil = DeviceUtil();
    final deviceId = await deviceUtil.getDeviceId();
    final deviceInfo = await deviceUtil.getDeviceInfo();
    if (!await _storage!.containsKey(key: _Constants.sharedPrefKeyDeviceId) && deviceId != null) {
      _setDeviceId(deviceId);
    }
    if (!await _storage!.containsKey(key: _Constants.sharedPrefKeyDeviceInfo) && deviceInfo != null) {
      _setDeviceInfo(deviceInfo);
    }
    if (!await _storage!.containsKey(key: _Constants.sharedPrefKeyTokenId)) {
      _setTokenId(const Uuid().v1());
    }
  }

  Future setLanguageCode(String languageCode) async {
    return await _storage!.write(key: _Constants.sharedPrefKeyLanguage, value: languageCode);
  }

  Future<String?> getLanguageCode() async {
    return await _storage!.read(key: _Constants.sharedPrefKeyLanguage);
  }

  static _setDeviceId(String deviceId) async {
    await _storage!.write(key: _Constants.sharedPrefKeyDeviceId, value: deviceId);
  }

  Future<String?> getDeviceId() async {
    return await _storage!.read(key: _Constants.sharedPrefKeyDeviceId);
  }

  static _setDeviceInfo(String deviceInfo) async {
    await _storage!.write(key: _Constants.sharedPrefKeyDeviceInfo, value: deviceInfo);
  }

  Future<String?> getDeviceInfo() async {
    return await _storage!.read(key: _Constants.sharedPrefKeyDeviceInfo);
  }

  static _setTokenId(String tokenId) async {
    await _storage!.write(key: _Constants.sharedPrefKeyTokenId, value: tokenId);
  }

  Future<String?> getTokenId() async {
    return await _storage!.read(key: _Constants.sharedPrefKeyTokenId);
  }

  Future setAuthToken(String token) async {
    await _storage!.write(key: _Constants.sharedPrefKeyAuthToken, value: token);
  }

  Future deleteAuthToken() async {
    if (await _storage!.containsKey(key: _Constants.sharedPrefKeyAuthToken)) {
      return await _storage!.delete(key: _Constants.sharedPrefKeyAuthToken);
    }
  }

  Future<String?> getAuthToken() async {
    return await _storage!.read(key: _Constants.sharedPrefKeyAuthToken);
  }

  Future setRefreshToken(String refreshToken) async {
    await _storage!.write(key: _Constants.sharedPrefKeyRefreshToken, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage!.read(key: _Constants.sharedPrefKeyRefreshToken);
  }
}
