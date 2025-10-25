/*
 * neo_core
 *
 * Created on 23/9/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';

/// Types of UI events that workflow operations can trigger
enum WorkflowUIEventType {
  /// Show/hide loading indicator
  loading,
  
  /// Navigate to a new page
  navigate,
  
  /// Display an error
  error,
  
  /// Update page data
  updateData,
  
  /// Show a dialog or popup
  showDialog,
  
  /// No UI action needed (silent event)
  silent,
}

/// Configuration for UI behavior during workflow operations
class WorkflowUIConfig {
  final NeoNavigationType? navigationType;
  final bool useSubNavigator;
  final bool displayLoading;
  final Map<String, dynamic>? metadata;

  const WorkflowUIConfig({
    this.navigationType,
    this.useSubNavigator = false,
    this.displayLoading = true,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'navigationType': navigationType?.toString(),
      'useSubNavigator': useSubNavigator,
      'displayLoading': displayLoading,
      'metadata': metadata,
    };
  }

  factory WorkflowUIConfig.fromJson(Map<String, dynamic> json) {
    return WorkflowUIConfig(
      navigationType: json['navigationType'] != null 
          ? NeoNavigationType.fromJson(json['navigationType']) 
          : null,
      useSubNavigator: json['useSubNavigator'] as bool? ?? false,
      displayLoading: json['displayLoading'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Event emitted by workflow operations to trigger UI changes
class WorkflowUIEvent {
  final WorkflowUIEventType type;
  final String? instanceId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WorkflowUIEvent._({
    required this.type,
    this.instanceId,
    required this.data,
  }) : timestamp = DateTime.now();

  /// Create a loading event
  factory WorkflowUIEvent.loading({
    required bool isLoading,
    String? message,
    String? instanceId,
  }) {
    return WorkflowUIEvent._(
      type: WorkflowUIEventType.loading,
      instanceId: instanceId,
      data: {
        'isLoading': isLoading,
        'message': message,
      },
    );
  }

  /// Create a navigation event
  factory WorkflowUIEvent.navigate({
    required String pageId,
    String? instanceId,
    NeoNavigationType? navigationType,
    bool useSubNavigator = false,
    Map<String, dynamic>? pageData,
    Map<String, dynamic>? queryParameters,
  }) {
    return WorkflowUIEvent._(
      type: WorkflowUIEventType.navigate,
      instanceId: instanceId,
      data: {
        'pageId': pageId,
        'navigationType': navigationType,
        'useSubNavigator': useSubNavigator,
        'pageData': pageData,
        'queryParameters': queryParameters,
      },
    );
  }

  /// Create an error event
  factory WorkflowUIEvent.error({
    required String error,
    String? instanceId,
    bool displayAsPopup = true,
  }) {
    return WorkflowUIEvent._(
      type: WorkflowUIEventType.error,
      instanceId: instanceId,
      data: {
        'error': error,
        'displayAsPopup': displayAsPopup,
      },
    );
  }

  /// Create a data update event
  factory WorkflowUIEvent.updateData({
    required Map<String, dynamic> pageData,
    String? instanceId,
  }) {
    return WorkflowUIEvent._(
      type: WorkflowUIEventType.updateData,
      instanceId: instanceId,
      data: {
        'pageData': pageData,
      },
    );
  }

  /// Create a dialog event
  factory WorkflowUIEvent.showDialog({
    required String title,
    required String message,
    String? instanceId,
    List<Map<String, dynamic>>? actions,
  }) {
    return WorkflowUIEvent._(
      type: WorkflowUIEventType.showDialog,
      instanceId: instanceId,
      data: {
        'title': title,
        'message': message,
        'actions': actions,
      },
    );
  }

  /// Create a silent event (no UI action)
  factory WorkflowUIEvent.silent({
    String? instanceId,
    Map<String, dynamic>? data,
  }) {
    return WorkflowUIEvent._(
      type: WorkflowUIEventType.silent,
      instanceId: instanceId,
      data: data ?? {},
    );
  }

  // Convenience getters
  bool get isLoading => data['isLoading'] as bool? ?? false;
  String? get error => data['error'] as String?;
  String? get pageId => data['pageId'] as String?;
  NeoNavigationType? get navigationType => data['navigationType'] as NeoNavigationType?;
  bool get useSubNavigator => data['useSubNavigator'] as bool? ?? false;
  Map<String, dynamic>? get pageData => data['pageData'] as Map<String, dynamic>?;
  bool get displayAsPopup => data['displayAsPopup'] as bool? ?? true;

  @override
  String toString() {
    return 'WorkflowUIEvent(type: $type, instanceId: $instanceId, timestamp: $timestamp)';
  }
}
