import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:flutter/foundation.dart';
import 'package:neo_core/neo_core.dart';

class NeoAdjust {
  final void Function(String?) adjustDeferredDeeplinkCallback;
  NeoAdjust({required this.adjustDeferredDeeplinkCallback});

  Future<void> init({required String appToken}) async {
    if (kIsWeb) {
      return;
    }

    final String? deviceId = await DeviceUtil().getDeviceId();
    final AdjustConfig adjustConfig =
        AdjustConfig(appToken, kDebugMode ? AdjustEnvironment.sandbox : AdjustEnvironment.production)
          ..externalDeviceId = deviceId
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
