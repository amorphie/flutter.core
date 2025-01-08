// TODO: Order enum values alphabetically to prevent possible conflicts!
import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_widget_event.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_widget_event_bus.dart';

enum NeoCoreWidgetEventKeys {
  initPushMessagingServices,
}

extension NeoCoreWidgetEventKeysExtension on NeoCoreWidgetEventKeys {
  NeoWidgetEventBus get widgetEventBus => GetIt.I.get();

  void sendEvent({Object? data}) {
    widgetEventBus.addEvent(
      NeoWidgetEvent(eventId: name, data: data),
    );
  }

  StreamSubscription<NeoWidgetEvent> listenEvent({required Function(NeoWidgetEvent) onEventReceived}) {
    return widgetEventBus.listen(eventId: name, onEventReceived: onEventReceived);
  }
}
