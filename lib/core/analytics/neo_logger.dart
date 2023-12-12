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

import 'package:flutter/material.dart';
import 'package:neo_core/core/analytics/i_neo_logger.dart';
import 'package:neo_core/core/analytics/neo_crashlytics.dart';
import 'package:neo_core/core/analytics/neo_posthog.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class NeoLogger implements INeoLogger {
  static bool _isCrashlyticsEnabled = false;
  static bool _isPosthogEnabled = false;

  static void init({bool enableCrashlytics = true, bool enablePosthog = true}) {
    _isCrashlyticsEnabled = enableCrashlytics;
    _isPosthogEnabled = enablePosthog;

    if (_isCrashlyticsEnabled) {
      NeoCrashlytics.initializeCrashlytics();
    }
  }

  @override
  List<NavigatorObserver> setObserver() => _isPosthogEnabled ? [PosthogObserver()] : [];

  @override
  void logScreenEvent(String screenName, {Map<String, dynamic>? properties, Map<String, dynamic>? options}) {
    if (_isPosthogEnabled) {
      NeoPosthog.setScreen(screenName, properties: properties, options: options);
    }
  }

  @override
  void logNavigationEvent(String eventName, {Map<String, dynamic>? properties, Map<String, dynamic>? options}) {
    if (_isPosthogEnabled) {
      NeoPosthog.logEvent(eventName, properties: properties, options: options);
    }
  }

  @override
  Future<bool?> isFeatureEnabled(String key) async {
    return _isPosthogEnabled ? NeoPosthog.isFeatureEnabled(key) : null;
  }

  @override
  Future<void> reloadFeatureFlags() async {
    if (_isPosthogEnabled) {
      await NeoPosthog.reloadFeatureFlags();
    }
  }

  @override
  bool get isCrashlyticsCollectionEnabled => _isCrashlyticsEnabled && NeoCrashlytics.isCrashlyticsCollectionEnabled;

  @override
  void logError(String message) {
    if (_isCrashlyticsEnabled) {
      NeoCrashlytics.logError(message);
    }
  }

  @override
  void logException(dynamic exception, StackTrace stackTrace) {
    if (_isCrashlyticsEnabled) {
      NeoCrashlytics.logException(exception, stackTrace);
    }
  }

  @override
  Future<void> setEnabled({required bool enabled}) async {
    if (_isCrashlyticsEnabled) {
      await NeoCrashlytics.setEnabled(enabled: enabled);
    }
  }

  @override
  Future<void> sendUnsentReports() async {
    if (_isCrashlyticsEnabled) {
      await NeoCrashlytics.sendUnsentReports();
    }
  }
}
