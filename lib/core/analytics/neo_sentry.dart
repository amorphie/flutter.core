import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class NeoSentry {
  Future<void> init({required Client httpClient, required String dsn, required Widget child}) async {
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = dsn
          ..httpClient = httpClient
          ..debug = kDebugMode;
      },
      appRunner: () => runApp(SentryWidget(child: child)),
    );
  }
}
