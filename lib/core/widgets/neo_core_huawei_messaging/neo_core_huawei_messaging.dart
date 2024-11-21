import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:huawei_push/huawei_push.dart'; // Huawei Push Kit
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_core_widget_event_keys.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_widget_event.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/feature/device_registration/usecases/neo_core_register_device_usecase.dart';
import 'package:universal_io/io.dart';

abstract class _Constant {
  static const androidNotificationChannelID = "high_importance_channel";
  static const androidNotificationChannelName = "High Importance Notifications";
  static const androidNotificationChannelDescription = "This channel is used for important notifications";
  static const pushNotificationDeeplinkKey = "deeplink";
}

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  return Future.value();
}

class NeoCoreHuaweiMessaging extends StatefulWidget {
  const NeoCoreHuaweiMessaging({
    required this.child,
    required this.networkManager,
    required this.neoCoreSecureStorage,
    this.androidDefaultIcon,
    this.onDeeplinkNavigation,
    super.key,
  });

  final Widget child;
  final NeoNetworkManager networkManager;
  final NeoCoreSecureStorage neoCoreSecureStorage;
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

  void _listenWidgetEventKeys() {
    NeoCoreWidgetEventKeys.initFirebaseAndHuawei.listenEvent(
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
    debugPrint("Huawei Push token: $token");
    NeoCoreRegisterDeviceUseCase().call(
      networkManager: widget.networkManager,
      secureStorage: widget.neoCoreSecureStorage,
      deviceToken: token,
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
    final String? deeplinkPath = messageData[_Constant.pushNotificationDeeplinkKey];
    if (deeplinkPath != null && deeplinkPath.isNotEmpty) {
      widget.onDeeplinkNavigation?.call(deeplinkPath);
    }
  }

  Future<String?> _getHuaweiToken() async {
    try {
      // Request token (token will be sent via Push.getTokenStream)
      Push.getToken("");

      // Listen to the first token from stream
      final String token = await Push.getTokenStream.first;
      return token;
    } catch (e) {
      debugPrint("There is an error receiving the Huawei-Push token: $e");
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
    _neoLogger.logConsole("Error receiving message: $error", logLevel: Level.error);
  }
}
