/*
 * neo_core
 *
 * Created on 9/2/2024.
 * Copyright (c) 2024 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/analytics/neo_posthog.dart';
import 'package:neo_core/core/feature_flags/neo_feature_flag_key.dart';

class NeoFeatureFlagUtil {
  NeoFeatureFlagUtil._();

  static final _posthog = NeoPosthog();

  static Future<bool> bypassSignalR() async {
    return await _posthog.isFeatureEnabled(NeoFeatureFlagKey.bypassSignalR.value) ?? false;
  }

  static Future<bool> bypassSslPinning() async {
    return await _posthog.isFeatureEnabled(NeoFeatureFlagKey.bypassSslPinning.value) ?? false;
  }
}
