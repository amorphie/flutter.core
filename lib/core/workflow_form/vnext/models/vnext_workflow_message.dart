/*
 * neo_core
 *
 * Created on 2/10/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * vNext workflow message models for long polling
 */

import 'package:equatable/equatable.dart';

/// Types of vNext workflow messages
enum VNextWorkflowMessageType {
  transition,
  stateChange,
  error,
  completion,
  data,
}

/// vNext workflow message received via long polling
/// 
/// This is the vNext equivalent of NeoSignalRTransition
/// but designed specifically for long polling responses
class VNextWorkflowMessage extends Equatable {
  final String instanceId;
  final VNextWorkflowMessageType type;
  final String? transitionId;
  final String? state;
  final String? pageId;
  final Map<String, dynamic> data;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String? error;

  const VNextWorkflowMessage({
    required this.instanceId,
    required this.type,
    this.transitionId,
    this.state,
    this.pageId,
    this.data = const {},
    this.metadata = const {},
    required this.timestamp,
    this.error,
  });

  /// Create a transition message
  factory VNextWorkflowMessage.transition({
    required String instanceId,
    required String transitionId,
    required String state,
    String? pageId,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> metadata = const {},
    DateTime? timestamp,
  }) {
    return VNextWorkflowMessage(
      instanceId: instanceId,
      type: VNextWorkflowMessageType.transition,
      transitionId: transitionId,
      state: state,
      pageId: pageId,
      data: data,
      metadata: metadata,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Create a state change message
  factory VNextWorkflowMessage.stateChange({
    required String instanceId,
    required String state,
    String? pageId,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> metadata = const {},
    DateTime? timestamp,
  }) {
    return VNextWorkflowMessage(
      instanceId: instanceId,
      type: VNextWorkflowMessageType.stateChange,
      state: state,
      pageId: pageId,
      data: data,
      metadata: metadata,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Create an error message
  factory VNextWorkflowMessage.error({
    required String instanceId,
    required String error,
    Map<String, dynamic> metadata = const {},
    DateTime? timestamp,
  }) {
    return VNextWorkflowMessage(
      instanceId: instanceId,
      type: VNextWorkflowMessageType.error,
      error: error,
      metadata: metadata,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Create a completion message
  factory VNextWorkflowMessage.completion({
    required String instanceId,
    required String state,
    Map<String, dynamic> data = const {},
    Map<String, dynamic> metadata = const {},
    DateTime? timestamp,
  }) {
    return VNextWorkflowMessage(
      instanceId: instanceId,
      type: VNextWorkflowMessageType.completion,
      state: state,
      data: data,
      metadata: metadata,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Create a data update message
  factory VNextWorkflowMessage.data({
    required String instanceId,
    required String pageId,
    required Map<String, dynamic> data,
    Map<String, dynamic> metadata = const {},
    DateTime? timestamp,
  }) {
    return VNextWorkflowMessage(
      instanceId: instanceId,
      type: VNextWorkflowMessageType.data,
      pageId: pageId,
      data: data,
      metadata: metadata,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Create from JSON (from long polling response)
  factory VNextWorkflowMessage.fromJson(Map<String, dynamic> json) {
    return VNextWorkflowMessage(
      instanceId: json['instanceId'] as String,
      type: _parseMessageType(json['type'] as String?),
      transitionId: json['transitionId'] as String?,
      state: json['state'] as String?,
      pageId: json['pageId'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      error: json['error'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'instanceId': instanceId,
      'type': type.name,
      'transitionId': transitionId,
      'state': state,
      'pageId': pageId,
      'data': data,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'error': error,
    };
  }

  static VNextWorkflowMessageType _parseMessageType(String? typeString) {
    switch (typeString?.toLowerCase()) {
      case 'transition':
        return VNextWorkflowMessageType.transition;
      case 'statechange':
      case 'state_change':
        return VNextWorkflowMessageType.stateChange;
      case 'error':
        return VNextWorkflowMessageType.error;
      case 'completion':
      case 'completed':
        return VNextWorkflowMessageType.completion;
      case 'data':
        return VNextWorkflowMessageType.data;
      default:
        return VNextWorkflowMessageType.transition; // Default fallback
    }
  }

  /// Check if this is an error message
  bool get isError => type == VNextWorkflowMessageType.error;

  /// Check if this is a completion message
  bool get isCompletion => type == VNextWorkflowMessageType.completion;

  /// Check if this message requires UI navigation
  bool get requiresNavigation => pageId != null && (
    type == VNextWorkflowMessageType.transition ||
    type == VNextWorkflowMessageType.stateChange
  );

  /// Check if this message contains data updates
  bool get hasDataUpdate => data.isNotEmpty || type == VNextWorkflowMessageType.data;

  @override
  List<Object?> get props => [
    instanceId,
    type,
    transitionId,
    state,
    pageId,
    data,
    metadata,
    timestamp,
    error,
  ];

  @override
  String toString() {
    return 'VNextWorkflowMessage(instanceId: $instanceId, type: $type, state: $state, pageId: $pageId)';
  }
}
