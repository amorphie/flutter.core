/*
 * burgan_core
 *
 * Created on 22/9/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:burgan_core/core/storage/shared_preferences_helper.dart';

export 'core/bus/burgan_bus.dart';
export 'core/network/burgan_network.dart';
export 'core/util/burgan_util.dart';
export 'core/widgets/burgan_widgets.dart';

class BurganCore {
  static init() async {
    await SharedPreferencesHelper.init();
  }
}
