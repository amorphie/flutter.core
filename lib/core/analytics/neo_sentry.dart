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
    required Widget child,
  }) async {
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = dsn
          ..httpClient = httpClient
          ..environment = environment
          ..release = release
          ..experimental.replay.onErrorSampleRate = 1.0
          ..tracesSampleRate = 1.0 // TODO: Get it from config
          ..debug = false; // TODO: Get it from config
      },
      appRunner: () => runApp(SentryWidget(child: child)),
    );
  }

  Future<void> setUser({required String id}) async {
    await Sentry.configureScope(
      (scope) async {
        await scope.setUser(SentryUser(id: id, data: await _neoNetworkManager.neoConstantHeaders.getHeaders()));
      },
    );
  }

  Future<void> clearUser() async {
    await Sentry.configureScope((scope) => scope.setUser(null));
  }
}
