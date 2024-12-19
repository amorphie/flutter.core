import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:huawei_push/huawei_push.dart'; // Huawei Push Kit
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_core_widget_event_keys.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_widget_event.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/feature/device_registration/usecases/neo_core_register_device_usecase.dart';
import 'package:neo_core/feature/neo_push_message_payload_handlers/neo_huawei_push_message_payload_handler.dart';
import 'package:universal_io/io.dart';

abstract class _Constant {
  static const androidNotificationChannelID = "high_importance_channel";
  static const androidNotificationChannelName = "High Importance Notifications";
  static const androidNotificationChannelDescription = "This channel is used for important notifications";
  static const pushNotificationDeeplinkKey = "deeplink";
}

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  debugPrint("[NeoCoreHuaweiMessaging]: Background notification was triggered by ${message.notification}");
  return Future.value();
}

class NeoCoreHuaweiMessaging extends StatefulWidget {
  const NeoCoreHuaweiMessaging({
    required this.child,
    required this.networkManager,
    required this.neoCoreSecureStorage,
    required this.onTokenChanged,
    this.androidDefaultIcon,
    this.onDeeplinkNavigation,
    super.key,
  });

  final Widget child;
  final NeoNetworkManager networkManager;
  final NeoCoreSecureStorage neoCoreSecureStorage;
  final Function(String) onTokenChanged;
  final String? androidDefaultIcon;
  final Function(String)? onDeeplinkNavigation;

  @override
  State<NeoCoreHuaweiMessaging> createState() => _NeoCoreHuaweiMessagingState();
}

class _NeoCoreHuaweiMessagingState extends State<NeoCoreHuaweiMessaging> {
  final _androidChannel = const AndroidNotificationChannel(
    _Constant.androidNotificationChannelID,
    _Constant.androidNotificationChannelName,
    description: _Constant.androidNotificationChannelDescription,
  );
  final _localNotifications = FlutterLocalNotificationsPlugin();

  NeoLogger get _neoLogger => GetIt.I.get();

  StreamSubscription? _widgetEventStreamSubscription;

  void _listenWidgetEventKeys() {
    _widgetEventStreamSubscription = NeoCoreWidgetEventKeys.initFirebaseAndHuawei.listenEvent(
      onEventReceived: (NeoWidgetEvent widgetEvent) {
        _init();
      },
    );
  }

  void _init() {
    if (kIsWeb) {
      return;
    }
    _initPushNotifications();
    _initNotifications();
    if (Platform.isAndroid) {
      _initLocalNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    _listenWidgetEventKeys();
  }

  Future<void> _initNotifications() async {
    final token = await _getHuaweiToken();
    if (token != null) {
      _onTokenChange(token);
    }

    // Listen to the token stream
    Push.getTokenStream.listen(_onTokenChange);

    // Listen to the message received stream
    Push.onMessageReceivedStream.listen(_onMessageReceived, onError: _onMessageReceiveError);

    // Listen to notification opened events
    Push.onNotificationOpenedApp.listen(_onNotificationOpenedApp);
  }

  void _onTokenChange(String token) {
    _neoLogger.logConsole("[NeoCoreHuaweiMessaging]: Firebase Push token is: $token");
    widget.onTokenChanged.call(token);
    NeoCoreRegisterDeviceUseCase().call(
      networkManager: widget.networkManager,
      secureStorage: widget.neoCoreSecureStorage,
      deviceToken: token,
      isGoogleServiceAvailable: false,
    );
  }

  Future<void> _initPushNotifications() async {
    // Enable push notifications for Huawei Push Kit
    await Push.turnOnPush();
  }

  Future<void> _initLocalNotifications() async {
    final String androidIcon = widget.androidDefaultIcon ?? "";
    final android = AndroidInitializationSettings(androidIcon);
    final settings = InitializationSettings(android: android);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          // Directly handle the JSON payload from the notification
          final Map<String, dynamic> messageData = jsonDecode(payload) as Map<String, dynamic>;
          _handleMessage(messageData);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  void _handleMessage(Map<String, dynamic> messageData) {
    NeoHuaweiPushMessagePayloadHandler().handleMessage(
      message: messageData,
      onDeeplinkNavigation: widget.onDeeplinkNavigation,
    );
  }

  Future<String?> _getHuaweiToken() async {
    try {
      // Request token (token will be sent via Push.getTokenStream)
      Push.getToken("");

      // Listen to the first token from stream
      final String token = await Push.getTokenStream.first;
      return token;
    } catch (e) {
      _neoLogger.logError("[NeoCoreHuaweiMessaging]: There is an error receiving the Huawei-Push token: $e");
      return null;
    }
  }

  void _onMessageReceived(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null || !Platform.isAndroid) {
      return;
    }
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: widget.androidDefaultIcon,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationOpenedApp(dynamic initialNotification) {
    if (initialNotification != null) {
      // Handle the initialNotification as a Map<String, dynamic>
      final Map<String, dynamic> messageData = initialNotification as Map<String, dynamic>;
      _handleMessage(messageData);
    }
  }

  void _onMessageReceiveError(Object error) {
    _neoLogger.logError("Error receiving message: $error");
  }

  @override
  void dispose() {
    _widgetEventStreamSubscription?.cancel();
    super.dispose();
  }
}
