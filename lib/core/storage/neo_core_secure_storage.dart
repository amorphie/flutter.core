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
import 'package:neo_core/core/encryption/jwt_decoder.dart';
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
  static const String sharedPrefKeyCustomerId = "shared_pref_key_customer_id";
}

class NeoCoreSecureStorage {
  static final NeoCoreSecureStorage _singleton = NeoCoreSecureStorage._internal();

  factory NeoCoreSecureStorage() {
    return _singleton;
  }

  NeoCoreSecureStorage._internal();

  FlutterSecureStorage? _storage;

  Future init() async {
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

  _setInitialParameters() async {
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
    return _storage!.write(key: _Constants.sharedPrefKeyLanguage, value: languageCode);
  }

  Future<String?> getLanguageCode() async {
    return _storage!.read(key: _Constants.sharedPrefKeyLanguage);
  }

  _setDeviceId(String deviceId) async {
    await _storage!.write(key: _Constants.sharedPrefKeyDeviceId, value: deviceId);
  }

  Future<String?> getDeviceId() async {
    return _storage!.read(key: _Constants.sharedPrefKeyDeviceId);
  }

  _setDeviceInfo(String deviceInfo) async {
    await _storage!.write(key: _Constants.sharedPrefKeyDeviceInfo, value: deviceInfo);
  }

  Future<String?> getDeviceInfo() async {
    return _storage!.read(key: _Constants.sharedPrefKeyDeviceInfo);
  }

  _setTokenId(String tokenId) async {
    await _storage!.write(key: _Constants.sharedPrefKeyTokenId, value: tokenId);
  }

  Future<String?> getTokenId() async {
    return _storage!.read(key: _Constants.sharedPrefKeyTokenId);
  }

  /// Set auth token(JWT) and customerId from encoded JWT
  Future setAuthToken(String token) async {
    await _storage!.write(key: _Constants.sharedPrefKeyAuthToken, value: token);
    final customerId = JwtDecoder.decode(token)["user.reference"];
    if (customerId is String && customerId.isNotEmpty) {
      await _setCustomerId(customerId);
    }
  }

  Future deleteAuthToken() async {
    if (await _storage!.containsKey(key: _Constants.sharedPrefKeyAuthToken)) {
      await _storage!.delete(key: _Constants.sharedPrefKeyAuthToken);
    }
    await _deleteCustomerId();
  }

  Future<String?> getAuthToken() async {
    return _storage!.read(key: _Constants.sharedPrefKeyAuthToken);
  }

  Future setRefreshToken(String refreshToken) async {
    await _storage!.write(key: _Constants.sharedPrefKeyRefreshToken, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return _storage!.read(key: _Constants.sharedPrefKeyRefreshToken);
  }

  Future _setCustomerId(String customerId) async {
    await _storage!.write(key: _Constants.sharedPrefKeyCustomerId, value: customerId);
  }

  Future<String?> getCustomerId() async {
    return _storage!.read(key: _Constants.sharedPrefKeyCustomerId);
  }

  Future _deleteCustomerId() async {
    if (await _storage!.containsKey(key: _Constants.sharedPrefKeyCustomerId)) {
      return _storage!.delete(key: _Constants.sharedPrefKeyCustomerId);
    }
  }

  Future _deleteRefreshToken() async {
    if (await _storage!.containsKey(key: _Constants.sharedPrefKeyRefreshToken)) {
      return _storage!.delete(key: _Constants.sharedPrefKeyRefreshToken);
    }
  }
}
