import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:neo_core/core/analytics/neo_adjust/events/neo_adjust_events.dart';
import 'package:neo_core/neo_core.dart';

class NeoAdjust {
  static final NeoAdjust _instance = NeoAdjust._();
  factory NeoAdjust() => _instance;
  NeoAdjust._();

  Future<void> init({required String appToken}) async {
    final String? deviceId = await DeviceUtil().getDeviceId();

    final AdjustConfig adjustConfig = AdjustConfig(appToken, AdjustEnvironment.sandbox)..externalDeviceId = deviceId;

    Adjust.start(adjustConfig);
  }

  void logEvent(NeoAdjustEvent event) {
    Adjust.trackEvent(AdjustEvent(event.id));
  }
}
