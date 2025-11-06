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
    _logger.logConsole('[VNextLongPollingManager] startPolling instance=$instanceId');
    try {
      final pollingConfig = config ?? VNextPollingConfig.defaultConfig();
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

      _activeSessions[instanceId] = session;
      await session.start();
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
    _logger.logConsole('[VNextLongPollingManager] Snapshot: state=${snapshot.state}, status=${snapshot.status}, viewHref=${snapshot.viewHref}');
    _logger.logConsole('[VNextLongPollingManager] Snapshot: hasView=${snapshot.hasView}, isRenderable=${snapshot.isRenderable}');
    _messageController.add(snapshot);
    _logger.logConsole('[VNextLongPollingManager] Snapshot added to message stream');
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
    if (_isActive) {
      logger.logConsole('[VNextLongPollingManager] session already active, returning');
      return;
    }
    _isActive = true;
    _startTime = DateTime.now();

    logger.logConsole('[VNextLongPollingManager] Starting polling session');
    logger.logConsole('[VNextLongPollingManager] Instance: $instanceId, domain: $domain, workflow: $workflowName');
    
    // Notify that polling has started
    onStart?.call(instanceId);
    
    await _poll();
    logger.logConsole('[VNextLongPollingManager] Initial poll completed, scheduling next poll');
    _scheduleNextPoll();
    logger.logConsole('[VNextLongPollingManager] Session start completed');
  }

  Future<void> stop({String reason = 'manual'}) async {
    if (!_isActive) return;
    _isActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    onStop?.call(instanceId, reason);
  }

  void _scheduleNextPoll() {
    if (!_isActive) {
      return;
    }
    final elapsed = DateTime.now().difference(_startTime!);
    if (!config.shouldContinuePolling(elapsed)) {
      logger.logConsole('[VNextLongPollingManager] Duration limit reached, stopping polling');
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
    if (!_isActive) {
      logger.logConsole('[VNextLongPollingManager] _poll: Session not active, skipping');
      return;
    }
    final elapsed = DateTime.now().difference(_startTime!);
    if (!config.shouldContinuePolling(elapsed)) {
      logger.logConsole('[VNextLongPollingManager] Stopping polling due to duration limit: ${elapsed.inSeconds}s');
      stop(reason: 'duration-exceeded');
      return;
    }
    
    logger.logConsole('[VNextLongPollingManager] Polling instance: $instanceId, domain: $domain, workflow: $workflowName');
    
    try {
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

      logger.logConsole('[VNextLongPollingManager] Network call completed: isSuccess=${response.isSuccess}');
      
      if (response.isSuccess) {
        logger.logConsole('[VNextLongPollingManager] Response data keys: ${response.asSuccess.data.keys.join(", ")}');
        final snapshot = _toSnapshot(response.asSuccess.data);
        logger.logConsole('[VNextLongPollingManager] Parsed snapshot: ${snapshot != null ? "success" : "null"}');
        
        if (snapshot != null) {
          logger.logConsole('[VNextLongPollingManager] Snapshot details: instanceId=${snapshot.instanceId}, state=${snapshot.state}, status=${snapshot.status}, viewHref=${snapshot.viewHref}');
          logger.logConsole('[VNextLongPollingManager] Snapshot: hasView=${snapshot.hasView}, isRenderable=${snapshot.isRenderable}');
          onMessage(snapshot);
          logger.logConsole('[VNextLongPollingManager] onMessage called');
          
          // Stop when waiting for user input or workflow finished
          final shouldStop = _shouldStopPolling(snapshot);
          logger.logConsole('[VNextLongPollingManager] _shouldStopPolling: $shouldStop (status.isBusy=${snapshot.status.isBusy})');
          if (shouldStop) {
            logger.logConsole('[VNextLongPollingManager] Stopping polling due to status: ${snapshot.status}');
            await stop(reason: 'workflow-not-busy');
          } else {
            logger.logConsole('[VNextLongPollingManager] Continuing polling (workflow is busy)');
          }
        } else {
          logger.logError('[VNextLongPollingManager] Failed to parse snapshot from response data');
        }
      } else {
        logger.logError('[VNextLongPollingManager] Poll failed: ${response.asError.error.error.description}');
        onError(instanceId, 'Poll failed: ${response.asError.error.error.description}');
      }
    } catch (e, stackTrace) {
      logger.logError('[VNextLongPollingManager] Poll exception: $e');
      logger.logError('[VNextLongPollingManager] Stack trace: $stackTrace');
      onError(instanceId, 'Poll exception: $e');
    }
  }

  VNextInstanceSnapshot? _toSnapshot(Map<String, dynamic> data) {
    logger.logConsole('[VNextLongPollingManager] Input data keys: ${data.keys.join(", ")}');
    
    // The response is expected to be at top level with fields like:
    // - data: {href: ...} (function reference)
    // - view: {loadData: ..., href: ...}
    // - state, status, activeCorrelations, transitions, eTag at top level
    Map<String, dynamic> instanceData = Map<String, dynamic>.from(data);
    
    // Always inject instanceId from session (backend doesn't return it in new format)
    instanceData['id'] = instanceId;
    
    // Always inject domain and workflowName from stored values (backend may return empty strings)
    // This ensures we always have these values for subsequent requests
    if (domain.isNotEmpty) {
      instanceData['domain'] = domain;
    }
    if (workflowName.isNotEmpty) {
      instanceData['flow'] = workflowName;
    }
    
    try {
      final snapshot = VNextInstanceSnapshot.fromInstanceJson(instanceData);
      logger.logConsole('[VNextLongPollingManager] Parsed snapshot successfully');
      logger.logConsole('[VNextLongPollingManager] Snapshot: instanceId=${snapshot.instanceId}, statusCode=${snapshot.statusCode}');
      
      if (snapshot.instanceId.isNotEmpty && snapshot.statusCode.isNotEmpty) {
        logger.logConsole('[VNextLongPollingManager] Snapshot is valid');
        return snapshot;
      } else {
        logger.logError('[VNextLongPollingManager] Snapshot validation failed: instanceId.isEmpty=${snapshot.instanceId.isEmpty}, statusCode.isEmpty=${snapshot.statusCode.isEmpty}');
      }
    } catch (e, stackTrace) {
      logger.logError('[VNextLongPollingManager] Failed to parse instance snapshot for $instanceId/$workflowName: $e');
      logger.logError('[VNextLongPollingManager] Stack trace: $stackTrace');
    }
    logger.logConsole('[VNextLongPollingManager] _toSnapshot returning null');
    return null;
  }

  bool _shouldStopPolling(VNextInstanceSnapshot snapshot) {
    final status = snapshot.status; // enum
    if (status.isBusy) return false; // keep polling while busy
    return true; // stop polling otherwise (active/user input, completed, faulted)
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
