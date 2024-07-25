import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:flutter/foundation.dart';
import 'package:neo_core/neo_core.dart';

class NeoAdjust {
  NeoAdjust();
  Future<void> init({required String appToken}) async {
    final String? deviceId = await DeviceUtil().getDeviceId();
    final AdjustConfig adjustConfig =
        AdjustConfig(appToken, kDebugMode ? AdjustEnvironment.sandbox : AdjustEnvironment.production)
          ..externalDeviceId = deviceId;
    Adjust.start(adjustConfig);
  }

  void logEvent(String eventId) {
    Adjust.trackEvent(AdjustEvent(eventId));
  }
}
