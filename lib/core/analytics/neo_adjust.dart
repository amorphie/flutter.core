import 'dart:async';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_attribution.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:flutter/foundation.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/neo_core.dart';

class NeoAdjust {
  final void Function(String?)? adjustDeferredDeeplinkCallback;
  final void Function(AdjustAttribution)? adjustAttributionCallback;
  final NeoCoreSecureStorage secureStorage;

  NeoAdjust({required this.secureStorage, this.adjustDeferredDeeplinkCallback, this.adjustAttributionCallback});

  Future<void> init({
    required String appToken,
    String urlStrategyValue = AdjustConfig.DataResidencyTR,
  }) async {
    if (kIsWeb) {
      return;
    }

    final String? deviceId = await secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId);
    final AdjustConfig adjustConfig =
        AdjustConfig(appToken, kDebugMode ? AdjustEnvironment.sandbox : AdjustEnvironment.production)
          ..externalDeviceId = deviceId
          ..urlStrategy = urlStrategyValue
          ..attributionCallback = adjustAttributionCallback
          ..deferredDeeplinkCallback = adjustDeferredDeeplinkCallback;

    Adjust.start(adjustConfig);
  }

  void logEvent(String eventId) {
    if (kIsWeb) {
      return;
    }

    Adjust.trackEvent(AdjustEvent(eventId));
  }
}
