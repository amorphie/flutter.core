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

import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/i_neo_logger.dart';
import 'package:neo_core/core/analytics/neo_adjust.dart';
import 'package:neo_core/core/analytics/neo_crashlytics.dart';
import 'package:neo_core/core/analytics/neo_elastic.dart';
import 'package:neo_core/core/analytics/neo_logger_type.dart';
import 'package:neo_core/core/network/models/http_client_config.dart';
import 'package:neo_core/core/network/models/neo_page_type.dart';
import 'package:neo_core/core/util/device_util/device_util.dart';
import 'package:universal_io/io.dart';

abstract class _Constants {
  static const criticalBuildingDurationInMilliseconds = 1000;
  static const eventNameAdjustInitSucceed = "[NeoAdjust]: init is succeed!";
}

class _NeoLoggerPrinter extends PrettyPrinter {
  _NeoLoggerPrinter() : super(printTime: true, methodCount: 0, noBoxingByDefault: true, printEmojis: false);
}

class _NeoLoggerOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    log(event.lines.join("\n"));
  }
}

class NeoLogger implements INeoLogger {
  final NeoAdjust neoAdjust;
  final NeoElastic neoElastic;
  final HttpClientConfig httpClientConfig;

  NeoLogger({
    required this.neoAdjust,
    required this.neoElastic,
    required this.httpClientConfig,
  });

  // Getter is required, config may change at runtime
  Level get _logLevel => httpClientConfig.config.logLevel;

  final DeviceUtil _deviceUtil = DeviceUtil();

  final Logger _logger = Logger(printer: _NeoLoggerPrinter(), output: _NeoLoggerOutput());

  late final NeoCrashlytics _neoCrashlytics = NeoCrashlytics();

  @override
  List<NavigatorObserver> observers = [];
  final Map<String, DateTime> _timeMap = {};

  static const List<NeoLoggerType> defaultAnalytics = [
    NeoLoggerType.adjust,
    NeoLoggerType.elastic,
    NeoLoggerType.logger,
  ];

  Future<void> init({bool enableLogging = false}) async {
    if (!enableLogging || Platform.isMacOS || Platform.isWindows) {
      return;
    }
    if (!kIsWeb) {
      await _neoCrashlytics.initializeCrashlytics();
      await _neoCrashlytics.setEnabled(enabled: true);
      await _neoCrashlytics.setUserIdentifier();
    }

    logCustom(
      _Constants.eventNameAdjustInitSucceed,
      logTypes: [NeoLoggerType.logger],
    );
  }

  @override
  void logCustom(
    dynamic message, {
    Level logLevel = Level.info,
    List<NeoLoggerType> logTypes = defaultAnalytics,
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  }) {
    // ignore: deprecated_member_use
    if (_logLevel.value > logLevel.value || logLevel == Level.off || logLevel == Level.nothing) {
      return;
    }
    if (logTypes.contains(NeoLoggerType.logger)) {
      _logger.log(logLevel, message);
    }
    if (logTypes.contains(NeoLoggerType.elastic)) {
      neoElastic.logCustom(message, logLevel.name, parameters: properties);
    }
    if (logTypes.contains(NeoLoggerType.adjust)) {
      final String? eventId = message;
      if (eventId != null) {
        neoAdjust.logEvent(eventId);
      }
    }
  }

  @override
  void logScreenEvent(String screenName, {Map<String, dynamic>? properties, Map<String, dynamic>? options}) {}

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
      logCustom(
        message,
        logLevel: Level.warning,
        properties: parameters,
        logTypes: [NeoLoggerType.logger, NeoLoggerType.elastic],
      );
    } else {
      logCustom(
        message,
        logLevel: Level.trace,
        properties: parameters,
        logTypes: [NeoLoggerType.logger, NeoLoggerType.elastic],
      );
    }
  }

  @override
  void logError(String message) {
    if (kIsWeb) {
      return;
    }
    _neoCrashlytics.logError(message);
    logCustom(message, logLevel: Level.error, logTypes: [NeoLoggerType.elastic]);
  }

  @override
  void logException(dynamic exception, StackTrace stackTrace, {Map<String, dynamic>? parameters}) {
    if (kIsWeb) {
      return;
    }
    _neoCrashlytics.logException(exception, stackTrace);
    logCustom(exception, logLevel: Level.fatal, properties: parameters, logTypes: [NeoLoggerType.elastic]);
  }

  @override
  Future<void> sendUnsentReports() async {
    if (kIsWeb) {
      return;
    }
    await _neoCrashlytics.sendUnsentReports();
  }

  void logConsole(dynamic message, {Level logLevel = Level.info}) {
    logCustom(message, logLevel: logLevel, logTypes: [NeoLoggerType.logger]);
  }
}
