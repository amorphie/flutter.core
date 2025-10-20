/*
 * neo_core
 *
 * Long polling manager for vNext workflow real-time updates
 */

import 'dart:async';

import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_polling_config.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_instance_snapshot.dart';

class VNextLongPollingManager {
  final NeoNetworkManager _networkManager;
  final NeoLogger _logger;

  final Map<String, _PollingSession> _activeSessions = {};
  final StreamController<VNextInstanceSnapshot> _messageController = StreamController.broadcast();

  VNextLongPollingManager({
    required NeoNetworkManager networkManager,
    required NeoLogger logger,
  }) : _networkManager = networkManager, _logger = logger;

  Stream<VNextInstanceSnapshot> get messageStream => _messageController.stream;

  Future<void> startPolling(
    String instanceId, {
    required String domain,
    required String workflowName,
    VNextPollingConfig? config,
  }) async {
    final pollingConfig = config ?? VNextPollingConfig.defaultConfig();

    await stopPolling(instanceId);

    final session = _PollingSession(
      instanceId: instanceId,
      domain: domain,
      workflowName: workflowName,
      config: pollingConfig,
      networkManager: _networkManager,
      logger: _logger,
      onMessage: _handleMessage,
      onError: _handleError,
      onStop: _handleStop,
    );

    _activeSessions[instanceId] = session;
    await session.start();
  }

  Future<void> stopPolling(String instanceId) async {
    final session = _activeSessions.remove(instanceId);
    if (session != null) {
      await session.stop();
    }
  }

  Future<void> stopAllPolling() async {
    final sessions = Map<String, _PollingSession>.from(_activeSessions);
    _activeSessions.clear();
    await Future.wait(sessions.values.map((s) => s.stop()));
  }

  List<String> getActiveInstances() => _activeSessions.keys.toList();

  Map<String, dynamic> getPollingStats() {
    final stats = <String, dynamic>{
      'activeInstances': _activeSessions.length,
      'sessions': <String, dynamic>{},
    };
    for (final entry in _activeSessions.entries) {
      stats['sessions'][entry.key] = entry.value.getStats();
    }
    return stats;
  }

  void _handleMessage(VNextInstanceSnapshot snapshot) {
    _logger.logConsole('[VNextLongPollingManager] Received snapshot for instance: ${snapshot.instanceId}');
    _messageController.add(snapshot);
  }

  void _handleError(String instanceId, String error) {
    _logger.logError('[VNextLongPollingManager] Polling error for instance $instanceId: $error');
    // Emit no error message object; logging is sufficient at this layer
  }

  void _handleStop(String instanceId, String reason) {
    _logger.logConsole('[VNextLongPollingManager] Polling stopped for $instanceId (reason: $reason)');
  }

  Future<void> dispose() async {
    await stopAllPolling();
    await _messageController.close();
  }
}

class _PollingSession {
  final String instanceId;
  final String domain;
  final String workflowName;
  final VNextPollingConfig config;
  final NeoNetworkManager networkManager;
  final NeoLogger logger;
  final void Function(VNextInstanceSnapshot) onMessage;
  final void Function(String, String) onError;
  final void Function(String, String)? onStop;

  Timer? _pollingTimer;
  bool _isActive = false;
  DateTime? _startTime;

  _PollingSession({
    required this.instanceId,
    required this.domain,
    required this.workflowName,
    required this.config,
    required this.networkManager,
    required this.logger,
    required this.onMessage,
    required this.onError,
    this.onStop,
  });

  Future<void> start() async {
    if (_isActive) return;
    _isActive = true;
    _startTime = DateTime.now();

    await _poll();
    _scheduleNextPoll();
  }

  Future<void> stop({String reason = 'manual'}) async {
    if (!_isActive) return;
    _isActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    onStop?.call(instanceId, reason);
  }

  void _scheduleNextPoll() {
    if (!_isActive) return;
    final elapsed = DateTime.now().difference(_startTime!);
    if (!config.shouldContinuePolling(elapsed)) {
      stop(reason: 'duration-exceeded');
      return;
    }
    _pollingTimer = Timer(config.interval, () {
      if (_isActive) {
        _poll().then((_) => _scheduleNextPoll());
      }
    });
  }

  Future<void> _poll() async {
    if (!_isActive) return;
    final elapsed = DateTime.now().difference(_startTime!);
    if (!config.shouldContinuePolling(elapsed)) {
      stop(reason: 'duration-exceeded');
      return;
    }
    try {
      final response = await networkManager.call(
        NeoHttpCall(
          endpoint: 'vnext-get-workflow-instance',
          pathParameters: {
            'DOMAIN': domain,
            'WORKFLOW_NAME': workflowName,
            'INSTANCE_ID': instanceId,
          },
        ),
      ).timeout(config.requestTimeout);

      if (response.isSuccess) {
        final data = response.asSuccess.data;
        final snapshot = _toSnapshot(data);
        if (snapshot != null) {
          onMessage(snapshot);
          // Stop when waiting for user input or workflow finished
          if (_shouldStopPolling(snapshot)) {
            await stop(reason: 'user-interaction-or-finished');
          }
        }
      } else {
        onError(instanceId, 'Poll failed: ${response.asError.error.error.description}');
        // No max error auto-stop; rely on status-based stop
      }
    } catch (e) {
      onError(instanceId, 'Poll exception: $e');
      // No max error auto-stop; rely on status-based stop
    }
  }

  VNextInstanceSnapshot? _toSnapshot(Map<String, dynamic> data) {
    try {
      final snapshot = VNextInstanceSnapshot.fromInstanceJson(data);
      if (snapshot.instanceId.isNotEmpty && snapshot.status.isNotEmpty) return snapshot;
    } catch (e) {
      logger.logError('[VNextLongPollingManager] Failed to parse instance snapshot for $instanceId/$workflowName: $e');
    }
    return null;
  }

  bool _shouldStopPolling(VNextInstanceSnapshot snapshot) {
    final status = snapshot.status; // A, B, C, E, S
    switch (status.toUpperCase()) {
      case 'A':
        return true; // active - client should proceed, no need to poll further
      case 'C':
      case 'E':
        return true; // completed or error
      default:
        return false; // keep polling for B (busy), S (suspended), etc.
    }
  }

  Map<String, dynamic> getStats() {
    final elapsed = _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;
    return {
      'instanceId': instanceId,
      'domain': domain,
      'workflowName': workflowName,
      'isActive': _isActive,
      'startTime': _startTime?.toIso8601String(),
      'elapsedSeconds': elapsed.inSeconds,
      'config': config.toJson(),
    };
  }
}


