/*
 * 
 * flutter.core
 * 
 * Created on 11/12/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 * 
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 * 
 */

import 'package:neo_core/core/util/neo_crashlytics.dart';
import 'package:neo_core/core/util/neo_posthog.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class NeoLogger {
  NeoLogger._();

  static void setScreen(
    String screenName, {
    Map<String, dynamic>? posthogProperties,
    Map<String, dynamic>? posthogOptions,
  }) {
    NeoPosthog.setScreen(
      screenName,
      properties: posthogProperties,
      options: posthogOptions,
    );
  }

  static void logNavigationEvent(
    String eventName, {
    Map<String, dynamic>? posthogProperties,
    Map<String, dynamic>? posthogOptions,
  }) {
    NeoPosthog.captureEvent(
      eventName,
      properties: posthogProperties,
      options: posthogOptions,
    );
  }

  static Future<bool?> isFeatureEnabled(String key) async {
    return NeoPosthog.isFeatureEnabled(key);
  }

  static Future<void> reloadFeatureFlags() async {
    await NeoPosthog.reloadFeatureFlags();
  }

  static PosthogObserver setPosthogObserver() => PosthogObserver();

  static bool get isEnabled => NeoCrashlytics.isEnabled;

  static void logError(String message) {
    NeoCrashlytics.logError(message);
  }

  static void logException(dynamic exception, StackTrace stackTrace) {
    NeoCrashlytics.logException(exception, stackTrace);
  }

  static Future<void> setCrashlyticsEnabled({required bool enabled}) async {
    await NeoCrashlytics.setEnabled(enabled: enabled);
  }

  static Future<void> sendUnsentReports() async {
    await NeoCrashlytics.sendUnsentReports();
  }
}
