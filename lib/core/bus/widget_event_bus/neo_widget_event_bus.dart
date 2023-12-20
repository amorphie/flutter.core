/*
 * neo_core
 *
 * Created on 22/9/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'dart:async';

import 'package:neo_core/core/bus/widget_event_bus/neo_widget_event.dart';
import 'package:rxdart/rxdart.dart';

class NeoWidgetEventBus {
  final _eventBus = BehaviorSubject<NeoWidgetEvent>();

  StreamSubscription<NeoWidgetEvent> listen({
    required String eventId,
    required Function(NeoWidgetEvent) onEventReceived,
  }) {
    return _eventBus.stream.listen((event) {
      if (event.eventId == eventId) {
        onEventReceived(event);
      }
    });
  }

  StreamSubscription<NeoWidgetEvent> listenEvents({
    required List<String> eventIds,
    required Function(NeoWidgetEvent) onEventReceived,
  }) {
    return _eventBus.stream.listen((event) {
      if (eventIds.contains(event.eventId)) {
        onEventReceived(event);
      }
    });
  }

  void addEvent(NeoWidgetEvent event) {
    _eventBus.add(event);
  }

  void close() {
    _eventBus.close();
  }
}
