import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class NeoSentry {
  late final NeoNetworkManager _neoNetworkManager = GetIt.I<NeoNetworkManager>();

  Future<void> init({
    required Client httpClient,
    required String dsn,
    required String environment,
    required String release,
    required bool enableInDebug,
    required double tracesSampleRate,
    required Widget child,
    required String? userId,
  }) async {
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = dsn
          ..httpClient = httpClient
          ..environment = environment
          ..release = release
          ..experimental.replay.onErrorSampleRate = 1.0
          ..tracesSampleRate = tracesSampleRate
          ..enableTimeToFullDisplayTracing = true
          ..debug = enableInDebug;
      },
      appRunner: () => runApp(SentryWidget(child: child)),
    );
    await setUser(id: userId);
  }

  Future<void> setUser({required String? id}) async {
    await Sentry.configureScope(
      (scope) async {
        await scope.setUser(
          SentryUser(
            id: id ?? scope.user?.id,
            data: await _neoNetworkManager.neoConstantHeaders.getHeaders(),
            ipAddress: '{{auto}}',
          ),
        );
      },
    );
  }

  Future<void> clearUser() async {
    await Sentry.configureScope((scope) => scope.setUser(null));
  }

  Future<void> logCustom(dynamic message, String level, {List<dynamic>? parameters}) async {
    await Sentry.captureMessage(
      message.toString(),
      level: SentryLevel.fromName(level),
      params: parameters,
    );
  }

  Future<void> logException(dynamic exception, StackTrace stackTrace) async {
    await Sentry.captureException(exception, stackTrace: stackTrace);
  }
}
