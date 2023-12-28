import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef TokenCallback = void Function(String token);

abstract class _Constant {
  static const androidNotificationChannelID = "high_importance_channel";
  static const androidNotificationChannelName = "High Importance Notifications";
  static const androidNotificationChannelDescription = "This channel is used for important notifications";
}

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  return Future.value();
}

class NeoCoreFirebaseMessaging extends StatefulWidget {
  const NeoCoreFirebaseMessaging({
    required this.child,
    required this.onTokenChange,
    this.androidDefaultIcon,
    super.key,
  });

  final Widget child;
  final TokenCallback onTokenChange;
  final String? androidDefaultIcon;

  @override
  State<NeoCoreFirebaseMessaging> createState() => _NeoCoreFirebaseMessagingState();
}

class _NeoCoreFirebaseMessagingState extends State<NeoCoreFirebaseMessaging> {
  late FirebaseMessaging _firebaseMessaging;

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
    _firebaseMessaging = FirebaseMessaging.instance;
    _initNotifications();
    _initPushNotifications();
    if (Platform.isAndroid) {
      _initLocalNotifications();
    }
  }

  _initNotifications() async {
    await _firebaseMessaging.requestPermission();

    final token = await _getTokenBasedOnPlatform();
    if (token != null) {
      widget.onTokenChange(token);
    }
    _firebaseMessaging.onTokenRefresh.listen((token) {
      widget.onTokenChange(token);
    });
  }

  _initPushNotifications() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    // Get any messages which caused the application to open from
    // a terminated state.
    await _firebaseMessaging.getInitialMessage().then(_handleMessage);

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    ///Sadece Android'de çalışan notification alındığı zaman payload'u alan fonksiyon
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

    /// This is called when an incoming FCM payload is received whilst
    /// the Flutter instance is in the foreground.
    FirebaseMessaging.onMessage.listen((message) {
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

  _initLocalNotifications() async {
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
    final platform =
        _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
  }

  Future<String?> _getTokenBasedOnPlatform() async {
    String? token;
    if (kIsWeb) {
      return null;
    } else if (Platform.isIOS) {
      token = await _firebaseMessaging.getAPNSToken();
    } else if (Platform.isAndroid) {
      token = await _firebaseMessaging.getToken();
    }
    return token;
  }

  void _handleMessage(RemoteMessage? message) {
    if (message == null) {
      return;
    }
    // TODO: Handle push message
  }
}
