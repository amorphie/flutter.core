import 'package:equatable/equatable.dart';
import 'package:neo_core/core/network/managers/vnext_polling_event_type.dart';

/// Represents a polling lifecycle event (started, stopped, error, etc.)
/// 
/// This is separate from workflow data (VNextInstanceSnapshot) and is used
/// to communicate polling infrastructure events to the UI layer.
class VNextPollingEvent extends Equatable {
  /// The instance ID this event relates to
  final String instanceId;
  
  /// The type of polling event that occurred
  final VNextPollingEventType type;
  
  /// Human-readable reason for the event
  final String reason;
  
  /// When the event occurred
  final DateTime timestamp;
  
  /// Optional additional metadata about the event
  final Map<String, dynamic>? metadata;

  const VNextPollingEvent({
    required this.instanceId,
    required this.type,
    required this.reason,
    required this.timestamp,
    this.metadata,
  });

  /// Create a polling started event
  factory VNextPollingEvent.started({
    required String instanceId,
    String reason = 'workflow-busy',
    Map<String, dynamic>? metadata,
  }) {
    return VNextPollingEvent(
      instanceId: instanceId,
      type: VNextPollingEventType.started,
      reason: reason,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Create a polling stopped event
  factory VNextPollingEvent.stopped({
    required String instanceId,
    required String reason,
    Map<String, dynamic>? metadata,
  }) {
    return VNextPollingEvent(
      instanceId: instanceId,
      type: VNextPollingEventType.stopped,
      reason: reason,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Create a polling error event
  factory VNextPollingEvent.error({
    required String instanceId,
    required String reason,
    Map<String, dynamic>? metadata,
  }) {
    return VNextPollingEvent(
      instanceId: instanceId,
      type: VNextPollingEventType.error,
      reason: reason,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Create a polling timeout event
  factory VNextPollingEvent.timeout({
    required String instanceId,
    String reason = 'request-timeout',
    Map<String, dynamic>? metadata,
  }) {
    return VNextPollingEvent(
      instanceId: instanceId,
      type: VNextPollingEventType.timeout,
      reason: reason,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [
        instanceId,
        type,
        reason,
        timestamp,
        metadata,
      ];

  @override
  String toString() {
    return 'VNextPollingEvent(instanceId: $instanceId, type: $type, reason: $reason, timestamp: $timestamp)';
  }
}
