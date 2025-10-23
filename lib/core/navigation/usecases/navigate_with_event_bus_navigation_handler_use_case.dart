import 'package:neo_core/core/bus/widget_event_bus/neo_core_widget_event_keys.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_event_model.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';

class NavigateWithEventBusNavigationHandlerUseCase {
  static void call(
    NeoNavigationType navigationType,
    String? navigationPath, {
    Map<dynamic, dynamic>? popArguments,
    Function(dynamic)? onPopped,
    bool useRootNavigator = false,
  }) {
    switch (navigationType) {
      case NeoNavigationType.popUntil:
        NeoCoreWidgetEventKeys.globalNavigationPopUntil.sendEvent(
          data: NeoNavigationEventModel(navigationPath: navigationPath, useRootNavigator: useRootNavigator),
        );
        break;
      case NeoNavigationType.push:
        NeoCoreWidgetEventKeys.globalNavigationPush.sendEvent(
          data: NeoNavigationEventModel(
            navigationPath: navigationPath,
            onPopped: onPopped,
            useRootNavigator: useRootNavigator,
          ),
        );
        break;
      case NeoNavigationType.pushReplacement:
        NeoCoreWidgetEventKeys.globalNavigationPushReplacement.sendEvent(
          data: NeoNavigationEventModel(navigationPath: navigationPath, useRootNavigator: useRootNavigator),
        );
        break;
      case NeoNavigationType.pushAsRoot:
        NeoCoreWidgetEventKeys.globalNavigationPushAsRoot.sendEvent(
          data: NeoNavigationEventModel(navigationPath: navigationPath, useRootNavigator: useRootNavigator),
        );
        break;
      case NeoNavigationType.pop:
        NeoCoreWidgetEventKeys.globalNavigationPop.sendEvent(
          data: NeoNavigationEventModel(
            navigationPath: navigationPath,
            popArguments: popArguments,
            useRootNavigator: useRootNavigator,
          ),
        );
        break;
      case NeoNavigationType.popup:
      case NeoNavigationType.bottomSheet:
        // No-op
        break;
      case NeoNavigationType.none:
      // No-op
    }
  }
}
