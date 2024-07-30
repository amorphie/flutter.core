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

import 'dart:async';

import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class NeoPosthog {
  NeoPosthog() {
    _init();
  }

  final Posthog _posthog = Posthog();

  Future<void> _init() async {
    final secureStorage = NeoCoreSecureStorage();
    await secureStorage.init();
    unawaited(
      _posthog.identify(userId: await secureStorage.read(NeoCoreParameterKey.secureStorageTokenId) ?? ""),
    );
  }

  Future<void> setScreen(
    String screenName, {
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  }) async {
    await _posthog.screen(screenName: screenName, properties: properties, options: options);
  }

  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  }) async {
    await _posthog.capture(eventName: eventName, properties: properties, options: options);
  }

  Future<bool?> isFeatureEnabled(String key) async {
    return _posthog.isFeatureEnabled(key);
  }

  Future<void> reloadFeatureFlags() async {
    await _posthog.reloadFeatureFlags();
  }

  Future<void> setEnabled({required bool enabled}) async {
    return enabled ? _posthog.enable() : _posthog.disable();
  }
}
