/*
 * neo_core
 *
 * Created on 2/10/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Configuration for vNext long polling behavior
 */

/// Configuration for vNext workflow long polling
/// 
/// Simple configuration with:
/// - Polling interval: How often to poll
/// - Polling duration: Maximum time to keep polling
/// - Request timeout: HTTP timeout per request
class VNextPollingConfig {
  /// How often to poll for updates
  final Duration interval;
  
  /// Maximum duration to keep polling
  final Duration duration;
  
  /// HTTP request timeout for each poll
  final Duration requestTimeout;
  
  /// Maximum number of consecutive errors before stopping
  final int maxConsecutiveErrors;

  const VNextPollingConfig({
    required this.interval,
    required this.duration,
    this.requestTimeout = const Duration(seconds: 30),
    this.maxConsecutiveErrors = 5,
  });

  /// Default configuration: Poll every 5 seconds for 1 minute
  factory VNextPollingConfig.defaultConfig() {
    return const VNextPollingConfig(
      interval: Duration(seconds: 5),
      duration: Duration(seconds: 20),
    );
  }

  /// Check if polling should continue based on elapsed time
  /// Returns true if still within duration, false if duration exceeded
  bool shouldContinuePolling(Duration elapsed) {
    return elapsed < duration;
  }

  /// Convert to JSON for logging/debugging
  Map<String, dynamic> toJson() {
    return {
      'intervalSeconds': interval.inSeconds,
      'durationSeconds': duration.inSeconds,
      'requestTimeoutSeconds': requestTimeout.inSeconds,
      'maxConsecutiveErrors': maxConsecutiveErrors,
    };
  }

  @override
  String toString() {
    return 'VNextPollingConfig(interval: ${interval.inSeconds}s, duration: ${duration.inMinutes}min, timeout: ${requestTimeout.inSeconds}s)';
  }
}
