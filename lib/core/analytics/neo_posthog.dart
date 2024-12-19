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

abstract class _Constants {
  static const String usernameKey = "NameSurname";
  static const String businessLineKey = "BranchCode";
}

class NeoPosthog {
  final NeoCoreSecureStorage neoCoreSecureStorage;

  NeoPosthog({required this.neoCoreSecureStorage});

  final Posthog _posthog = Posthog();

  Future<void> init({required String apiKey, required String host}) async {
    final config = PostHogConfig(apiKey)
      ..debug = true
      ..captureApplicationLifecycleEvents = true
      ..host = host;
    final List values = await Future.wait([
      neoCoreSecureStorage.read(NeoCoreParameterKey.secureStorageCustomerId),
      neoCoreSecureStorage.read(NeoCoreParameterKey.secureStorageCustomerNameAndSurname),
      neoCoreSecureStorage.read(NeoCoreParameterKey.secureStorageBusinessLine),
      Posthog().setup(config),
    ]);

    final customerId = values[0] ?? "";
    final nameAndSurname = values[1] ?? "";
    final businessLine = values[2] ?? "";

    unawaited(
      _posthog.identify(
        userId: customerId,
        userProperties: {
          _Constants.usernameKey: nameAndSurname,
          _Constants.businessLineKey: businessLine,
        },
      ),
    );
  }

  Future<void> setScreen(
    String screenName, {
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  }) async {
    await _posthog.screen(screenName: screenName, properties: properties?.cast<String, Object>());
  }

  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    Map<String, dynamic>? options,
  }) async {
    await _posthog.capture(
      eventName: eventName,
      properties: properties?.cast<String, Object>(),
    );
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
