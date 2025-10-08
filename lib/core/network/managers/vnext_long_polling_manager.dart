/*
 * neo_core
 *
 * Created on 2/10/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Long polling manager for vNext workflow real-time updates
 */

import 'dart:async';

import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_polling_config.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_workflow_message.dart';

/// Long polling manager for vNext workflow real-time updates
/// 
/// Handles:
/// - Configurable polling intervals (default: 5sec for 1min)
/// - Per-instance polling sessions
/// - Automatic retry and backoff
/// - Message routing to correct workflow instances
class VNextLongPollingManager {
  final NeoNetworkManager _networkManager;
  final NeoLogger _logger;
  
  // Active polling sessions per instance
  final Map<String, _PollingSession> _activeSessions = {};
  
  // Event stream for workflow messages
  final StreamController<VNextWorkflowMessage> _messageController = StreamController.broadcast();
  
  VNextLongPollingManager({
    required NeoNetworkManager networkManager,
    required NeoLogger logger,
  }) : _networkManager = networkManager, _logger = logger;

  /// Stream of vNext workflow messages
  Stream<VNextWorkflowMessage> get messageStream => _messageController.stream;

  /// Start long polling for a specific workflow instance
  /// 
  /// [instanceId] - The workflow instance ID to poll for
  /// [workflowName] - The workflow name for the endpoint
  /// [config] - Polling configuration (intervals, duration, etc.)
  Future<void> startPolling(String instanceId, {required String workflowName, VNextPollingConfig? config}) async {
    final pollingConfig = config ?? VNextPollingConfig.defaultConfig();
    
    _logger.logConsole('[VNextLongPollingManager] Starting polling for instance: $instanceId');
    _logger.logConsole('[VNextLongPollingManager] Config: ${pollingConfig.toString()}');

    // Stop existing session if any
    await stopPolling(instanceId);

    // Create new polling session
    final session = _PollingSession(
      instanceId: instanceId,
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
  
  void _handleStop(String instanceId, String reason) {
    _logger.logConsole('[VNextLongPollingManager] Polling stopped for instance: $instanceId (reason: $reason)');
    
    // Remove from active sessions
    _activeSessions.remove(instanceId);
    
    // Emit a completion message to notify listeners
    _messageController.add(VNextWorkflowMessage.completion(
      instanceId: instanceId,
      state: 'polling-stopped',
      data: {'reason': reason},
      timestamp: DateTime.now(),
    ));
  }

  /// Stop long polling for a specific workflow instance
  Future<void> stopPolling(String instanceId) async {
    final session = _activeSessions.remove(instanceId);
    if (session != null) {
      _logger.logConsole('[VNextLongPollingManager] Stopping polling for instance: $instanceId');
      await session.stop();
      
      // Emit a completion message to notify listeners that polling has stopped
      _messageController.add(VNextWorkflowMessage.completion(
        instanceId: instanceId,
        state: 'polling-stopped',
        data: {'reason': 'manual-stop'},
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Stop all active polling sessions
  Future<void> stopAllPolling() async {
    _logger.logConsole('[VNextLongPollingManager] Stopping all polling sessions');
    
    // Create a copy of the sessions to avoid concurrent modification
    final sessions = Map<String, _PollingSession>.from(_activeSessions);
    _activeSessions.clear();
    
    final futures = sessions.values.map((session) => session.stop());
    await Future.wait(futures);
  }

  /// Get active polling sessions
  List<String> getActiveInstances() {
    return _activeSessions.keys.toList();
  }

  /// Get polling statistics
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

  void _handleMessage(VNextWorkflowMessage message) {
    _logger.logConsole('[VNextLongPollingManager] Received message for instance: ${message.instanceId}');
    _messageController.add(message);
  }

  void _handleError(String instanceId, String error) {
    _logger.logError('[VNextLongPollingManager] Polling error for instance $instanceId: $error');
    
    // Emit error message
    _messageController.add(VNextWorkflowMessage.error(
      instanceId: instanceId,
      error: error,
      timestamp: DateTime.now(),
    ));
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopAllPolling();
    await _messageController.close();
  }
}

/// Internal polling session for a single workflow instance
class _PollingSession {
  final String instanceId;
  final String workflowName;
  final VNextPollingConfig config;
  final NeoNetworkManager networkManager;
  final NeoLogger logger;
  final Function(VNextWorkflowMessage) onMessage;
  final Function(String, String) onError;
  final Function(String, String)? onStop; // Callback when polling stops

  Timer? _pollingTimer;
  bool _isActive = false;
  DateTime? _startTime;
  int _pollCount = 0;
  int _messageCount = 0;
  int _errorCount = 0;

  _PollingSession({
    required this.instanceId,
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
    _pollCount = 0;
    _messageCount = 0;
    _errorCount = 0;

    logger.logConsole('┌─────────────────────────────────────────────────────────');
    logger.logConsole('│ [PollingSession] 🚀 Starting long polling');
    logger.logConsole('├─────────────────────────────────────────────────────────');
    logger.logConsole('│ Instance: $instanceId');
    logger.logConsole('│ Workflow: $workflowName');
    logger.logConsole('│ Interval: ${config.interval.inSeconds}s');
    logger.logConsole('│ Duration: ${config.duration.inSeconds}s');
    logger.logConsole('│ Max Consecutive Errors: ${config.maxConsecutiveErrors}');
    logger.logConsole('└─────────────────────────────────────────────────────────\n');
    
    // Start immediate poll, then schedule regular polling
    await _poll();
    _scheduleNextPoll();
  }

  Future<void> stop({String reason = 'manual'}) async {
    if (!_isActive) return;

    _isActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;

    logger.logConsole('[PollingSession] Stopped session for instance: $instanceId (reason: $reason)');
    
    // Notify parent that polling has stopped
    onStop?.call(instanceId, reason);
  }

  void _scheduleNextPoll() {
    if (!_isActive) return;

    final elapsed = DateTime.now().difference(_startTime!);
    
    // Check if polling duration exceeded
    if (!config.shouldContinuePolling(elapsed)) {
      logger.logConsole('┌─────────────────────────────────────────────────────────');
      logger.logConsole('│ [PollingSession] ⏱️ Duration limit reached');
      logger.logConsole('├─────────────────────────────────────────────────────────');
      logger.logConsole('│ Instance: $instanceId');
      logger.logConsole('│ Elapsed: ${elapsed.inSeconds}s / ${config.duration.inSeconds}s');
      logger.logConsole('│ Total polls: $_pollCount');
      logger.logConsole('│ Total messages: $_messageCount');
      logger.logConsole('│ 🛑 Stopping polling');
      logger.logConsole('└─────────────────────────────────────────────────────────\n');
      stop(reason: 'duration-exceeded');
      return;
    }

    // Schedule next poll using configured interval
    logger.logConsole('[PollingSession] ⏰ Scheduling next poll in ${config.interval.inSeconds}s (elapsed: ${elapsed.inSeconds}s / ${config.duration.inSeconds}s)');
    _pollingTimer = Timer(config.interval, () {
      if (_isActive) {
        _poll().then((_) => _scheduleNextPoll());
      }
    });
  }

  Future<void> _poll() async {
    if (!_isActive) return;

    // Check if duration exceeded before polling
    final elapsed = DateTime.now().difference(_startTime!);
    if (!config.shouldContinuePolling(elapsed)) {
      logger.logConsole('[PollingSession] Polling duration exceeded, stopping before poll #${_pollCount + 1}');
      stop(reason: 'duration-exceeded');
      return;
    }

    _pollCount++;
    
    try {
      logger.logConsole('[PollingSession] 🔍 Poll #$_pollCount - Checking instance state...');
      logger.logConsole('[PollingSession] Endpoint: vnext-get-workflow-instance');
      logger.logConsole('[PollingSession] Path: /core/workflows/$workflowName/instances/$instanceId');

      // Poll the instance endpoint to check for state changes
      // vNext doesn't have a separate /messages endpoint - we poll the instance itself
      final response = await networkManager.call(
        NeoHttpCall(
          endpoint: 'vnext-get-workflow-instance',
          pathParameters: {
            'DOMAIN': 'core', // TODO: Get from config
            'WORKFLOW_NAME': workflowName,
            'INSTANCE_ID': instanceId,
          },
        ),
      );

      if (response.isSuccess) {
        final data = response.asSuccess.data;
        final messages = _parseMessages(data);
        
        for (final message in messages) {
          _messageCount++;
          onMessage(message);
        }

        if (messages.isNotEmpty) {
          logger.logConsole('[PollingSession] Received ${messages.length} messages for instance: $instanceId');
        }
      } else {
        _errorCount++;
        final error = response.asError.error.error.description;
        onError(instanceId, 'Poll failed: $error');
      }
    } catch (e) {
      _errorCount++;
      onError(instanceId, 'Poll exception: $e');
    }
  }

  List<VNextWorkflowMessage> _parseMessages(Map<String, dynamic> data) {
    final messages = <VNextWorkflowMessage>[];
    
    try {
      // For vNext, we poll the instance endpoint directly
      // Convert the instance response to a state change message
      final instanceId = data['id'] as String? ?? data['instanceId'] as String?;
      final extensions = data['extensions'] as Map<String, dynamic>?;
      final status = extensions?['status'] as String?;
      final currentState = extensions?['currentState'] as String?;
      final transitions = extensions?['transitions'] as List<dynamic>?;
      
      if (instanceId != null && status != null) {
        // Create a synthetic message representing the state change
        final message = VNextWorkflowMessage(
          instanceId: instanceId,
          type: VNextWorkflowMessageType.stateChange,
          timestamp: DateTime.now(),
          data: data,
        );
        messages.add(message);
        logger.logConsole('[PollingSession] State: $currentState, Status: $status');
        
        // Check if polling should stop based on workflow status
        if (_shouldStopPolling(status, transitions)) {
          logger.logConsole('┌─────────────────────────────────────────────────────────');
          logger.logConsole('│ [PollingSession] 🛑 Stopping polling - User interaction required');
          logger.logConsole('├─────────────────────────────────────────────────────────');
          logger.logConsole('│ Instance: $instanceId');
          logger.logConsole('│ Status: $status (${_getStatusDescription(status)})');
          logger.logConsole('│ Current State: $currentState');
          logger.logConsole('│ Available Transitions: ${transitions?.length ?? 0}');
          logger.logConsole('│ Reason: Workflow is waiting for user input');
          logger.logConsole('└─────────────────────────────────────────────────────────\n');
          
          // Stop polling for this instance
          stop(reason: 'user-interaction-required');
        }
      }
    } catch (e) {
      logger.logError('[PollingSession] Failed to parse instance data: $e');
    }

    return messages;
  }
  
  /// Determine if polling should stop based on workflow status
  bool _shouldStopPolling(String? status, List<dynamic>? transitions) {
    if (status == null) return false;
    
    switch (status.toUpperCase()) {
      case 'A': // Active - stop if user interaction is required
        return transitions != null && transitions.isNotEmpty;
      case 'C': // Completed - always stop
        return true;
      case 'E': // Error - always stop
        return true;
      case 'B': // Busy/Processing - continue polling
        return false;
      case 'S': // Suspended - continue polling (might resume)
        return false;
      default:
        return false; // Unknown status - continue polling to be safe
    }
  }
  
  /// Get human-readable description of status code
  String _getStatusDescription(String? status) {
    if (status == null) return 'Unknown';
    
    switch (status.toUpperCase()) {
      case 'A': return 'Active (waiting for user input)';
      case 'B': return 'Busy (processing)';
      case 'C': return 'Completed';
      case 'E': return 'Error';
      case 'S': return 'Suspended';
      default: return 'Unknown ($status)';
    }
  }

  Map<String, dynamic> getStats() {
    final elapsed = _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;
    
    return {
      'instanceId': instanceId,
      'isActive': _isActive,
      'startTime': _startTime?.toIso8601String(),
      'elapsedMinutes': elapsed.inMinutes,
      'pollCount': _pollCount,
      'messageCount': _messageCount,
      'errorCount': _errorCount,
      'config': config.toJson(),
    };
  }
}
