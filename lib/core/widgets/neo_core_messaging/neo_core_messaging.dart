import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_core_widget_event_keys.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_widget_event.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/widgets/neo_core_firebase_messaging/neo_core_firebase_messaging.dart';
import 'package:neo_core/core/widgets/neo_core_huawei_messaging/neo_core_huawei_messaging.dart';
import 'package:neo_core/feature/neo_push_message_payload_handlers/neo_dengage_android_push_message_payload_handler.dart';
import 'package:neo_core/feature/neo_push_message_payload_handlers/neo_ios_push_message_payload_handler.dart';
import 'package:universal_io/io.dart';

class NeoCoreMessaging extends StatefulWidget {
  final Widget child;
  final NeoSharedPrefs neoSharedPrefs;
  final NeoNetworkManager networkManager;
  final NeoCoreSecureStorage neoCoreSecureStorage;
  final Function(String) onTokenChanged;
  final String? androidDefaultIcon;
  final String? notificationSound;
  final Function(String)? onDeeplinkNavigation;

  const NeoCoreMessaging({
    required this.child,
    required this.neoSharedPrefs,
    required this.networkManager,
    required this.neoCoreSecureStorage,
    required this.onTokenChanged,
    this.androidDefaultIcon,
    this.notificationSound,
    this.onDeeplinkNavigation,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _NeoCoreMessagingState();
}

class _NeoCoreMessagingState extends State<NeoCoreMessaging> {
  late final EventChannel eventChannel = const EventChannel("com.dengage.flutter/onNotificationClicked");

  NeoLogger get _neoLogger => GetIt.I.get();
  StreamSubscription<dynamic>? _subscription;

  StreamSubscription? _widgetEventStreamSubscription;

  void _listenWidgetEventKeys() {
    _widgetEventStreamSubscription = NeoCoreWidgetEventKeys.initPushMessagingServices.listenEvent(
      onEventReceived: (NeoWidgetEvent widgetEvent) {
        _init();
      },
    );
  }

  void _init() {
    if (kIsWeb) {
      return;
    }
    if (Platform.isIOS) {
      NeoIosPushMessagePayloadHandler().init(onDeeplinkNavigationParam: widget.onDeeplinkNavigation);
    }
    _subscription = eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  @override
  void initState() {
    super.initState();
    _listenWidgetEventKeys();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return widget.child;
    } else {
      final bool isHuaweiCompatible =
          widget.neoSharedPrefs.read(NeoCoreParameterKey.sharedPrefsIsHuaweiCompatible) as bool? ?? false;
      if (isHuaweiCompatible) {
        return NeoCoreHuaweiMessaging(
          networkManager: widget.networkManager,
          neoCoreSecureStorage: widget.neoCoreSecureStorage,
          onTokenChanged: widget.onTokenChanged,
          androidDefaultIcon: widget.androidDefaultIcon,
          notificationSound: widget.notificationSound,
          onDeeplinkNavigation: widget.onDeeplinkNavigation,
          child: widget.child,
        );
      } else {
        return NeoCoreFirebaseMessaging(
          networkManager: widget.networkManager,
          neoCoreSecureStorage: widget.neoCoreSecureStorage,
          onTokenChanged: widget.onTokenChanged,
          androidDefaultIcon: widget.androidDefaultIcon,
          notificationSound: widget.notificationSound,
          onDeeplinkNavigation: widget.onDeeplinkNavigation,
          child: widget.child,
        );
      }
    }
  }

  void _onEvent(dynamic event) {
    try {
      final Map<String, dynamic> eventData = json.decode(event);
      NeoDengageAndroidPushMessagePayloadHandler().handleMessage(
        message: eventData,
        onDeeplinkNavigation: widget.onDeeplinkNavigation,
      );
    } on FormatException catch (e) {
      _neoLogger.logError("[NeoCoreMessaging]: JSON Decode Error: $e");
    } catch (e) {
      _neoLogger.logError("[NeoCoreMessaging]: Dengage Message Error is: $e!");
    }
  }

  void _onError(dynamic error) {
    _neoLogger.logError("[NeoCoreMessaging]: Dengage Error Object is: $error!");
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _widgetEventStreamSubscription?.cancel();
    super.dispose();
  }
}
