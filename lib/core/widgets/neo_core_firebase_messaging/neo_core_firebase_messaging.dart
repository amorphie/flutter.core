import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_core_widget_event_keys.dart';
import 'package:neo_core/core/bus/widget_event_bus/neo_widget_event.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/feature/device_registration/usecases/neo_core_register_device_usecase.dart';
import 'package:neo_core/feature/neo_push_message_payload_handlers/neo_firebase_android_push_message_payload_handler.dart';
import 'package:universal_io/io.dart';

abstract class _Constant {
  static const androidNotificationChannelID = "high_importance_channel";
  static const androidNotificationChannelName = "High Importance Notifications";
  static const androidNotificationChannelDescription = "This channel is used for important notifications";
  static const androidNotificationImportance = Importance.max;
}

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  debugPrint("[NeoCoreFirebaseMessaging]: Background notification was triggered by ${message.notification}");
  return Future.value();
}

class NeoCoreFirebaseMessaging extends StatefulWidget {
  const NeoCoreFirebaseMessaging({
    required this.child,
    required this.networkManager,
    required this.neoCoreSecureStorage,
    required this.onTokenChanged,
    this.androidDefaultIcon,
    this.notificationSound,
    this.onDeeplinkNavigation,
    super.key,
  });

  final Widget child;
  final NeoNetworkManager networkManager;
  final NeoCoreSecureStorage neoCoreSecureStorage;
  final Function(String) onTokenChanged;
  final String? androidDefaultIcon;
  final String? notificationSound;
  final Function(String)? onDeeplinkNavigation;

  static FirebaseMessaging get firebaseMessaging => _firebaseMessaging;

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  State<NeoCoreFirebaseMessaging> createState() => _NeoCoreFirebaseMessagingState();
}

class _NeoCoreFirebaseMessagingState extends State<NeoCoreFirebaseMessaging> {
  late AndroidNotificationChannel _androidChannel;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  NeoLogger get _neoLogger => GetIt.I.get();

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
    _initNotificationChannel();
    _initNotifications();
    _initPushNotifications();
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

  void _initNotificationChannel() {
    if (Platform.isAndroid) {
      _androidChannel = AndroidNotificationChannel(
        _Constant.androidNotificationChannelID,
        _Constant.androidNotificationChannelName,
        description: _Constant.androidNotificationChannelDescription,
        importance: _Constant.androidNotificationImportance,
        sound:
            (widget.notificationSound != null) ? RawResourceAndroidNotificationSound(widget.notificationSound) : null,
      );
    }
  }

  Future<void> _initNotifications() async {
    if (Platform.isIOS) {
      unawaited(
        _getAPNSTokenBasedOnPlatform().then((apnsToken) {
          if (apnsToken != null) {
            _onTokenChange(apnsToken, isAPNS: true);
          }
        }),
      );
    }
    unawaited(
      _getTokenBasedOnPlatform().then((firebaseToken) {
        if (firebaseToken != null) {
          _onTokenChange(firebaseToken);
        }
      }),
    );
    NeoCoreFirebaseMessaging.firebaseMessaging.onTokenRefresh.listen(_onTokenChange);
  }

  void _onTokenChange(String token, {bool isAPNS = false}) {
    _neoLogger.logConsole("[NeoCoreMessaging]: Token is: $token. Is APNS: $isAPNS");
    if (Platform.isAndroid || isAPNS) {
      widget.onTokenChanged.call(token);
    }
    if (!isAPNS) {
      registerDevice(token);
    }
  }

  void registerDevice(String tokenFirebase) {
    NeoCoreRegisterDeviceUseCase().call(
      networkManager: widget.networkManager,
      secureStorage: widget.neoCoreSecureStorage,
      deviceToken: tokenFirebase,
      isGoogleServiceAvailable: Platform.isAndroid,
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
      _neoLogger
          .logConsole("[NeoCoreFirebaseMessaging]: Foreground notification was triggered by ${message.notification}");
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
            sound: _androidChannel.sound,
            importance: _androidChannel.importance,
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
    if (kIsWeb) {
      return null;
    }
    return NeoCoreFirebaseMessaging.firebaseMessaging.getToken();
  }

  Future<String?> _getAPNSTokenBasedOnPlatform() async {
    return NeoCoreFirebaseMessaging.firebaseMessaging.getAPNSToken();
  }

  void _handleMessage(RemoteMessage? message) {
    NeoFirebaseAndroidPushMessagePayloadHandler().handleMessage(
      message: message,
      onDeeplinkNavigation: widget.onDeeplinkNavigation,
    );
  }

  @override
  void dispose() {
    _widgetEventStreamSubscription?.cancel();
    super.dispose();
  }
}
