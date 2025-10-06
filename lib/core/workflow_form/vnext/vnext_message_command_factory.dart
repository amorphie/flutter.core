/*
 * neo_core
 *
 * Created on 2/10/2025.
 * Copyright (c) 2025 Commencis. All rights reserved.
 *
 * Command factory for converting vNext messages to domain objects
 */

import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/navigation/models/neo_navigation_type.dart';
import 'package:neo_core/core/network/models/neo_signalr_transition.dart';
import 'package:neo_core/core/network/models/neo_signalr_transition_state_type.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_workflow_message.dart';
import 'package:neo_core/core/workflow_form/workflow_ui_events.dart';

/// Factory for converting vNext workflow messages to domain objects
/// 
/// This factory handles the conversion of vNext long polling messages
/// to the existing SignalR-based domain objects, ensuring compatibility
/// with the current UI event system.
class VNextMessageCommandFactory {
  final NeoLogger _logger;

  VNextMessageCommandFactory({
    required NeoLogger logger,
  }) : _logger = logger;

  /// Convert vNext message to SignalR transition for UI compatibility
  /// 
  /// This allows vNext messages to be processed by the existing
  /// WorkflowBridgeSetup and UI event system without changes.
  NeoSignalRTransition? convertToSignalRTransition(VNextWorkflowMessage message) {
    try {
      _logger.logConsole('[VNextMessageCommandFactory] Converting message: ${message.type} for instance: ${message.instanceId}');

      switch (message.type) {
        case VNextWorkflowMessageType.transition:
          return _createTransitionCommand(message);
        
        case VNextWorkflowMessageType.stateChange:
          return _createStateChangeCommand(message);
        
        case VNextWorkflowMessageType.completion:
          return _createCompletionCommand(message);
        
        case VNextWorkflowMessageType.data:
          return _createDataUpdateCommand(message);
        
        case VNextWorkflowMessageType.error:
          // Error messages are handled separately
          return null;
      }
    } catch (e) {
      _logger.logError('[VNextMessageCommandFactory] Failed to convert message: $e');
      return null;
    }
  }

  /// Convert vNext message to WorkflowUIEvent for direct UI processing
  /// 
  /// This provides a more direct conversion for cases where we want
  /// to bypass the SignalR compatibility layer.
  WorkflowUIEvent? convertToUIEvent(VNextWorkflowMessage message) {
    try {
      _logger.logConsole('[VNextMessageCommandFactory] Converting to UI event: ${message.type} for instance: ${message.instanceId}');

      switch (message.type) {
        case VNextWorkflowMessageType.transition:
        case VNextWorkflowMessageType.stateChange:
          if (message.requiresNavigation && message.pageId != null) {
            return WorkflowUIEvent.navigate(
              pageId: message.pageId!,
              instanceId: message.instanceId,
              pageData: message.data,
              navigationType: _determineNavigationType(message),
            );
          }
          break;

        case VNextWorkflowMessageType.completion:
          return WorkflowUIEvent.navigate(
            pageId: message.state ?? 'completion',
            instanceId: message.instanceId,
            pageData: {
              ...message.data,
              'workflowCompleted': true,
            },
            navigationType: NeoNavigationType.pushAsRoot,
          );

        case VNextWorkflowMessageType.data:
          return WorkflowUIEvent.updateData(
            pageData: message.data,
            instanceId: message.instanceId,
          );

        case VNextWorkflowMessageType.error:
          return WorkflowUIEvent.error(
            error: message.error ?? 'Unknown workflow error',
            instanceId: message.instanceId,
          );
      }

      return null;
    } catch (e) {
      _logger.logError('[VNextMessageCommandFactory] Failed to convert to UI event: $e');
      return null;
    }
  }

  /// Create transition command from vNext message
  NeoSignalRTransition _createTransitionCommand(VNextWorkflowMessage message) {
    return NeoSignalRTransition(
      transitionId: message.transitionId ?? message.instanceId,
      instanceId: message.instanceId,
      state: message.state ?? '',
      viewSource: message.metadata['viewSource'] as String? ?? 'state',
      pageDetails: _extractPageDetails(message),
      initialData: message.data,
      buttonType: message.metadata['buttonType'] as String? ?? '',
      time: message.timestamp,
      dataPageId: message.pageId,
      additionalData: message.metadata,
      workflowStateType: NeoSignalRTransitionStateType.standard,
    );
  }

  /// Create state change command from vNext message
  NeoSignalRTransition _createStateChangeCommand(VNextWorkflowMessage message) {
    return NeoSignalRTransition(
      transitionId: message.instanceId, // Use instanceId as transitionId for state changes
      instanceId: message.instanceId,
      state: message.state ?? '',
      viewSource: message.metadata['viewSource'] as String? ?? 'state',
      pageDetails: _extractPageDetails(message),
      initialData: message.data,
      buttonType: '',
      time: message.timestamp,
      dataPageId: message.pageId,
      additionalData: message.metadata,
      workflowStateType: NeoSignalRTransitionStateType.standard,
    );
  }

  /// Create completion command from vNext message
  NeoSignalRTransition _createCompletionCommand(VNextWorkflowMessage message) {
    return NeoSignalRTransition(
      transitionId: message.instanceId,
      instanceId: message.instanceId,
      state: message.state ?? 'completed',
      viewSource: 'completion',
      pageDetails: {
        'completed': true,
        'completionTime': message.timestamp.toIso8601String(),
      },
      initialData: message.data,
      buttonType: '',
      time: message.timestamp,
      workflowStateType: NeoSignalRTransitionStateType.finish,
    );
  }

  /// Create data update command from vNext message
  NeoSignalRTransition _createDataUpdateCommand(VNextWorkflowMessage message) {
    return NeoSignalRTransition(
      transitionId: message.instanceId,
      instanceId: message.instanceId,
      state: message.state ?? '',
      viewSource: 'data',
      pageDetails: const {},
      initialData: const {},
      buttonType: '',
      time: message.timestamp,
      dataPageId: message.pageId,
      additionalData: message.data,
      workflowStateType: NeoSignalRTransitionStateType.standard,
    );
  }

  /// Extract page details from vNext message
  Map<String, dynamic> _extractPageDetails(VNextWorkflowMessage message) {
    final pageDetails = <String, dynamic>{};

    // Extract common page information
    if (message.pageId != null) {
      pageDetails['pageId'] = message.pageId;
    }

    // Extract navigation type if specified
    final navigationType = message.metadata['navigationType'];
    if (navigationType != null) {
      pageDetails['navigationType'] = navigationType;
    }

    // Extract view source
    final viewSource = message.metadata['viewSource'];
    if (viewSource != null) {
      pageDetails['viewSource'] = viewSource;
    }

    // Add any other page-specific metadata
    final pageMetadata = message.metadata['page'] as Map<String, dynamic>?;
    if (pageMetadata != null) {
      pageDetails.addAll(pageMetadata);
    }

    return pageDetails;
  }

  /// Determine navigation type from vNext message
  NeoNavigationType _determineNavigationType(VNextWorkflowMessage message) {
    final navigationTypeString = message.metadata['navigationType'] as String?;
    
    switch (navigationTypeString?.toLowerCase()) {
      case 'push':
        return NeoNavigationType.push;
      case 'replace':
        return NeoNavigationType.pushReplacement;
      case 'popup':
      case 'dialog':
        return NeoNavigationType.popup;
      case 'clear':
      case 'clearall':
        return NeoNavigationType.pushAsRoot;
      default:
        return NeoNavigationType.push; // Default
    }
  }

  /// Batch convert multiple vNext messages
  List<NeoSignalRTransition> convertBatchToSignalRTransitions(List<VNextWorkflowMessage> messages) {
    final transitions = <NeoSignalRTransition>[];

    for (final message in messages) {
      final transition = convertToSignalRTransition(message);
      if (transition != null) {
        transitions.add(transition);
      }
    }

    _logger.logConsole('[VNextMessageCommandFactory] Converted ${transitions.length} of ${messages.length} messages to SignalR transitions');
    
    return transitions;
  }

  /// Batch convert multiple vNext messages to UI events
  List<WorkflowUIEvent> convertBatchToUIEvents(List<VNextWorkflowMessage> messages) {
    final events = <WorkflowUIEvent>[];

    for (final message in messages) {
      final event = convertToUIEvent(message);
      if (event != null) {
        events.add(event);
      }
    }

    _logger.logConsole('[VNextMessageCommandFactory] Converted ${events.length} of ${messages.length} messages to UI events');
    
    return events;
  }
}
