/*
 * 
 * neo_core
 * 
 * Created on 04/12/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 * 
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 * 
 */

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show FlutterError, PlatformDispatcher;
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';

class NeoCrashlytics {
  NeoCrashlytics();

  NeoCoreSecureStorage get _neoCoreSecureStorage => GetIt.I.get();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> initializeCrashlytics() async {
    FlutterError.onError = _crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
    await sendUnsentReports();
  }

  bool get isCrashlyticsCollectionEnabled {
    return _crashlytics.isCrashlyticsCollectionEnabled;
  }

  Future<void> logError(String message) async {
    await _crashlytics.log(message);
  }

  Future<void> logException(dynamic exception, StackTrace stackTrace) async {
    await _crashlytics.recordError(exception, stackTrace);
  }

  Future<void> setUserIdentifier() async {
    final userId = await _neoCoreSecureStorage.read(NeoCoreParameterKey.secureStorageUserId);
    if (userId == null) {
      return;
    }

    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> setEnabled({required bool enabled}) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  Future<void> sendUnsentReports() async {
    await _crashlytics.sendUnsentReports();
  }
}
