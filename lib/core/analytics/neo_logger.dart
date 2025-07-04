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

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/i_neo_logger.dart';
import 'package:neo_core/core/analytics/models/neo_log.dart';
import 'package:neo_core/core/analytics/neo_adjust.dart';
import 'package:neo_core/core/analytics/neo_crashlytics.dart';
import 'package:neo_core/core/analytics/neo_elastic.dart';
import 'package:neo_core/core/analytics/neo_logger_type.dart';
import 'package:neo_core/core/network/models/http_client_config.dart';
import 'package:neo_core/core/network/models/neo_page_type.dart';
import 'package:neo_core/core/util/device_util/device_util.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';
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
  _LogMessageQueueProcessor? _processor;

  NeoLogger({
    required this.neoAdjust,
    required this.neoElastic,
    required this.httpClientConfig,
  });

  Level get _logLevel => httpClientConfig.config.logLevel;
  final DeviceUtil _deviceUtil = DeviceUtil();

  @override
  List<NavigatorObserver> observers = [];
  final Map<String, DateTime> _timeMap = {};

  static const List<NeoLoggerType> defaultAnalytics = [
    NeoLoggerType.adjust,
    NeoLoggerType.elastic,
    NeoLoggerType.logger,
  ];

  bool _isLoggingEnabled = false;

  NeoCrashlytics? get _neoCrashlytics => GetIt.I.getIfReady<NeoCrashlytics>();

  Future<void> init({bool enableLogging = false}) async {
    _isLoggingEnabled = enableLogging && !Platform.isMacOS && !Platform.isWindows;

    if (!_isLoggingEnabled) {
      return;
    }

    _processor = _LogMessageQueueProcessor(
      neoAdjust: neoAdjust,
      neoElastic: neoElastic,
    );

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
    if (!_isLoggingEnabled) {
      return;
    }

    if (message == null || _logLevel.value > logLevel.value || logLevel == Level.off || logLevel == Level.off) {
      return;
    }

    _processor?.enqueue(
      NeoLog(
        message: message,
        logLevel: logLevel,
        logTypes: logTypes,
        properties: properties,
        options: options,
      ),
    );
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
    logCustom(message, logLevel: Level.error, logTypes: [NeoLoggerType.elastic]);
    if (kIsWeb) {
      return;
    }
    _neoCrashlytics?.logError(message);
  }

  @override
  void logException(dynamic exception, StackTrace stackTrace, {Map<String, dynamic>? parameters}) {
    logCustom(exception, logLevel: Level.fatal, properties: parameters, logTypes: [NeoLoggerType.elastic]);
    if (kIsWeb) {
      return;
    }
    _neoCrashlytics?.logException(exception, stackTrace);
  }

  void logConsole(dynamic message, {Level logLevel = Level.info}) {
    logCustom(message, logLevel: logLevel, logTypes: [NeoLoggerType.logger]);
  }
}

class _LogMessageQueueProcessor {
  static _LogMessageQueueProcessor? _instance;
  final NeoAdjust neoAdjust;
  final NeoElastic neoElastic;

  static const _processingInterval = Duration(milliseconds: 100);
  final _messageQueue = <NeoLog>[];

  bool _isProcessing = false;

  _LogMessageQueueProcessor._({
    required this.neoAdjust,
    required this.neoElastic,
  });

  factory _LogMessageQueueProcessor({
    required NeoAdjust neoAdjust,
    required NeoElastic neoElastic,
  }) {
    _instance ??= _LogMessageQueueProcessor._(
      neoAdjust: neoAdjust,
      neoElastic: neoElastic,
    );
    return _instance!;
  }

  final _logger = Logger(printer: _NeoLoggerPrinter(), output: _NeoLoggerOutput());

  void enqueue(NeoLog message) {
    _messageQueue.add(message);
    _processQueueIfNeeded();
  }

  Future<void> _processQueueIfNeeded() async {
    if (!_isProcessing && _messageQueue.isNotEmpty) {
      await _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isProcessing = true;
    final pendingMessages = List<NeoLog>.from(_messageQueue);
    _messageQueue.clear();

    await Future.forEach<NeoLog>(pendingMessages, (logMessage) async {
      try {
        if (logMessage.logTypes.contains(NeoLoggerType.logger)) {
          _logger.log(logMessage.logLevel, logMessage.message);
        }

        if (logMessage.logTypes.contains(NeoLoggerType.elastic)) {
          unawaited(
            neoElastic.logCustom(logMessage.message, logMessage.logLevel.name, parameters: logMessage.properties),
          );
        }
        if (logMessage.logTypes.contains(NeoLoggerType.adjust) && logMessage.message is String) {
          neoAdjust.logEvent(logMessage.message);
        }
      } catch (e) {
        _logger.e('Failed to process log message: $e');
      }
    });

    _isProcessing = false;

    // Check if new messages arrived while processing
    if (_messageQueue.isNotEmpty) {
      await Future.delayed(_processingInterval);
      await _processQueueIfNeeded();
    }
  }
}
