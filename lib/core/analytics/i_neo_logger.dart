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

abstract class INeoLogger {
  void logScreenEvent(
    String screenName, {
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  });

  void logNavigationEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  });

  Future<bool?> isFeatureEnabled(String key);

  Future<void> reloadFeatureFlags();

  List<NavigatorObserver> setObserver();

  bool get isCrashlyticsCollectionEnabled;

  void logError(String message);

  void logException(dynamic exception, StackTrace stackTrace);
  Future<void> setEnabled({required bool enabled});

  Future<void> sendUnsentReports();
}
