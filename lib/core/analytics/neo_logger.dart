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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:neo_core/core/analytics/i_neo_logger.dart';
import 'package:neo_core/core/analytics/neo_crashlytics.dart';
import 'package:neo_core/core/analytics/neo_posthog.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:universal_io/io.dart';

class NeoLogger implements INeoLogger {
  static final NeoLogger _instance = NeoLogger._internal();

  @override
  List<NavigatorObserver> observers = [];
  NeoCrashlytics? _neoCrashlytics;
  final NeoPosthog _neoPosthog = NeoPosthog();

  factory NeoLogger() {
    return _instance;
  }

  NeoLogger._internal();

  Future<void> init({bool enableCrashlytics = false, bool enablePosthog = false}) async {
    if (Platform.isMacOS || Platform.isWindows) {
      return;
    }
    if (!kIsWeb) {
      if (enableCrashlytics) {
        _neoCrashlytics = NeoCrashlytics();
        await _neoCrashlytics?.initializeCrashlytics();
        await _neoCrashlytics?.setEnabled(enabled: enableCrashlytics);
      }
    }

    if (enablePosthog) {
      observers = [PosthogObserver()];
      await _neoPosthog.setEnabled(enabled: enablePosthog);
    }
  }

  @override
  void logScreenEvent(String screenName, {Map<String, dynamic>? properties, Map<String, dynamic>? options}) {
    _neoPosthog.setScreen(screenName, properties: properties, options: options);
  }

  @override
  void logEvent(String eventName, {Map<String, dynamic>? properties, Map<String, dynamic>? options}) {
    _neoPosthog.logEvent(eventName, properties: properties, options: options);
  }

  @override
  Future<bool?> isFeatureEnabled(String key) async {
    return _neoPosthog.isFeatureEnabled(key);
  }

  @override
  Future<void> reloadFeatureFlags() async {
    await _neoPosthog.reloadFeatureFlags();
  }

  @override
  void logError(String message) {
    if (kIsWeb) {
      return;
    }
    _neoCrashlytics?.logError(message);
  }

  @override
  void logException(dynamic exception, StackTrace stackTrace) {
    if (kIsWeb) {
      return;
    }
    _neoCrashlytics?.logException(exception, stackTrace);
  }

  @override
  Future<void> sendUnsentReports() async {
    if (kIsWeb) {
      return;
    }
    await _neoCrashlytics?.sendUnsentReports();
  }
}
