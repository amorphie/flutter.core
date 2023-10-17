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

import 'package:burgan_core/core/bus/widget_event_bus/brg_widget_event.dart';
import 'package:rxdart/rxdart.dart';

class BrgWidgetEventBus {
  final _eventBus = BehaviorSubject<BrgWidgetEvent>();

  listen({
    required String eventId,
    required Function(BrgWidgetEvent) onEventReceived,
  }) {
    _eventBus.stream.listen((event) {
      if (event.eventId == eventId) {
        onEventReceived(event);
      }
    });
  }

  addEvent(BrgWidgetEvent event) {
    _eventBus.add(event);
  }
}
