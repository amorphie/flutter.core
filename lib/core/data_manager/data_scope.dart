/*
 * neo_core
 *
 * DataManager scopes for workflow data management
 */

/// Data scope categories for DataManager
enum DataScope {
  /// Workflow instance data (backend data, read-only from client perspective)
  workflowInstance,

  /// Workflow transition data (user input, client-side temporary data)
  workflowTransition,
}

/// Data context (device vs user level)
/// For now, we only use user context for workflow data
enum DataContext {
  /// Device-level data (shared across all users)
  device,

  /// User-level data (user-specific)
  user,
}

