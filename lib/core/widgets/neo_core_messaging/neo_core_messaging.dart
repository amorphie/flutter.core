import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/widgets/models/dengage_message.dart';
import 'package:neo_core/core/widgets/neo_core_firebase_messaging/neo_core_firebase_messaging.dart';
import 'package:neo_core/core/widgets/neo_core_huawei_messaging/neo_core_huawei_messaging.dart';

abstract class _Constants {
  static const messageSource = "DENGAGE";
}

class NeoCoreMessaging extends StatefulWidget {
  final Widget child;
  final NeoSharedPrefs neoSharedPrefs;
  final NeoNetworkManager networkManager;
  final NeoCoreSecureStorage neoCoreSecureStorage;
  final Function(String) onTokenChanged;
  final String? androidDefaultIcon;
  final Function(String)? onDeeplinkNavigation;

  const NeoCoreMessaging({
    required this.child,
    required this.neoSharedPrefs,
    required this.networkManager,
    required this.neoCoreSecureStorage,
    required this.onTokenChanged,
    this.androidDefaultIcon,
    this.onDeeplinkNavigation,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _NeoCoreMessagingState();
}

class _NeoCoreMessagingState extends State<NeoCoreMessaging> {
  static const EventChannel eventChannel = EventChannel("com.dengage.flutter/onNotificationClicked");

  NeoLogger get _neoLogger => GetIt.I.get();
  StreamSubscription<dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
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
          onDeeplinkNavigation: widget.onDeeplinkNavigation,
          child: widget.child,
        );
      } else {
        return NeoCoreFirebaseMessaging(
          networkManager: widget.networkManager,
          neoCoreSecureStorage: widget.neoCoreSecureStorage,
          onTokenChanged: widget.onTokenChanged,
          androidDefaultIcon: widget.androidDefaultIcon,
          onDeeplinkNavigation: widget.onDeeplinkNavigation,
          child: widget.child,
        );
      }
    }
  }

  void _onEvent(dynamic event) {
    try {
      final Map<String, dynamic> eventData = json.decode(event);
      final dengageMessage = DengageMessage.fromJson(eventData);
      if (_Constants.messageSource.toLowerCase() == dengageMessage.messageSource.toLowerCase() &&
          dengageMessage.dengageMedia.isNotEmpty &&
          dengageMessage.dengageMedia[0].target.isNotEmpty) {
        widget.onDeeplinkNavigation?.call(dengageMessage.dengageMedia[0].target);
      }
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
    super.dispose();
  }
}
