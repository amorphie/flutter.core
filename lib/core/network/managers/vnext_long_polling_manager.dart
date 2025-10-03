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
import 'package:neo_core/core/network/query_providers/http_query_provider.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_workflow_message.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_polling_config.dart';

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
    );

    _activeSessions[instanceId] = session;
    await session.start();
  }

  /// Stop long polling for a specific workflow instance
  Future<void> stopPolling(String instanceId) async {
    final session = _activeSessions.remove(instanceId);
    if (session != null) {
      _logger.logConsole('[VNextLongPollingManager] Stopping polling for instance: $instanceId');
      await session.stop();
    }
  }

  /// Stop all active polling sessions
  Future<void> stopAllPolling() async {
    _logger.logConsole('[VNextLongPollingManager] Stopping all polling sessions');
    
    final futures = _activeSessions.values.map((session) => session.stop());
    await Future.wait(futures);
    _activeSessions.clear();
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
  });

  Future<void> start() async {
    if (_isActive) return;

    _isActive = true;
    _startTime = DateTime.now();
    _pollCount = 0;
    _messageCount = 0;
    _errorCount = 0;

    logger.logConsole('[PollingSession] Starting session for instance: $instanceId');
    
    // Start immediate poll, then schedule regular polling
    await _poll();
    _scheduleNextPoll();
  }

  Future<void> stop() async {
    if (!_isActive) return;

    _isActive = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;

    logger.logConsole('[PollingSession] Stopped session for instance: $instanceId');
  }

  void _scheduleNextPoll() {
    if (!_isActive) return;

    final elapsed = DateTime.now().difference(_startTime!);
    final interval = config.getIntervalForElapsed(elapsed);

    if (interval == null) {
      // Polling duration exceeded, stop session
      logger.logConsole('[PollingSession] Polling duration exceeded for instance: $instanceId');
      stop();
      return;
    }

    _pollingTimer = Timer(interval, () {
      if (_isActive) {
        _poll().then((_) => _scheduleNextPoll());
      }
    });
  }

  Future<void> _poll() async {
    if (!_isActive) return;

    _pollCount++;
    
    try {
      logger.logConsole('[PollingSession] Polling instance: $instanceId (poll #$_pollCount)');

      final response = await networkManager.call(
        NeoHttpCall(
          endpoint: 'vnext-poll-messages',
          pathParameters: {
            'WORKFLOW_NAME': workflowName,
          },
          queryProviders: [
            HttpQueryProvider({
              'InstanceId': instanceId, // Match existing Amorphie pattern
              'timeout': config.requestTimeout.inSeconds.toString(),
              'engine': 'vnext', // Distinguish from Amorphie requests
            }),
          ],
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
      final messageList = data['messages'] as List<dynamic>? ?? [];
      
      for (final messageData in messageList) {
        if (messageData is Map<String, dynamic>) {
          final message = VNextWorkflowMessage.fromJson(messageData);
          messages.add(message);
        }
      }
    } catch (e) {
      logger.logError('[PollingSession] Failed to parse messages: $e');
    }

    return messages;
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
