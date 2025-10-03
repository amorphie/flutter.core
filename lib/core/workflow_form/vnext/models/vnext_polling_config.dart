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
/// Supports configurable polling intervals and duration:
/// - Default: 5 seconds for 1 minute, then stop
/// - Customizable intervals and total duration
/// - Request timeout configuration
class VNextPollingConfig {
  /// List of polling intervals with their durations
  /// Each entry: [intervalSeconds, durationSeconds]
  final List<PollingInterval> intervals;
  
  /// HTTP request timeout for each poll
  final Duration requestTimeout;
  
  /// Maximum number of consecutive errors before stopping
  final int maxConsecutiveErrors;

  const VNextPollingConfig({
    required this.intervals,
    this.requestTimeout = const Duration(seconds: 30),
    this.maxConsecutiveErrors = 5,
  });

  /// Default configuration: 5 seconds for 1 minute
  factory VNextPollingConfig.defaultConfig() {
    return const VNextPollingConfig(
      intervals: [
        PollingInterval(
          interval: Duration(seconds: 5),
          duration: Duration(minutes: 1),
        ),
      ],
    );
  }

  /// Aggressive configuration: 2 seconds for 30 seconds, then 10 seconds for 2 minutes
  factory VNextPollingConfig.aggressive() {
    return const VNextPollingConfig(
      intervals: [
        PollingInterval(
          interval: Duration(seconds: 2),
          duration: Duration(seconds: 30),
        ),
        PollingInterval(
          interval: Duration(seconds: 10),
          duration: Duration(minutes: 2),
        ),
      ],
    );
  }

  /// Conservative configuration: 10 seconds for 5 minutes
  factory VNextPollingConfig.conservative() {
    return const VNextPollingConfig(
      intervals: [
        PollingInterval(
          interval: Duration(seconds: 10),
          duration: Duration(minutes: 5),
        ),
      ],
    );
  }

  /// Custom configuration with specific intervals
  factory VNextPollingConfig.custom({
    required List<PollingInterval> intervals,
    Duration requestTimeout = const Duration(seconds: 30),
    int maxConsecutiveErrors = 5,
  }) {
    return VNextPollingConfig(
      intervals: intervals,
      requestTimeout: requestTimeout,
      maxConsecutiveErrors: maxConsecutiveErrors,
    );
  }

  /// Get the polling interval for the given elapsed time
  /// Returns null if polling should stop (duration exceeded)
  Duration? getIntervalForElapsed(Duration elapsed) {
    Duration totalDuration = Duration.zero;
    
    for (final intervalConfig in intervals) {
      final endTime = totalDuration + intervalConfig.duration;
      
      if (elapsed < endTime) {
        // We're within this interval period
        return intervalConfig.interval;
      }
      
      totalDuration = endTime;
    }
    
    // Elapsed time exceeds all configured intervals
    return null;
  }

  /// Get total polling duration
  Duration get totalDuration {
    return intervals.fold(Duration.zero, (sum, interval) => sum + interval.duration);
  }

  /// Convert to JSON for logging/debugging
  Map<String, dynamic> toJson() {
    return {
      'intervals': intervals.map((i) => i.toJson()).toList(),
      'requestTimeoutSeconds': requestTimeout.inSeconds,
      'maxConsecutiveErrors': maxConsecutiveErrors,
      'totalDurationMinutes': totalDuration.inMinutes,
    };
  }

  @override
  String toString() {
    final intervalDescriptions = intervals.map((i) => 
      '${i.interval.inSeconds}s for ${i.duration.inMinutes}min'
    ).join(', then ');
    
    return 'VNextPollingConfig($intervalDescriptions, timeout: ${requestTimeout.inSeconds}s)';
  }
}

/// Represents a single polling interval configuration
class PollingInterval {
  /// How often to poll during this period
  final Duration interval;
  
  /// How long this polling interval lasts
  final Duration duration;

  const PollingInterval({
    required this.interval,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'intervalSeconds': interval.inSeconds,
      'durationSeconds': duration.inSeconds,
    };
  }

  @override
  String toString() {
    return 'PollingInterval(${interval.inSeconds}s for ${duration.inMinutes}min)';
  }
}
