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
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/i_neo_logger.dart';
import 'package:neo_core/core/analytics/neo_adjust/neo_adjust.dart';
import 'package:neo_core/core/analytics/neo_crashlytics.dart';
import 'package:neo_core/core/analytics/neo_elastic.dart';
import 'package:neo_core/core/analytics/neo_posthog.dart';
import 'package:neo_core/core/network/models/neo_page_type.dart';
import 'package:neo_core/core/util/device_util/device_util.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:universal_io/io.dart';

abstract class _Constants {
  static const criticalBuildingDurationInMilliseconds = 1000;
  static const eventNameAdjustInitSucceed = "[NeoAdjust]: init is succeed!";
  static const eventNameAdjustInitFailed = "[NeoAdjust]: init is failed!";
}

enum NeoAnalytics {
  adjust,
  posthog,
  elastic,
  logger,
}

class NeoLogger implements INeoLogger {
  static final NeoLogger _instance = NeoLogger._internal();

  @override
  List<NavigatorObserver> observers = [];
  final Map<String, DateTime> _timeMap = {};

  NeoCrashlytics? _neoCrashlytics;

  final DeviceUtil _deviceUtil = DeviceUtil();
  final NeoPosthog _neoPosthog = NeoPosthog();
  final NeoAdjust _neoAdjust = NeoAdjust();
  final NeoElastic _neoElastic = NeoElastic();
  final Logger _logger = Logger(
    printer: PrettyPrinter(printTime: true),
  );

  factory NeoLogger() => _instance;
  NeoLogger._internal();

  static const List<NeoAnalytics> defaultAnalytics = [
    NeoAnalytics.adjust,
    NeoAnalytics.posthog,
    NeoAnalytics.elastic,
    NeoAnalytics.logger,
  ];

  Future<void> init({required String? adjustAppToken, bool enableLogging = false}) async {
    if (!enableLogging || Platform.isMacOS || Platform.isWindows) {
      return;
    }
    if (!kIsWeb) {
      _neoCrashlytics = NeoCrashlytics();
      await _neoCrashlytics?.initializeCrashlytics();
      await _neoCrashlytics?.setEnabled(enabled: true);
    }
    if (adjustAppToken != null) {
      try {
        await _neoAdjust.init(appToken: adjustAppToken);
        logCustom(
          _Constants.eventNameAdjustInitSucceed,
          logTypes: [NeoAnalytics.posthog, NeoAnalytics.logger],
        );
      } on Exception catch (e, stacktrace) {
        logException("${_Constants.eventNameAdjustInitFailed} $e", stacktrace);
      }
    }
    observers = [PosthogObserver()];
    await _neoPosthog.setEnabled(enabled: true);
  }

  @override
  void logCustom(
    dynamic message, {
    Level logLevel = Level.info,
    List<NeoAnalytics> logTypes = defaultAnalytics,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  }) {
    if (logTypes.contains(NeoAnalytics.logger)) {
      _logger.log(logLevel, message);
    }
    if (logTypes.contains(NeoAnalytics.elastic)) {
      _neoElastic.logCustom(message, logLevel.name, parameters: properties);
    }
    if (logTypes.contains(NeoAnalytics.posthog)) {
      _neoPosthog.logEvent(message, properties: properties, options: options);
    }
    if (logTypes.contains(NeoAnalytics.adjust)) {
      final String? eventId = message;
      if (eventId != null) {
        _neoAdjust.logEvent(eventId);
      }
    }
  }

  @override
  void logScreenEvent(String screenName, {Map<String, dynamic>? properties, Map<String, dynamic>? options}) {
    _neoPosthog.setScreen(screenName, properties: properties, options: options);
  }

  @override
  void setPageBuildStartingTime(String pageId, NeoPageType pageType) {
    final startTime = DateTime.now();
    _timeMap[pageId] = startTime;
  }

  @override
  Future<void> logPageBuildSuccessTime(String pageId, NeoPageType pageType) async {
    final endTime = DateTime.now();
    final startTime = _timeMap.remove(pageId);
    final duration = startTime != null ? endTime.difference(startTime).inMilliseconds : null;
    final message =
        '[Building Time]:$pageId - ${pageType.type}is built successfully.${duration != null ? ' Duration: ${duration}ms' : ''}';
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
      logCustom(
        message,
        logLevel: Level.warning,
        properties: parameters,
        logTypes: [NeoAnalytics.logger, NeoAnalytics.elastic],
      );
    } else {
      logCustom(
        message,
        logLevel: Level.trace,
        properties: parameters,
        logTypes: [NeoAnalytics.logger, NeoAnalytics.elastic],
      );
    }
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
    logCustom(message, logLevel: Level.error, logTypes: [NeoAnalytics.elastic]);
  }

  @override
  void logException(dynamic exception, StackTrace stackTrace, {Map<String, dynamic>? parameters}) {
    if (kIsWeb) {
      return;
    }
    _neoCrashlytics?.logException(exception, stackTrace);
    logCustom(exception, logLevel: Level.fatal, properties: parameters, logTypes: [NeoAnalytics.elastic]);
  }

  @override
  Future<void> sendUnsentReports() async {
    if (kIsWeb) {
      return;
    }
    await _neoCrashlytics?.sendUnsentReports();
  }
}
