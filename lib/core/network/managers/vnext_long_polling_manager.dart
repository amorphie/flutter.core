/*
 * neo_core
 *
 * Long polling manager for vNext workflow real-time updates
 */

import 'dart:async';

import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/managers/vnext_polling_event.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_instance_snapshot.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_polling_config.dart';

class VNextLongPollingManager {
  final NeoNetworkManager _networkManager;
  final NeoLogger _logger;

  final Map<String, _PollingSession> _activeSessions = {};
  final StreamController<VNextInstanceSnapshot> _messageController = StreamController.broadcast();
  final StreamController<VNextPollingEvent> _eventController = StreamController.broadcast();

  VNextLongPollingManager({
    required NeoNetworkManager networkManager,
    required NeoLogger logger,
  }) : _networkManager = networkManager, _logger = logger;

  Stream<VNextInstanceSnapshot> get messageStream => _messageController.stream;
  Stream<VNextPollingEvent> get eventStream => _eventController.stream;

  Future<void> startPolling(
    String instanceId, {
    required String domain,
    required String workflowName,
    VNextPollingConfig? config,
  }) async {
    print('[VNextLongPollingManager] DEBUG: startPolling called for instance $instanceId');
    try {
      final pollingConfig = config ?? VNextPollingConfig.defaultConfig();

      print('[VNextLongPollingManager] DEBUG: About to log console message');
      _logger.logConsole('[VNextLongPollingManager] Starting polling for instance $instanceId with config: $pollingConfig');
      
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
        onStart: _handleStart,
      );

      print('[VNextLongPollingManager] DEBUG: Session created successfully');
      _logger.logConsole('[VNextLongPollingManager] Session created successfully');
      _activeSessions[instanceId] = session;
      print('[VNextLongPollingManager] DEBUG: Session added to active sessions, starting polling...');
      _logger.logConsole('[VNextLongPollingManager] Session added to active sessions, starting polling...');
      await session.start();
      print('[VNextLongPollingManager] DEBUG: Polling session started successfully');
      _logger.logConsole('[VNextLongPollingManager] Polling session started successfully');
    } catch (e, stackTrace) {
      _logger.logConsole('[VNextLongPollingManager] Error starting polling for instance $instanceId: $e');
      _logger.logConsole('[VNextLongPollingManager] Stack trace: $stackTrace');
      rethrow;
    }
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
    // Emit error event
    final event = VNextPollingEvent.error(
      instanceId: instanceId,
      reason: error,
    );
    _eventController.add(event);
  }

// todo: check if we need to add check for the init or transition method status value and not start 
// the lognpolling if it is already "A"
// // todo: not urgent, we can check later.
  void _handleStart(String instanceId) {
    _logger.logConsole('[VNextLongPollingManager] Polling started for $instanceId');
    
    // Emit a polling started event
    final event = VNextPollingEvent.started(
      instanceId: instanceId,
      reason: 'workflow-busy',
    );
    _eventController.add(event);
  }

  void _handleStop(String instanceId, String reason) {
    _logger.logConsole('[VNextLongPollingManager] Polling stopped for $instanceId (reason: $reason)');
    
    // Emit a polling event instead of fake snapshot
    final event = VNextPollingEvent.stopped(
      instanceId: instanceId,
      reason: reason,
    );
    _eventController.add(event);
  }

  Future<void> dispose() async {
    await stopAllPolling();
    await _messageController.close();
    await _eventController.close();
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
  final void Function(String)? onStart;

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
    this.onStart,
  });

  Future<void> start() async {
    print('[VNextLongPollingManager] DEBUG: _PollingSession.start() called for instance $instanceId');
    if (_isActive) {
      print('[VNextLongPollingManager] DEBUG: Session already active, returning');
      return;
    }
    _isActive = true;
    _startTime = DateTime.now();

    print('[VNextLongPollingManager] DEBUG: About to log console message in session');
    logger.logConsole('[VNextLongPollingManager] Starting polling session for instance $instanceId');
    
    // Notify that polling has started
    onStart?.call(instanceId);
    
    print('[VNextLongPollingManager] DEBUG: About to call _poll()');
    await _poll();
    print('[VNextLongPollingManager] DEBUG: About to schedule next poll');
    _scheduleNextPoll();
    print('[VNextLongPollingManager] DEBUG: Session start completed');
  }

  Future<void> stop({String reason = 'manual'}) async {
    if (!_isActive) return;
    _isActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    onStop?.call(instanceId, reason);
  }

  void _scheduleNextPoll() {
    print('[VNextLongPollingManager] DEBUG: _scheduleNextPoll() called for instance $instanceId');
    if (!_isActive) {
      print('[VNextLongPollingManager] DEBUG: Session not active, returning from _scheduleNextPoll()');
      return;
    }
    final elapsed = DateTime.now().difference(_startTime!);
    print('[VNextLongPollingManager] DEBUG: Elapsed time in _scheduleNextPoll: ${elapsed.inSeconds}s');
    if (!config.shouldContinuePolling(elapsed)) {
      print('[VNextLongPollingManager] DEBUG: Duration limit reached in _scheduleNextPoll, stopping polling');
      logger.logConsole('[VNextLongPollingManager] Duration limit reached, stopping polling');
      stop(reason: 'duration-exceeded');
      return;
    }
    
    print('[VNextLongPollingManager] DEBUG: About to schedule timer for ${config.interval.inSeconds}s');
    logger.logConsole('[VNextLongPollingManager] Scheduling next poll in ${config.interval.inSeconds}s');
    _pollingTimer = Timer(config.interval, () {
      print('[VNextLongPollingManager] DEBUG: Timer callback triggered for instance $instanceId');
      if (_isActive) {
        print('[VNextLongPollingManager] DEBUG: Session is active, executing poll');
        logger.logConsole('[VNextLongPollingManager] Timer triggered, executing poll');
        _poll().then((_) => _scheduleNextPoll());
      } else {
        print('[VNextLongPollingManager] DEBUG: Session is inactive, not executing poll');
        logger.logConsole('[VNextLongPollingManager] Timer triggered but session is inactive');
      }
    });
    print('[VNextLongPollingManager] DEBUG: Timer scheduled successfully');
  }

  Future<void> _poll() async {
    print('[VNextLongPollingManager] DEBUG: _poll() called for instance $instanceId');
    if (!_isActive) {
      print('[VNextLongPollingManager] DEBUG: Session not active, returning from _poll()');
      return;
    }
    final elapsed = DateTime.now().difference(_startTime!);
    print('[VNextLongPollingManager] DEBUG: Elapsed time: ${elapsed.inSeconds}s');
    if (!config.shouldContinuePolling(elapsed)) {
      print('[VNextLongPollingManager] DEBUG: Duration limit reached, stopping polling');
      logger.logConsole('[VNextLongPollingManager] Stopping polling due to duration limit: ${elapsed.inSeconds}s');
      stop(reason: 'duration-exceeded');
      return;
    }
    
    print('[VNextLongPollingManager] DEBUG: About to log polling message');
    logger.logConsole('[VNextLongPollingManager] Polling instance $instanceId (elapsed: ${elapsed.inSeconds}s)');
    
    try {
      print('[VNextLongPollingManager] DEBUG: About to make network call');
      print('[VNextLongPollingManager] DEBUG: Polling instance ID: $instanceId, domain: $domain, workflow: $workflowName');
      final response = await networkManager.call(
        NeoHttpCall(
          endpoint: 'vnext-get-workflow-instance',
          pathParameters: {
            'DOMAIN': domain,
            'WORKFLOW_NAME': workflowName,
            'INSTANCE_ID': instanceId,
          },
          useHttps: false, // Force HTTP for vNext backend
        ),
      ).timeout(config.requestTimeout);

      if (response.isSuccess) {
        final data = response.asSuccess.data;
        print('[VNextLongPollingManager] DEBUG: Network response data: $data');
        final snapshot = _toSnapshot(data);
        if (snapshot != null) {
          print('[VNextLongPollingManager] DEBUG: Received snapshot with status: ${snapshot.status}');
          print('[VNextLongPollingManager] DEBUG: Snapshot instance ID: ${snapshot.instanceId}');
          onMessage(snapshot);
          // Stop when waiting for user input or workflow finished
          if (_shouldStopPolling(snapshot)) {
            print('[VNextLongPollingManager] DEBUG: Should stop polling for status: ${snapshot.status} (workflow not busy)');
            logger.logConsole('[VNextLongPollingManager] Stopping polling due to status: ${snapshot.status}');
            await stop(reason: 'workflow-not-busy');
          } else {
            print('[VNextLongPollingManager] DEBUG: Should continue polling for status: ${snapshot.status} (workflow is busy)');
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
      case 'B':
        return false; // keep polling while busy (workflow is processing)
      case 'A':
      case 'C':
      case 'E':
      case 'S':
      default:
        return true; // stop polling for A (active), C (completed), E (error), S (suspended)
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
