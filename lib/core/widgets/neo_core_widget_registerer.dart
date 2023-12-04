/*
 * neo_core
 *
 * Created on 17/11/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:neo_core/core/widgets/neo_navigation_button/neo_navigation_button_builder.dart';

class NeoCoreWidgetRegisterer {
  static final registry = JsonWidgetRegistry.instance;

  void init() {
    registry.registerCustomBuilder(
      NeoNavigationButtonBuilder.kType,
      const JsonWidgetBuilderContainer(builder: NeoNavigationButtonBuilder.fromDynamic),
    );
  }
}
