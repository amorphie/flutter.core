import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  return Future.value();
}

abstract class _Constant {
  static const androidNotificationChannelID = "high_importance_channel";
  static const androidNotificationChannelName = "High Importance Notifications";
  static const androidNotificationChannelDescription = "This channel is used for important notifications";
}

class NeoCoreFirebaseMessaging {
  static final NeoCoreFirebaseMessaging _singleton = NeoCoreFirebaseMessaging._internal();
  factory NeoCoreFirebaseMessaging() {
    return _singleton;
  }

  NeoCoreFirebaseMessaging._internal();

  String? _vapidKey;
  String? _androidDefaultIcon;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final _publishToken = BehaviorSubject<String?>();
  Stream<String?> get pushTokens => _publishToken.stream;

  final _androidChannel = const AndroidNotificationChannel(
    _Constant.androidNotificationChannelID,
    _Constant.androidNotificationChannelName,
    description: _Constant.androidNotificationChannelDescription,
  );
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future init(String? vapidKey, String? androidDefaultIcon) async {
    _vapidKey = vapidKey;
    _androidDefaultIcon = androidDefaultIcon;
    _initNotifications();
    _initPushNotifications();
    _initLocalNotifications();
  }

  _initNotifications() async {
    await _firebaseMessaging.requestPermission();

    final token = await _getTokenBasedOnPlatform();
    _publishToken.sink.add(token);
    _firebaseMessaging.onTokenRefresh.listen((newPushToken) {
      _publishToken.sink.add(newPushToken);
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
      if (notification == null) {
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
            icon: _androidDefaultIcon,
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
    });
  }

  _initLocalNotifications() async {
    if (kIsWeb) {
      return;
    }
    const iOS = DarwinInitializationSettings();
    final String androidIcon = _androidDefaultIcon ?? "";
    final android = AndroidInitializationSettings(androidIcon);
    final settings = InitializationSettings(android: android, iOS: iOS);
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
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final platform =
          _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await platform?.createNotificationChannel(_androidChannel);
    }
  }

  Future<String?> _getTokenBasedOnPlatform() async {
    String? token;
    if (kIsWeb) {
      token = await _firebaseMessaging.getToken(
        vapidKey: _vapidKey,
      );
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

  void close() {
    _publishToken.close();
  }
}
