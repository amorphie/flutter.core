import 'dart:async';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_attribution.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:flutter/foundation.dart';
import 'package:neo_core/neo_core.dart';

abstract class _Constants {
  static const String urlStrategyDefaultValue = "ADJDataResidencyTR";
}

class NeoAdjust {
  final void Function(String?)? adjustDeferredDeeplinkCallback;
  final void Function(AdjustAttribution)? adjustAttributionCallback;

  NeoAdjust({this.adjustDeferredDeeplinkCallback, this.adjustAttributionCallback});

  Future<void> init({
    required String appToken,
    String urlStrategyValue = _Constants.urlStrategyDefaultValue,
  }) async {
    if (kIsWeb) {
      return;
    }

    final String? deviceId = await DeviceUtil().getDeviceId();
    final AdjustConfig adjustConfig =
        AdjustConfig(appToken, kDebugMode ? AdjustEnvironment.sandbox : AdjustEnvironment.production)
          ..externalDeviceId = deviceId
          ..urlStrategy = urlStrategyValue
          ..deferredDeeplinkCallback = adjustDeferredDeeplinkCallback;

    Adjust.start(adjustConfig);

    unawaited(() {
      try {
        setAdjustNetworkAttribution();
      } catch (e) {
        debugPrint('Failed to set Adjust network attribution: $e');
      }
    }());
  }

  void logEvent(String eventId)  {
    if (kIsWeb) {
      return;
    }

    Adjust.trackEvent(AdjustEvent(eventId));
  }

  Future<void> setAdjustNetworkAttribution() async {
    if (kIsWeb || adjustAttributionCallback == null) {
      return;
    }

    await Adjust.getAttribution().then(adjustAttributionCallback!);
  }
}
