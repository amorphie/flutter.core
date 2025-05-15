// TODO: Order enum values alphabetically to prevent possible conflicts!
import 'dart:async';

import 'package:neo_core/neo_core.dart';

enum NeoCoreWidgetEventKeys {
  globalAnalyticEvent,
  globalNavigationMaybePop,
  globalNavigationPop,
  globalNavigationPopUntil,
  globalNavigationPush,
  globalNavigationPushAsRoot,
  globalNavigationPushReplacement,
  globalNavigationSystemPop,
  globalSignalrNetworkError,
  initPushMessagingServices,
  neoSmsOtpListenerAutofillOtp,
}

extension NeoWidgetEventKeysExtension on NeoCoreWidgetEventKeys {
  void sendEvent({Object? data}) {
    getIt.get<NeoWidgetEventBus>().addEvent(
          NeoWidgetEvent(eventId: name, data: data),
        );
  }

  StreamSubscription<NeoWidgetEvent> listenEvent({required Function(NeoWidgetEvent) onEventReceived}) {
    return getIt.get<NeoWidgetEventBus>().listen(eventId: name, onEventReceived: onEventReceived);
  }
}

extension NeoWidgetEventKeysListExtension on List<(NeoCoreWidgetEventKeys, Function(NeoWidgetEvent))> {
  StreamSubscription<NeoWidgetEvent> listenEvents() {
    return getIt.get<NeoWidgetEventBus>().listenEvents(
          eventIds: map((e) => e.$1.name).toList(),
          onEventReceived: (event) => forEach((e) {
            if (e.$1.name == event.eventId) {
              e.$2.call(event);
            }
          }),
        );
  }
}
