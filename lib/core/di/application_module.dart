/*
 * neo_core
 *
 * Created on 18/9/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:neo_core/core/workflow_form/vnext/vnext_config.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_client.dart';

/// Minimal application module for vNext dependency injection
/// This follows the minimal changes approach - no architectural refactoring
class ApplicationModule {
  /// Configure minimal dependencies for vNext integration only
  static Future<GetIt> configureDependencies(
    GetIt getIt, {
    VNextConfig? vNextConfig,
    bool isDevelopment = false,
  }) async {
    // Use provided config or create from environment
    final config = vNextConfig ?? VNextConfig.fromEnvironment();

    // Register HTTP client
    if (!getIt.isRegistered<http.Client>()) {
      getIt.registerSingleton<http.Client>(http.Client());
    }

    // Register vNext configuration
    getIt.registerSingleton<VNextConfig>(config);

    // Register vNext workflow client - using a simple logger
    if (!getIt.isRegistered<VNextWorkflowClient>()) {
      getIt.registerFactory<VNextWorkflowClient>(() {
        final vNextConfig = getIt.get<VNextConfig>();
        return VNextWorkflowClient(
          baseUrl: vNextConfig.vNextBaseUrl ?? 'http://localhost:4201',
          httpClient: getIt.get<http.Client>(),
          logger: _SimpleLogger(), // Use simple logger to avoid NeoLogger dependency
        );
      });
    }

    return getIt;
  }

  /// Register with development configuration (for testing)
  static Future<GetIt> configureDevelopmentDependencies(GetIt getIt) {
    return configureDependencies(
      getIt,
      vNextConfig: VNextConfig.development,
      isDevelopment: true,
    );
  }

  /// Register with production configuration
  static Future<GetIt> configureProductionDependencies(GetIt getIt) {
    return configureDependencies(
      getIt,
      vNextConfig: VNextConfig.fromEnvironment(),
      isDevelopment: false,
    );
  }
}

/// Simple logger implementation to avoid dependency on NeoLogger refactoring
class _SimpleLogger {
  void logConsole(String message) {
    print('[VNext] $message');
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    print('[VNext ERROR] $message');
    if (error != null) print('[VNext ERROR] Error: $error');
    if (stackTrace != null) print('[VNext ERROR] StackTrace: $stackTrace');
  }
}
