/// Types of polling events that can occur during long polling sessions
enum VNextPollingEventType {
  /// Polling session has started
  started,
  
  /// Polling session has stopped (normally or due to status change)
  stopped,
  
  /// Polling encountered an error
  error,
  
  /// Polling timed out
  timeout,
}
