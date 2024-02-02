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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class _Constants {
  static const StorageCipherAlgorithm storageCipherAlgorithm = StorageCipherAlgorithm.AES_GCM_NoPadding;
  static const String secureStorageKeyLanguage = "neocore_secure_storage_key_language";
  static const String secureStorageKeyDeviceId = "neocore_secure_storage_key_device_id";
  static const String secureStorageKeyDeviceInfo = "neocore_secure_storage_key_device_info";
  static const String secureStorageKeyTokenId = "neocore_secure_storage_key_token_id";
  static const String secureStorageKeyAuthToken = "neocore_secure_storage_key_auth_token";
  static const String secureStorageKeyRefreshToken = "neocore_secure_storage_key_refresh_token";
  static const String secureStorageKeyCustomerId = "neocore_secure_storage_key_customer_id";
  static const String secureStorageKeyDeviceRegistrationToken = "neocore_secure_storage_key_device_registration_token";
  static const String secureStorageKeyCustomerNameAndSurname = "neocore_secure_storage_key_customer_name_and_surname";

  static const String sharedPreferencesFirstRun = "neocore_shared_preferences_first_run";
}

class NeoCoreSecureStorage {
  static final NeoCoreSecureStorage _singleton = NeoCoreSecureStorage._internal();

  factory NeoCoreSecureStorage() {
    return _singleton;
  }

  NeoCoreSecureStorage._internal();

  FlutterSecureStorage? _storage;
  SharedPreferences? _preferences;

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
    _preferences = await SharedPreferences.getInstance();
    await _checkFirstRun();
    await _setInitialParameters();
  }

  Future _checkFirstRun() async {
    if (_preferences!.getBool(_Constants.sharedPreferencesFirstRun) ?? true) {
      await _storage!.deleteAll();
    }
    await _preferences!.setBool(_Constants.sharedPreferencesFirstRun, false);
  }

  _setInitialParameters() async {
    final deviceUtil = DeviceUtil();
    final deviceId = await deviceUtil.getDeviceId();
    final deviceInfo = await deviceUtil.getDeviceInfo();
    if (!await _storage!.containsKey(key: _Constants.secureStorageKeyDeviceId) && deviceId != null) {
      await _setDeviceId(deviceId);
    }
    if (!await _storage!.containsKey(key: _Constants.secureStorageKeyDeviceInfo) && deviceInfo != null) {
      await _setDeviceInfo(deviceInfo);
    }
    if (!await _storage!.containsKey(key: _Constants.secureStorageKeyTokenId)) {
      await _setTokenId(const Uuid().v1());
    }
  }

  Future setLanguageCode(String languageCode) async {
    return _storage!.write(key: _Constants.secureStorageKeyLanguage, value: languageCode);
  }

  Future<String?> getLanguageCode() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyLanguage)) {
      return _storage!.read(key: _Constants.secureStorageKeyLanguage);
    }
    return null;
  }

  Future _setDeviceId(String deviceId) async {
    await _storage!.write(key: _Constants.secureStorageKeyDeviceId, value: deviceId);
  }

  Future<String?> getDeviceId() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyDeviceId)) {
      return _storage!.read(key: _Constants.secureStorageKeyDeviceId);
    }
    return null;
  }

  Future _setDeviceInfo(String deviceInfo) async {
    await _storage!.write(key: _Constants.secureStorageKeyDeviceInfo, value: deviceInfo);
  }

  Future<String?> getDeviceInfo() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyDeviceInfo)) {
      return _storage!.read(key: _Constants.secureStorageKeyDeviceInfo);
    }
    return null;
  }

  Future _setTokenId(String tokenId) async {
    await _storage!.write(key: _Constants.secureStorageKeyTokenId, value: tokenId);
  }

  Future<String?> getTokenId() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyTokenId)) {
      return _storage!.read(key: _Constants.secureStorageKeyTokenId);
    }
    return null;
  }

  /// Set auth token(JWT), customerId and customerNameAndSurname from encoded JWT
  Future setAuthToken(String token) async {
    await _storage!.write(key: _Constants.secureStorageKeyAuthToken, value: token);
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    final customerId = decodedToken["user.reference"];
    if (customerId is String && customerId.isNotEmpty) {
      await _setCustomerId(customerId);
    }

    final customerName = decodedToken["given_name"];
    final customerSurname = decodedToken["family_name"];
    if (customerName is String && customerName.isNotEmpty && customerSurname is String && customerSurname.isNotEmpty) {
      await _setCustomerNameAndSurname(customerName, customerSurname);
    }
  }

  Future _deleteAuthToken() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyAuthToken)) {
      await _storage!.delete(key: _Constants.secureStorageKeyAuthToken);
    }
  }

  Future<String?> getAuthToken() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyAuthToken)) {
      return _storage!.read(key: _Constants.secureStorageKeyAuthToken);
    }
    return null;
  }

  Future setRefreshToken(String refreshToken) async {
    await _storage!.write(key: _Constants.secureStorageKeyRefreshToken, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyRefreshToken)) {
      return _storage!.read(key: _Constants.secureStorageKeyRefreshToken);
    }
    return null;
  }

  Future _setCustomerId(String customerId) async {
    await _storage!.write(key: _Constants.secureStorageKeyCustomerId, value: customerId);
  }

  Future<String?> getCustomerId() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyCustomerId)) {
      return _storage!.read(key: _Constants.secureStorageKeyCustomerId);
    }
    return null;
  }

  Future _deleteCustomerId() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyCustomerId)) {
      return _storage!.delete(key: _Constants.secureStorageKeyCustomerId);
    }
  }

  Future _deleteRefreshToken() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyRefreshToken)) {
      return _storage!.delete(key: _Constants.secureStorageKeyRefreshToken);
    }
  }

  Future<void> _setCustomerNameAndSurname(String name, String surname) async {
    await _storage?.write(key: _Constants.secureStorageKeyCustomerNameAndSurname, value: "$name $surname");
  }

  Future<String?> getCustomerNameAndSurname() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyCustomerNameAndSurname)) {
      return await _storage?.read(key: _Constants.secureStorageKeyCustomerNameAndSurname);
    }
    return null;
  }

  Future<void> _deleteCustomerNameAndSurname() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyCustomerNameAndSurname)) {
      await _storage?.delete(key: _Constants.secureStorageKeyCustomerNameAndSurname);
    }
  }

  Future deleteTokens() async {
    await _deleteAuthToken();
    await _deleteRefreshToken();
  }

  Future deleteCustomer() async {
    await deleteTokens();
    await _deleteCustomerId();
    await _deleteCustomerNameAndSurname();
  }

  Future setDeviceRegistrationToken({required String registrationToken}) async {
    await _storage!.write(key: _Constants.secureStorageKeyDeviceRegistrationToken, value: registrationToken);
  }

  Future<String?> getDeviceRegistrationToken() async {
    if (await _storage!.containsKey(key: _Constants.secureStorageKeyDeviceRegistrationToken)) {
      return _storage!.read(key: _Constants.secureStorageKeyDeviceRegistrationToken);
    }
    return null;
  }
}
