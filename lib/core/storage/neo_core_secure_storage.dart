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

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neo_core/core/encryption/jwt_decoder.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/util/uuid_util.dart';
import 'package:neo_core/neo_core.dart';

abstract class _Constants {
  static const StorageCipherAlgorithm storageCipherAlgorithm = StorageCipherAlgorithm.AES_GCM_NoPadding;
}

class NeoCoreSecureStorage {
  final bool enableCaching;
  final NeoSharedPrefs neoSharedPrefs;

  NeoCoreSecureStorage({required this.neoSharedPrefs, required this.enableCaching});

  FlutterSecureStorage? _storage;

  final Map<String, String?> _cachedValues = {};

  Future<void> write({required String key, required String? value}) {
    if (enableCaching) {
      _cachedValues[key] = value;
    }

    return _storage!.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    if (enableCaching && _cachedValues.containsKey(key)) {
      return _cachedValues[key];
    } else if (await _storage!.containsKey(key: key)) {
      String? value;
      try {
        value = await _storage!.read(key: key);
      } catch (e) {
        final errorMessage = '[NeoCoreSecureStorage]: Error occurred while reading value of $key';
        debugPrint(errorMessage);
      }
      _cachedValues[key] = value;
      return value;
    }

    return null;
  }

  Future<void> delete(String key) {
    if (enableCaching) {
      _cachedValues.remove(key);
    }

    return _storage!.delete(key: key);
  }

  Future<void> deleteAll() {
    if (enableCaching) {
      _cachedValues.clear();
    }

    return _storage!.deleteAll();
  }

  // region: Initial Settings
  Future<void> init() async {
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

  Future<bool> _checkFirstRun() async {
    final isFirstRun = neoSharedPrefs.read(NeoCoreParameterKey.sharedPrefsFirstRun);

    if (isFirstRun == null || isFirstRun as bool) {
      await deleteAll();
    }

    return neoSharedPrefs.write(NeoCoreParameterKey.sharedPrefsFirstRun, false);
  }

  Future<void> _setInitialParameters() async {
    final deviceUtil = DeviceUtil();
    final deviceId = await deviceUtil.getDeviceId();
    final deviceInfo = await deviceUtil.getDeviceInfo();
    if (!await _storage!.containsKey(key: NeoCoreParameterKey.secureStorageDeviceId) && deviceId != null) {
      await write(key: NeoCoreParameterKey.secureStorageDeviceId, value: deviceId);
    }
    if (!await _storage!.containsKey(key: NeoCoreParameterKey.secureStorageDeviceInfo) && deviceInfo != null) {
      await write(key: NeoCoreParameterKey.secureStorageDeviceInfo, value: deviceInfo.encode());
    }
    if (!await _storage!.containsKey(key: NeoCoreParameterKey.secureStorageTokenId)) {
      await write(key: NeoCoreParameterKey.secureStorageTokenId, value: UuidUtil.generateUUID());
    }
  }

  // endregion

  // region: Custom Operations
  /// Set auth token(JWT), customerId and customerNameAndSurname from encoded JWT
  /// and returns isTwoFactorAuthenticated status
  Future<bool> setAuthToken(String token) async {
    await write(key: NeoCoreParameterKey.secureStorageAuthToken, value: token);

    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final isTwoFactorAuthenticated = decodedToken["clientAuthorized"] != "1";
    if (!isTwoFactorAuthenticated) {
      return false;
    }
    final customerId = decodedToken["user.reference"];
    if (customerId is String && customerId.isNotEmpty) {
      await write(key: NeoCoreParameterKey.secureStorageCustomerId, value: customerId);
    }

    final customerName = decodedToken["given_name"];
    final customerSurname = decodedToken["family_name"];
    if (customerName is String && customerName.isNotEmpty && customerSurname is String && customerSurname.isNotEmpty) {
      await write(
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
      await write(
        key: NeoCoreParameterKey.secureStorageCustomerNameAndSurnameUppercase,
        value: "$customerNameUppercase $customerSurnameUppercase",
      );
    }

    final businessLine = decodedToken["business_line"];
    if (businessLine is String && businessLine.isNotEmpty) {
      await write(key: NeoCoreParameterKey.secureStorageBusinessLine, value: businessLine);
    }

    final phoneNumber = decodedToken["phone_number"];
    if (phoneNumber is String && phoneNumber.isNotEmpty) {
      await write(key: NeoCoreParameterKey.secureStoragePhoneNumber, value: phoneNumber);
    }
    final userRole = decodedToken["role"];
    await write(key: NeoCoreParameterKey.secureStorageUserRole, value: userRole);
    return true;
  }

  Future<void> deleteTokens() {
    return Future.wait([
      delete(NeoCoreParameterKey.secureStorageAuthToken),
      delete(NeoCoreParameterKey.secureStorageRefreshToken),
    ]);
  }

  Future<void> deleteCustomer() {
    return Future.wait([
      deleteTokens(),
      delete(NeoCoreParameterKey.secureStorageCustomerId),
      delete(NeoCoreParameterKey.secureStorageCustomerNameAndSurname),
      delete(NeoCoreParameterKey.secureStorageCustomerNameAndSurnameUppercase),
      delete(NeoCoreParameterKey.secureStorageBusinessLine),
      delete(NeoCoreParameterKey.secureStoragePhoneNumber),
    ]);
  }
// endregion
}
