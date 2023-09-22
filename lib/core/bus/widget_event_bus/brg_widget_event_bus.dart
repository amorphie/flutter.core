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
