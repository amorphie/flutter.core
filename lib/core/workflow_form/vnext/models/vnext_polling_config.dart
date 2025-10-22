/*
 * neo_core
 *
 * Configuration for vNext long polling behavior
 */

class VNextPollingConfig {
  final Duration interval;
  final Duration duration;
  final Duration requestTimeout;

  const VNextPollingConfig({
    required this.interval,
    required this.duration,
    this.requestTimeout = const Duration(seconds: 30),
  });

  factory VNextPollingConfig.defaultConfig() => const VNextPollingConfig(
        interval: Duration(seconds: 1),
        duration: Duration(seconds: 20),
      );

  bool shouldContinuePolling(Duration elapsed) => elapsed < duration;

  Map<String, dynamic> toJson() => {
        'intervalSeconds': interval.inSeconds,
        'durationSeconds': duration.inSeconds,
        'requestTimeoutSeconds': requestTimeout.inSeconds,
      };

  @override
  String toString() =>
      'VNextPollingConfig(interval: ${interval.inSeconds}s, duration: ${duration.inSeconds}s, timeout: ${requestTimeout.inSeconds}s)';
}
