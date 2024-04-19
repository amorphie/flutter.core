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

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neo_core/core/encryption/jwt_decoder.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/neo_core.dart';
import 'package:uuid/uuid.dart';

class _Constants {
  static const StorageCipherAlgorithm storageCipherAlgorithm = StorageCipherAlgorithm.AES_GCM_NoPadding;
}

class NeoCoreSecureStorage {
  static final NeoCoreSecureStorage _singleton = NeoCoreSecureStorage._internal();

  factory NeoCoreSecureStorage() {
    return _singleton;
  }

  NeoCoreSecureStorage._internal();

  FlutterSecureStorage? _storage;

  final Map<String, String?> _cachedValues = {};

  void write({required String key, required String? value}) {
    _cachedValues[key] = value;
    unawaited(_storage!.write(key: key, value: value));
  }

  Future<String?> read(String key) async {
    if (_cachedValues.containsKey(key)) {
      return _cachedValues[key];
    } else if (await _storage!.containsKey(key: key)) {
      final value = await _storage!.read(key: key);
      _cachedValues[key] = value;
      return value;
    }

    return null;
  }

  void delete(String key) {
    _cachedValues.remove(key);
    unawaited(_storage!.delete(key: key));
  }

  // region: Initial Settings
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
    _cachedValues.clear();
    await _checkFirstRun();
    await _setInitialParameters();
  }

  Future _checkFirstRun() async {
    final neoSharedPrefs = NeoSharedPrefs();
    final isFirstRun = neoSharedPrefs.read(NeoCoreParameterKey.sharedPrefsFirstRun);

    if (isFirstRun == null || isFirstRun as bool) {
      _cachedValues.clear();
      await _storage!.deleteAll();
    }

    neoSharedPrefs.write(NeoCoreParameterKey.sharedPrefsFirstRun, false);
  }

  _setInitialParameters() async {
    final deviceUtil = DeviceUtil();
    final deviceId = await deviceUtil.getDeviceId();
    final deviceInfo = await deviceUtil.getDeviceInfo();
    if (!await _storage!.containsKey(key: NeoCoreParameterKey.secureStorageDeviceId) && deviceId != null) {
      write(key: NeoCoreParameterKey.secureStorageDeviceId, value: deviceId);
    }
    if (!await _storage!.containsKey(key: NeoCoreParameterKey.secureStorageDeviceInfo) && deviceInfo != null) {
      write(key: NeoCoreParameterKey.secureStorageDeviceInfo, value: deviceInfo.encode());
    }
    if (!await _storage!.containsKey(key: NeoCoreParameterKey.secureStorageTokenId)) {
      write(key: NeoCoreParameterKey.secureStorageTokenId, value: const Uuid().v1());
    }
  }

  // endregion

  // region: Custom Operations
  /// Set auth token(JWT), customerId and customerNameAndSurname from encoded JWT
  Future setAuthToken(String token) async {
    write(key: NeoCoreParameterKey.secureStorageAuthToken, value: token);
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    final customerId = decodedToken["user.reference"];
    if (customerId is String && customerId.isNotEmpty) {
      write(key: NeoCoreParameterKey.secureStorageCustomerId, value: customerId);
    }

    final customerName = decodedToken["given_name"];
    final customerSurname = decodedToken["family_name"];
    if (customerName is String && customerName.isNotEmpty && customerSurname is String && customerSurname.isNotEmpty) {
      write(
        key: NeoCoreParameterKey.secureStorageCustomerNameAndSurname,
        value: "$customerName $customerSurname",
      );
    }

    final customerNameUppercase = decodedToken["uppercase_name"];
    final customerSurnameUppercase = decodedToken["uppercase_surname"];
    if (customerNameUppercase is String &&
        customerNameUppercase.isNotEmpty &&
        customerSurnameUppercase is String &&
        customerSurnameUppercase.isNotEmpty) {
      write(
        key: NeoCoreParameterKey.secureStorageCustomerNameAndSurnameUppercase,
        value: "$customerNameUppercase $customerSurnameUppercase",
      );
    }

    final businessLine = decodedToken["business_line"];
    if (businessLine is String && businessLine.isNotEmpty) {
      write(key: NeoCoreParameterKey.secureStorageBusinessLine, value: businessLine);
    }
  }

  void deleteTokens() {
    delete(NeoCoreParameterKey.secureStorageAuthToken);
    delete(NeoCoreParameterKey.secureStorageRefreshToken);
  }

  void deleteCustomer() {
    deleteTokens();
    delete(NeoCoreParameterKey.secureStorageCustomerId);
    delete(NeoCoreParameterKey.secureStorageCustomerNameAndSurname);
  }
// endregion
}
