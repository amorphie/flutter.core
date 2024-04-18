/*
 * 
 * flutter.core
 * 
 * Created on 12/12/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 * 
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 * 
 */

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

abstract class INeoLogger {
  List<NavigatorObserver> get observers;

  void logScreenEvent(
    String screenName, {
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  });

  void logEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  });

  void logPageBuildStartingTime(String pageId, PageType pageType);

  void logPageBuildSuccessTime(String pageId, PageType pageType);

  void logCustom(dynamic message, Level logLevel);

  Future<bool?> isFeatureEnabled(String key);
  Future<void> reloadFeatureFlags();

  void logError(String message);
  void logException(dynamic exception, StackTrace stackTrace);

  /// If automatic data collection is disabled, this method queues up all the
  /// reports on a device to send to Crashlytics. Otherwise, this method is a no-op.
  Future<void> sendUnsentReports();
}

enum PageType {
  component('Component Page'),
  workflow('Workflow Page');

  const PageType(this.type);

  final String type;
}
