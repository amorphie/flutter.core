import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:adjust_sdk/adjust_event.dart';
import 'package:flutter/foundation.dart';
import 'package:neo_core/core/analytics/neo_adjust/events/neo_adjust_events.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/neo_core.dart';

abstract class _Constants {
  static const eventNameAdjustInitSucceed = "[NeoAdjust]: init is succeed!";
  static const eventNameAdjustInitFailed = "[NeoAdjust]: init is failed!";
}

class NeoAdjust {
  static final NeoAdjust _instance = NeoAdjust._();
  factory NeoAdjust() => _instance;
  NeoAdjust._();

  final NeoLogger _neoLogger = NeoLogger();

  Future<void> init({required String appToken}) async {
    try {
      final String? deviceId = await DeviceUtil().getDeviceId();

      final AdjustConfig adjustConfig =
          AdjustConfig(appToken, kDebugMode ? AdjustEnvironment.sandbox : AdjustEnvironment.production)
            ..externalDeviceId = deviceId;

      Adjust.start(adjustConfig);
      _neoLogger.logCustom(
        _Constants.eventNameAdjustInitSucceed,
        logTypes: [NeoAnalytics.posthog, NeoAnalytics.logger],
      );
    } on Exception catch (e, stacktrace) {
      _neoLogger.logException("${_Constants.eventNameAdjustInitFailed} $e", stacktrace);
    }
  }

  void logEvent(NeoAdjustEvent event) {
    Adjust.trackEvent(AdjustEvent(event.id));
  }
}
