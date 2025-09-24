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

/// Minimal application module for vNext dependency injection
/// This follows the minimal changes approach - no architectural refactoring
class ApplicationModule {
  /// Configure minimal dependencies for vNext integration only
  /// Logger should be registered by client before calling this method
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

    // Note: VNextWorkflowClient registration should be handled by the client application
    // since it needs access to the proper logger implementation

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
    );
  }
}
