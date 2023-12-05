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

class NeoCrashlytics {
  NeoCrashlytics._();

  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  static bool get isEnabled => _crashlytics.isCrashlyticsCollectionEnabled;

  static Future<void> logError(String message) async {
    await _crashlytics.log(message);
  }

  static Future<void> logException(dynamic exception, StackTrace stackTrace) async {
    await _crashlytics.recordError(exception, stackTrace);
  }

  static Future<void> setEnabled({required bool enabled}) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  static Future<void> sendUnsentReports() async {
    await _crashlytics.sendUnsentReports();
  }
}