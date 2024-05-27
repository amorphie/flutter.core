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

import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/i_neo_logger.dart';
import 'package:neo_core/core/analytics/neo_crashlytics.dart';
import 'package:neo_core/core/analytics/neo_elastic.dart';
import 'package:neo_core/core/analytics/neo_posthog.dart';
import 'package:neo_core/core/network/models/neo_page_type.dart';
import 'package:neo_core/core/util/device_util/device_util.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:universal_io/io.dart';

abstract class _Constants {
  static const criticalBuildingDurationInMilliseconds = 1000;
}

class NeoLogger implements INeoLogger {
  static final NeoLogger _instance = NeoLogger._internal();

  @override
  List<NavigatorObserver> observers = [];
  final Map<String, DateTime> _timeMap = {};

  NeoCrashlytics? _neoCrashlytics;
  final DeviceUtil _deviceUtil = DeviceUtil();
  final NeoPosthog _neoPosthog = NeoPosthog();
  final NeoElastic _neoElastic = NeoElastic();
  final Logger _logger = Logger(
    printer: PrettyPrinter(printTime: true),
  );

  factory NeoLogger() {
    return _instance;
  }

  NeoLogger._internal();

  Future<void> init({bool enableCrashlytics = false, bool enablePosthog = false, bool enableChucker = false}) async {
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

    if (enableChucker) {
      ChuckerFlutter.showOnRelease = enableChucker;
      ChuckerFlutter.showNotification = false;
      observers.add(ChuckerFlutter.navigatorObserver);
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
  void logPageBuildStartingTime(String pageId, NeoPageType pageType) {
    final startTime = DateTime.now();
    _timeMap[pageId] = startTime;
  }

  @override
  Future<void> logPageBuildSuccessTime(String pageId, NeoPageType pageType) async {
    final endTime = DateTime.now();
    final startTime = _timeMap.remove(pageId);
    final duration = startTime != null ? endTime.difference(startTime).inMilliseconds : null;
    final message =
        '[Building Time]: $pageId - ${pageType.type} is built successfully.${duration != null ? ' Duration: ${duration}ms' : ''}';

    final platform = _deviceUtil.getPlatformName();
    final device = await _deviceUtil.getDeviceInfo();

    final parameters = {
      'pageId': pageId,
      'pageType': pageType.type,
      'duration': duration,
      'device_model': device?.model,
      'device_version': device?.version,
      'platform': platform,
    };

    if (duration != null && duration.compareTo(_Constants.criticalBuildingDurationInMilliseconds) >= 0) {
      logCustom(message, Level.warning, parameters: parameters);
    } else {
      logCustom(message, Level.trace, parameters: parameters);
    }
  }

  @override
  void logCustom(dynamic message, Level logLevel, {Map<String, dynamic>? parameters}) {
    _logger.log(logLevel, message);
    _neoElastic.logCustom(message, logLevel.name, parameters: parameters);
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
