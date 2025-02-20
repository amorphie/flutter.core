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

class NeoCrashlytics {
  final bool enabled;
  NeoCrashlytics({required this.enabled});

  FirebaseCrashlytics? _crashlytics;

  Future<void> init() async {
    if (!enabled) {
      return;
    }

    _crashlytics = FirebaseCrashlytics.instance;

    FlutterError.onError = _crashlytics?.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics?.recordError(error, stack, fatal: true);
      return true;
    };

    /// If automatic data collection is disabled, this method queues up all the
    /// reports on a device to send to Crashlytics. Otherwise, this method is a no-op.
    await _crashlytics?.sendUnsentReports();
    await _crashlytics?.setCrashlyticsCollectionEnabled(true);
  }

  Future<void> logError(String message) async {
    if (!enabled) {
      return;
    }

    await _crashlytics?.log(message);
  }

  Future<void> logException(dynamic exception, StackTrace stackTrace) async {
    if (!enabled) {
      return;
    }

    await _crashlytics?.recordError(exception, stackTrace);
  }

  Future<void> setUserIdentifier(String userId) async {
    if (!enabled) {
      return;
    }

    await _crashlytics?.setUserIdentifier(userId);
  }
}
