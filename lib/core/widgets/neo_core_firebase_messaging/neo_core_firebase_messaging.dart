import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  debugPrint("***BackgroundMessage: ${message.notification}");
  final buffer = StringBuffer()
    ..write("title: ${message.notification?.title}")
    ..write(message.notification?.titleLocKey ?? '-')
    ..write(message.notification?.titleLocArgs ?? '-')
    ..write("body: ${message.notification?.body}")
    ..write(message.notification?.bodyLocKey ?? '-')
    ..write(message.notification?.bodyLocArgs ?? '-')
    ..write(message.notification?.android?.link ?? '-')
    ..write(message.notification?.android?.imageUrl ?? '-')
    ..write("android: ${message.notification?.android}");
  debugPrint("***BackgroundMessage notification: $buffer");
  return Future.value();
}

class NeoCoreFirebaseMessaging extends StatefulWidget {
  const NeoCoreFirebaseMessaging({
    required this.child,
    required this.networkManager,
    required this.neoCoreSecureStorage,
    required this.token,
    this.androidDefaultIcon,
    this.onDeeplinkNavigation,
    super.key,
  });

  final Widget child;
  final NeoNetworkManager networkManager;
  final NeoCoreSecureStorage neoCoreSecureStorage;
  final Function(String) token;
  final String? androidDefaultIcon;
  final Function(String)? onDeeplinkNavigation;

  static FirebaseMessaging get firebaseMessaging => _firebaseMessaging;

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  State<NeoCoreFirebaseMessaging> createState() => _NeoCoreFirebaseMessagingState();
}

class _NeoCoreFirebaseMessagingState extends State<NeoCoreFirebaseMessaging> {
  final _androidChannel = const AndroidNotificationChannel(
    _Constant.androidNotificationChannelID,
    _Constant.androidNotificationChannelName,
    description: _Constant.androidNotificationChannelDescription,
  );
  final _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      return;
    }
    _initNotifications();
    _initPushNotifications();
    if (Platform.isAndroid) {
      _initLocalNotifications();
    }
  }

  Future<void> _initNotifications() async {
    final token = await _getTokenBasedOnPlatform();
    if (token != null) {
      _onTokenChange(token);
    }
    NeoCoreFirebaseMessaging.firebaseMessaging.onTokenRefresh.listen(_onTokenChange);
  }

  void _onTokenChange(String token) {
    debugPrint("Firebase Push token: $token");
    widget.token.call(token);
    NeoCoreRegisterDeviceUseCase().call(
      networkManager: widget.networkManager,
      secureStorage: widget.neoCoreSecureStorage,
      deviceToken: token,
    );
  }

  Future<void> _initPushNotifications() async {
    await NeoCoreFirebaseMessaging.firebaseMessaging
        .setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    // Get any messages which caused the application to open from a terminated state.
    await NeoCoreFirebaseMessaging.firebaseMessaging.getInitialMessage().then(_handleMessage);

    // Also handle any interaction when the app is in the background via Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Background message handler for Android platform
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

    // This is called when an incoming FCM payload is received while the Flutter instance is in the foreground.
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint("***ForegroundMessage: ${message.notification}");
      final buffer = StringBuffer()
        ..write("title: ${message.notification?.title}")
        ..write(message.notification?.titleLocKey ?? '-')
        ..write(message.notification?.titleLocArgs ?? '-')
        ..write("body: ${message.notification?.body}")
        ..write(message.notification?.bodyLocKey ?? '-')
        ..write(message.notification?.bodyLocArgs ?? '-')
        ..write(message.notification?.android?.link ?? '-')
        ..write(message.notification?.android?.imageUrl ?? '-')
        ..write("android: ${message.notification?.android}");
      debugPrint("****ForegroundMessage notification: $buffer");
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
        payload: jsonEncode(message.toMap()),
      );
    });
  }

  Future<void> _initLocalNotifications() async {
    final String androidIcon = widget.androidDefaultIcon ?? "";
    final android = AndroidInitializationSettings(androidIcon);
    final settings = InitializationSettings(android: android);
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            _handleMessage(RemoteMessage.fromMap(jsonDecode(notificationResponse.payload ?? "")));
            break;
          case NotificationResponseType.selectedNotificationAction:
            break;
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<String?> _getTokenBasedOnPlatform() async {
    String? token;
    if (kIsWeb) {
      return null;
    } else if (Platform.isIOS) {
      token = await NeoCoreFirebaseMessaging.firebaseMessaging.getAPNSToken();
    } else if (Platform.isAndroid) {
      token = await NeoCoreFirebaseMessaging.firebaseMessaging.getToken();
    }
    return token;
  }

  void _handleMessage(RemoteMessage? message) {
    if (message == null) {
      return;
    }
    final String? deeplinkPath = message.data[_Constant.pushNotificationDeeplinkKey];
    if (deeplinkPath != null && deeplinkPath.isNotEmpty) {
      widget.onDeeplinkNavigation?.call(deeplinkPath);
    }
  }
}
