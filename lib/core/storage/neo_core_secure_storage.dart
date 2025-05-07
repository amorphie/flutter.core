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
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/encryption/jwt_decoder.dart';
import 'package:neo_core/core/managers/parameter_manager/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';
import 'package:neo_core/core/util/token_util.dart';
import 'package:neo_core/core/util/uuid_util.dart';
import 'package:neo_core/neo_core.dart';

abstract class _Constants {
  static const StorageCipherAlgorithm storageCipherAlgorithm = StorageCipherAlgorithm.AES_GCM_NoPadding;
}

class NeoCoreSecureStorage {
  final NeoSharedPrefs neoSharedPrefs;
  final HttpClientConfig httpClientConfig;

  NeoCoreSecureStorage({required this.neoSharedPrefs, required this.httpClientConfig});

  // Getter is required, config may change at runtime
  bool get _enableCaching => httpClientConfig.config.cacheStorage;

  FlutterSecureStorage? _storage;

  final Map<String, String?> _cachedValues = {};

  NeoLogger? get _neoLogger => GetIt.I.getIfReady<NeoLogger>();

  Future<void> write({required String key, required String? value}) {
    if (_enableCaching) {
      _cachedValues[key] = value;
    }

    return _storage!.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    if (_enableCaching && _cachedValues.containsKey(key)) {
      return _cachedValues[key];
    } else if (await _storage!.containsKey(key: key)) {
      String? value;
      try {
        value = await _storage!.read(key: key);
      } catch (e) {
        final errorMessage = '[NeoCoreSecureStorage]: Error occurred while reading value of $key';
        _neoLogger?.logConsole(errorMessage, logLevel: Level.error);
      }
      _cachedValues[key] = value;
      return value;
    }

    return null;
  }

  Future<void> delete(String key) {
    if (_enableCaching) {
      _cachedValues.remove(key);
    }

    return _storage!.delete(key: key);
  }

  Future<void> deleteAll() {
    if (_enableCaching) {
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
    // ignore:deprecated_member_use_from_same_package
    final deviceId = await deviceUtil.getDeviceId();
    final deviceInfo = await deviceUtil.getDeviceInfo();
    if (deviceId != null) {
      await write(key: NeoCoreParameterKey.secureStorageDeviceId, value: deviceId);
    }
    if (deviceInfo != null) {
      await write(key: NeoCoreParameterKey.secureStorageDeviceInfo, value: deviceInfo.encode());
    }
    if (!await _storage!.containsKey(key: NeoCoreParameterKey.secureStorageInstallationId)) {
      await write(key: NeoCoreParameterKey.secureStorageInstallationId, value: UuidUtil.generateUUIDWithoutHyphen());
    }
  }

  // endregion

  // region: Custom Operations
  /// Set auth token(JWT), customerId and customerNameAndSurname from encoded JWT
  /// and returns isTwoFactorAuthenticated status
  Future<bool> setAuthToken(String token, {bool? isMobUnapproved}) async {
    await Future.wait(
      [
        write(key: NeoCoreParameterKey.secureStorageAuthToken, value: token),
        _writeIsMobUnapprovedStatus(isMobUnapproved),
      ],
    );

    if (!TokenUtil.is2FAToken(token)) {
      return false;
    }

    final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    final customerId = decodedToken["user.reference"];
    if (customerId is String && customerId.isNotEmpty) {
      await write(key: NeoCoreParameterKey.secureStorageCustomerId, value: customerId);
    }

    final userId = decodedToken["user.id"];
    if (userId is String && userId.isNotEmpty) {
      await write(key: NeoCoreParameterKey.secureStorageUserId, value: userId);
    }

    final customerNo = decodedToken["customer_no"];
    if (customerNo is String && customerNo.isNotEmpty) {
      await write(key: NeoCoreParameterKey.secureStorageCustomerNo, value: customerNo);
    }

    final customerName = decodedToken["given_name"];
    if (customerName is String && customerName.isNotEmpty) {
      await write(
        key: NeoCoreParameterKey.secureStorageCustomerName,
        value: customerName,
      );
    }

    final customerSurname = decodedToken["family_name"];
    if (customerSurname is String && customerSurname.isNotEmpty) {
      await write(
        key: NeoCoreParameterKey.secureStorageCustomerSurname,
        value: customerSurname,
      );
    }

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

    final sessionId = decodedToken["jti"];
    await write(key: NeoCoreParameterKey.secureStorageSessionId, value: sessionId);

    final email = decodedToken["email"];
    if (email is String && email.isNotEmpty) {
      await write(key: NeoCoreParameterKey.secureStorageEmail, value: email);
    }

    return true;
  }

  Future<void> deleteTokensWithRelatedData() {
    return Future.wait([
      delete(NeoCoreParameterKey.secureStorageAuthToken),
      delete(NeoCoreParameterKey.secureStorageRefreshToken),
      delete(NeoCoreParameterKey.secureStorageUserRole),
      delete(NeoCoreParameterKey.secureStorageSessionId),
      delete(NeoCoreParameterKey.secureStorageUserInfoIsMobUnapproved),
    ]);
  }

  Future<void> deleteCustomer() {
    return Future.wait([
      deleteTokensWithRelatedData(),
      delete(NeoCoreParameterKey.secureStorageUserId),
      delete(NeoCoreParameterKey.secureStorageCustomerId),
      delete(NeoCoreParameterKey.secureStorageCustomerNo),
      delete(NeoCoreParameterKey.secureStorageCustomerName),
      delete(NeoCoreParameterKey.secureStorageCustomerSurname),
      delete(NeoCoreParameterKey.secureStorageCustomerNameAndSurname),
      delete(NeoCoreParameterKey.secureStorageCustomerNameAndSurnameUppercase),
      delete(NeoCoreParameterKey.secureStorageBusinessLine),
      delete(NeoCoreParameterKey.secureStoragePhoneNumber),
      delete(NeoCoreParameterKey.secureStorageEmail),
    ]);
  }

  Future<void> _writeIsMobUnapprovedStatus(bool? isMobUnapproved) async {
    if (isMobUnapproved == null) {
      return;
    }
    return write(
      key: NeoCoreParameterKey.secureStorageUserInfoIsMobUnapproved,
      value: isMobUnapproved.toString(),
    );
  }
// endregion
}
