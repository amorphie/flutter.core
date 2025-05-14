import 'dart:async';
import 'dart:developer';

import 'package:adjust_sdk/adjust_attribution.dart';
import 'package:collection/collection.dart';
import 'package:dataroid_plugin_flutter/custom_event.dart';
import 'package:dataroid_plugin_flutter/dataroid_plugin_config.dart';
import 'package:dataroid_plugin_flutter/dataroid_plugin_flutter.dart';
import 'package:dataroid_plugin_flutter/deeplink_referral/deeplink_attributes.dart';
import 'package:dataroid_plugin_flutter/push/inapp_button.dart';
import 'package:dataroid_plugin_flutter/push/push_models.dart';
import 'package:dataroid_plugin_flutter/screen_tracker.dart';
import 'package:dataroid_plugin_flutter/super_attributes/super_attribute.dart';
import 'package:dataroid_plugin_flutter/user.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/analytics/neo_logger_type.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';
import 'package:neo_core/neo_core.dart';
import 'package:neo_core/usecases/run_platform_code_use_case.dart';

abstract class _Constants {
  static const String staticDeeplinkReferralKeyword = "campaign";
  static const String deeplinkQueryParamSplitter = ",";
  static const String failurePageEvent = "FailurePageEvent";
  static const String radioButtonSelectEvent = "RadioButtonSelectEvent";
  static const String networkErrorEvent = "NetworkErrorEvent";
}

class DataroidRepository implements DataroidPluginFlutterDelegate {
  DataroidRepository({
    required DataroidPluginFlutter dataroidPlugin,
    this.enableConsoleLogging = true,
  })  : _dataroidPlugin = dataroidPlugin,
        _screenTrackers = [] {
    _dataroidPlugin.delegate = this;
    _init();
  }

  final DataroidPluginFlutter _dataroidPlugin;
  final bool enableConsoleLogging;
  final List<ScreenTracker> _screenTrackers;

  static const RunPlatformCodeUseCase _runPlatformCodeUseCase = RunPlatformCodeUseCase();

  NeoLogger? get _logger => getIt.getIfReady<NeoLogger>();

  void adjustDeferredDeeplinkCallback(String? deferredLink) {
    _runPlatformCodeUseCase.call(
      mobile: () {
        if (deferredLink == null) {
          return;
        }

        final Map<String, String> queryParams = Uri.parse(deferredLink).queryParameters;
        if (queryParams.isEmpty) {
          return;
        }
        final String combinedQueryParams = queryParams.entries
            .map((entry) => "${entry.key}=${entry.value}")
            .join(_Constants.deeplinkQueryParamSplitter);

        _logger?.logCustom(
          "[NeoDataroidRepository] Adjust deferred deeplink: $deferredLink and logged $combinedQueryParams",
        );
        unawaited(setSuperAttribute(key: _Constants.staticDeeplinkReferralKeyword, value: combinedQueryParams));
      },
    );
  }

  void adjustAttributionCallback(AdjustAttribution attribution) {
    _runPlatformCodeUseCase.call(
      mobile: () {
        final String combinedQueryParams =
            "campaign=${attribution.campaign},network=${attribution.network},adgroup=${attribution.adgroup},adid=${attribution.adid},clickLabel=${attribution.clickLabel},trackerName=${attribution.trackerName},trackerToken=${attribution.trackerToken}";

        _logger?.logCustom(
          "[NeoDataroidRepository] Adjust attribution logged $combinedQueryParams",
        );
        unawaited(setSuperAttribute(key: _Constants.staticDeeplinkReferralKeyword, value: combinedQueryParams));
      },
    );
  }

  /// Sets the user for tracking purposes in Dataroid
  Future setUser(String userId) async {
    await _runPlatformCodeUseCase.call(
      mobile: () async {
        try {
          await _dataroidPlugin.setUser(User(customerId: userId));

          _logToConsole('Set user: $userId');
        } catch (e) {
          _logToConsole('Error setting user: $e');
        }
      },
    );
  }

  /// Initiates screen tracking for a specific view with given parameters.
  ///
  /// [label] The identifier for the screen being tracked
  /// [viewClass] The class name of the view being tracked
  /// [attributes] Additional data attributes for tracking
  ///
  /// If a tracker with the same label already exists, the method returns early
  /// without creating a duplicate tracker.
  void startScreenTracking({
    required String label,
    required String viewClass,
    required Map<String, dynamic> attributes,
  }) {
    _runPlatformCodeUseCase.call(
      mobile: () async {
        try {
          final tracker = ScreenTracker(
            label: label,
            viewClass: viewClass,
            attributes: attributes,
          );

          if (_screenTrackers.any((tracker) => tracker.label == label)) {
            return;
          }

          await _dataroidPlugin.startTracking(tracker);
          _screenTrackers.add(tracker);

          _logToConsole('--> Start tracking screen: $label <--');
        } catch (e) {
          _logToConsole('Error starting screen tracking: $e');
        }
      },
    );
  }

  /// Sets deeplink referral for tracking purposes in Dataroid
  Future<void> setDeeplinkReferral({required String url}) async {
    try {
      final DeeplinkAttributes deeplinkAttributes = DeeplinkAttributes(url: url);
      await _dataroidPlugin.collectDeeplink(deeplinkAttributes);
    } catch (e) {
      _logToConsole('Error setDeeplinkReferral : $e');
    }
  }

  /// Sets user's additional attributes for tracking purposes in Dataroid
  Future<void> setSuperAttribute({required String key, required String value}) async {
    try {
      await _dataroidPlugin.setSuperAttribute(SuperAttribute(key: key, value: value));
    } catch (e) {
      _logToConsole('Error setSuperAttribute : $e');
    }
  }

  /// Stops tracking a screen with the given [label].
  ///
  /// Finds the last tracker with matching [label] from [_screenTrackers] list.
  /// If found, stops tracking via [_dataroidPlugin] and removes the tracker.
  /// If no matching tracker found, silently returns.
  ///
  /// Logs tracking stop event to console.
  void stopScreenTracking(String label) {
    _runPlatformCodeUseCase.call(
      mobile: () async {
        try {
          final tracker = _screenTrackers.lastWhereOrNull((tracker) => tracker.label == label);

          if (tracker == null) {
            return;
          }

          await _dataroidPlugin.stopTracking(tracker);
          _screenTrackers.remove(tracker);

          _logToConsole('<-- Stop tracking screen: ${tracker.label} -->');
        } catch (e) {
          _logToConsole('Error stopping screen tracking: $e');
        }
      },
    );
  }

  /// Collects a click event to dataroid for analytics purposes.
  ///
  /// [labelText]: The text label of the button being clicked.
  /// [id]: Optional unique identifier for the button.
  /// [navigationPath]: Optional navigation path triggered by the button.
  /// [navigationType]: Optional type of navigation action.
  /// [transitionId]: Optional transition identifier.
  /// [workflowNameSuffix]: Optional suffix for the workflow name.
  /// [workflowPreInstanceId]: Optional ID for the pre-instance of the workflow.
  /// [workflowPreWorkflowName]: Optional name for the pre-workflow.
  /// [widgetEventKey]: Optional key to identify the widget in analytics.
  Future<void> collectClickEvent({
    required String labelText,
    String? id,
    String? navigationPath,
    String? navigationType,
    String? transitionId,
    String? workflowNameSuffix,
    String? workflowPreInstanceId,
    String? workflowPreWorkflowName,
    String? widgetEventKey,
  }) async {
    _runPlatformCodeUseCase.call(
      mobile: () async {
        try {
          await collectCustomEvent(
            eventName: "ClickEvent",
            attributes: {
              'labelText': labelText,
              'id': id,
              'navigationPath': navigationPath,
              'navigationType': navigationType,
              'transitionId': transitionId,
              'workflowNameSuffix': workflowNameSuffix,
              'workflowPreInstanceId': workflowPreInstanceId,
              'workflowPreWorkflowName': workflowPreWorkflowName,
              'widgetEventKey': widgetEventKey,
            },
          );
        } catch (e) {
          _logToConsole('Error collect ClickEvent: $e');
        }
      },
    );
  }

  void _init() {
    _enablePushForAndroid();
    _updateConfig();
  }

  Future<void> collectCustomEvent({required String eventName, Map<String, dynamic> attributes = const {}}) async {
    _runPlatformCodeUseCase.call(
      mobile: () async {
        try {
          final Map<String, dynamic> additionalData = _buildCustomAttributes(attributes);

          final customEvent = CustomEvent(eventName: eventName)..attributes = additionalData;

          await _dataroidPlugin.collectCustomEvent(customEvent);
          _logger?.logCustom(
            eventName,
            properties: additionalData,
            logTypes: [
              NeoLoggerType.elastic,
              NeoLoggerType.logger,
            ],
          );
          _logToConsole(eventName);
        } catch (e) {
          _logger?.logError(e.toString());
        }
      },
    );
  }

  Future<void> collectUserErrorEvent({
    required String pageId,
    required List<String> errorMessages,
  }) async {
    final Map<String, dynamic> attributeMap = {
      "pageId": pageId,
    };

    for (var i = 0; i < errorMessages.length; i++) {
      attributeMap["error${i + 1}"] = errorMessages[i];
    }

    await collectCustomEvent(
      eventName: "UserErrorEvent",
      attributes: attributeMap,
    );
  }

  Future<void> collectFailurePageEvent({
    String? pageId,
    String? transitionId,
    String? statusCode,
    String? statusMessage,
    String? navigationPath,
  }) async {
    await collectCustomEvent(
      eventName: _Constants.failurePageEvent,
      attributes: {
        "pageId": pageId,
        "transitionId": transitionId,
        "statusCode": statusCode,
        "statusMessage": statusMessage,
        "navigationPath": navigationPath,
      },
    );
  }

  Future<void> collectRadioButtonSelectEvent({
    required String pageId,
    required String radioKey,
    required int selectedIndex,
    String? selectedDataKey,
    String? selectedTitle,
  }) async {
    await collectCustomEvent(
      eventName: _Constants.radioButtonSelectEvent,
      attributes: {
        "pageId": pageId,
        "radioKey": radioKey,
        "selectedIndex": selectedIndex,
        "selectedDataKey": selectedDataKey,
        "selectedTitle": selectedTitle,
      },
    );
  }

  Future<void> collectNetworkErrorEvent({
    String? requestId,
    String? errorCode,
    String? errorType,
    String? title,
    String? description,
  }) async {
    await collectCustomEvent(
      eventName: _Constants.networkErrorEvent,
      attributes: {
        "requestId": requestId,
        "errorCode": errorCode,
        "errorType": errorType,
        "title": title,
        "description": description,
      },
    );
  }

  /// Updates the Dataroid plugin configuration.
  ///
  /// Enables screen tracking by setting [DataroidScreenTrackingConfig.enabled] to true.
  /// Logs confirmation message to console after update.
  void _updateConfig() {
    _runPlatformCodeUseCase.call(
      mobile: () async {
        try {
          await _dataroidPlugin.updateConfig(
            screenTracking: DataroidScreenTrackingConfig(
              enabled: true,
            ),
          );

          _logToConsole('Updated config');
        } catch (e) {
          _logToConsole('Error updating config: $e');
        }
      },
    );
  }

  /// Enables push notifications for [Android]
  void _enablePushForAndroid() {
    _runPlatformCodeUseCase.call(
      mobile: () async {
        try {
          await _dataroidPlugin.enablePush();
          _logToConsole('Dataroid notification enabled for Android');
        } catch (e) {
          _logToConsole('Error Dataroid push notification enabled on Android: $e');
        }
      },
    );
  }

  void _logToConsole(String message) {
    if (enableConsoleLogging) {
      log(message, name: 'Dataroid');
    }
  }

  Map<String, dynamic> _buildCustomAttributes(
    Map<String, dynamic> rawAttributes,
  ) {
    final attributes = <String, dynamic>{};
    rawAttributes.forEach((key, value) {
      if (value != null) {
        attributes[key] = value;
      }
    });
    return attributes;
  }

  @override
  void handleInApp(String content) {
    // TODO: implement handleInApp
  }

  @override
  void handleInAppButtonTap(InAppButton button, String content) {
    // TODO: implement handleInAppButtonTap
  }

  @override
  void handleInAppMessageDeeplink(String deeplink) {
    // TODO STOPSHIP: Send event using event bus
    // NavigateWithDeeplinkUseCase().call(deeplink);
  }

  @override
  void handlePushEventiOS(PushActionType type, PushEventTiming timing, String targetURL, Map attributes) {
    // TODO: implement handlePushEventiOS
  }

  @override
  bool shouldShowNotificationInForeground(Map<String, dynamic> userInfo) {
    return true;
  }
}
