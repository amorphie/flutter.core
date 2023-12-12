/*
 * 
 * neo_core
 * 
 * Created on 08/12/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 * 
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 * 
 */

import 'package:posthog_flutter/posthog_flutter.dart';

class NeoPosthog {
  NeoPosthog._();

  static final Posthog _posthog = Posthog();

  static Future<void> setScreen(
    String screenName, {
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  }) async {
    await _posthog.screen(screenName: screenName);
  }

  static Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  }) async {
    await _posthog.capture(eventName: eventName, properties: properties, options: options);
  }

  static Future<bool?> isFeatureEnabled(String key) async {
    return _posthog.isFeatureEnabled(key);
  }

  static Future<void> reloadFeatureFlags() async {
    await _posthog.reloadFeatureFlags();
  }
}
