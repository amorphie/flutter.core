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

class NeoWidgetEventBus {
  final _eventBus = StreamController<NeoWidgetEvent>.broadcast();
  final Set<StreamSubscription<NeoWidgetEvent>> _subscriptions = {};

  StreamSubscription<NeoWidgetEvent> listen({
    required String eventId,
    required Function(NeoWidgetEvent) onEventReceived,
  }) {
    final subscription = _eventBus.stream.listen((event) {
      if (event.eventId == eventId) {
        onEventReceived(event);
      }
    });
    _subscriptions.add(subscription);
    return subscription;
  }

  StreamSubscription<NeoWidgetEvent> listenEvents({
    required List<String> eventIds,
    required Function(NeoWidgetEvent) onEventReceived,
  }) {
    final subscription = _eventBus.stream.listen((event) {
      if (eventIds.contains(event.eventId)) {
        onEventReceived(event);
      }
    });
    _subscriptions.add(subscription);
    return subscription;
  }

  void addEvent(NeoWidgetEvent event) {
    _eventBus.add(event);
  }

  void close() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _eventBus.close();
  }
}
