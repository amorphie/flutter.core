/*
 * neo_core
 *
 * Utility functions for DataManager key generation
 */

import 'package:neo_core/core/workflow_form/vnext/models/vnext_context.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_instance_snapshot.dart';

/// Build workflow instance key for DataManager
/// 
/// Format: "{domain}/{workflowName}/{instanceId}"
/// Example: "core/account-opening/019a7440-83bd-7757-b8b7-82a2a001d20f"
String buildWorkflowInstanceKey({
  required String domain,
  required String workflowName,
  required String instanceId,
}) {
  return '$domain/$workflowName/$instanceId';
}

/// Build workflow instance key from VNextContext
String buildWorkflowInstanceKeyFromContext(VNextContext context) {
  return buildWorkflowInstanceKey(
    domain: context.domain,
    workflowName: context.workflowName,
    instanceId: context.instanceId,
  );
}

/// Build workflow instance key from VNextInstanceSnapshot
String buildWorkflowInstanceKeyFromSnapshot(VNextInstanceSnapshot snapshot) {
  return buildWorkflowInstanceKey(
    domain: snapshot.domain,
    workflowName: snapshot.workflowName,
    instanceId: snapshot.instanceId,
  );
}

/// Build workflow transition key for DataManager
/// 
/// Format: "{domain}/{workflowName}/{instanceId}/{transitionName}"
/// Example: "core/account-opening/019a7440-83bd-7757-b8b7-82a2a001d20f/select-demand-deposit"
String buildWorkflowTransitionKey({
  required String domain,
  required String workflowName,
  required String instanceId,
  required String transitionName,
}) {
  return '$domain/$workflowName/$instanceId/$transitionName';
}

/// Build workflow transition key from VNextContext
/// 
/// Requires transitionName to be set in context
String buildWorkflowTransitionKeyFromContext(VNextContext context) {
  if (context.transitionName == null || context.transitionName!.isEmpty) {
    throw ArgumentError('transitionName is required in VNextContext for transition key');
  }
  
  return buildWorkflowTransitionKey(
    domain: context.domain,
    workflowName: context.workflowName,
    instanceId: context.instanceId,
    transitionName: context.transitionName!,
  );
}

