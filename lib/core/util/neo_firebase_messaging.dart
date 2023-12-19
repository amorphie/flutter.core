import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rxdart/rxdart.dart';

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  return Future.value();
}

class NeoFirebaseMessaging {
  static final NeoFirebaseMessaging _singleton = NeoFirebaseMessaging._internal();
  factory NeoFirebaseMessaging() {
    return _singleton;
  }

  NeoFirebaseMessaging._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final BehaviorSubject<String?> _publishToken = BehaviorSubject();
  RemoteMessage? _initialMessage;
  final BehaviorSubject<RemoteMessage?> _backgroundMessage = BehaviorSubject();
  final BehaviorSubject<RemoteMessage?> _foregroundMessage = BehaviorSubject();
  Stream<String?> get pushTokens => _publishToken.stream;
  Stream<RemoteMessage?> get foregroundMessages => _foregroundMessage.stream;
  Stream<RemoteMessage?> get backgroundMessage => _backgroundMessage.stream;

  Future init() async {
    _setToken();
    _setInitialNotificationMessage();
  }

  _setToken() async {
    String? token;
    if (Platform.isIOS) {
      token = await _messaging.getAPNSToken();
    } else if (Platform.isAndroid) {
      token = await _messaging.getToken();
    }
    _publishToken.sink.add(token);
    _messaging.onTokenRefresh.listen((newPushToken) {
      _publishToken.sink.add(newPushToken);
    });
  }

  _setInitialNotificationMessage() async {
    ///Terminate state'de push'a basıldığı zaman o pushun payload datasını alan fonksiyon
    _initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    ///Foreground payload alan fonksyion
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _foregroundMessage.sink.add(message);
    });

    ///Sadece Android'de çalışan notification alındığı zaman payload'u alan fonksiyon
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

    ///Android ve iOS'de çalışan uygulama background'da çalışırken gelen push
    ///notification'a tıklandığı zaman payload alan fonksiyon
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _backgroundMessage.sink.add(message);
    });
  }

  String? getPushToken() {
    return _publishToken.value;
  }

  RemoteMessage? getInitialMessage() {
    return _initialMessage;
  }

  RemoteMessage? getBackgroundMessage() {
    return _backgroundMessage.value;
  }

  RemoteMessage? getForegroundMessage() {
    return _foregroundMessage.value;
  }

  Future<NotificationSettings> showNotificationRequest() {
    return _messaging.requestPermission();
  }

  void close() {
    _publishToken.close();
    _foregroundMessage.close();
    _backgroundMessage.close();
  }
}
