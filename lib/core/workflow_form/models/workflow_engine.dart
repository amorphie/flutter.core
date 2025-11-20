/*
 * neo_core
 *
 * Created on 22/9/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

/// Enum representing the available workflow engines
enum WorkflowEngine {
  /// vNext workflow engine - next generation workflow system
  vnext,
  
  /// Amorphie workflow engine - legacy workflow system
  amorphie;

  /// Creates a WorkflowEngine from a string value
  /// 
  /// Supports case-insensitive matching:
  /// - 'vnext' or 'VNEXT' → WorkflowEngine.vnext
  /// - 'amorphie' or 'AMORPHIE' → WorkflowEngine.amorphie
  /// - Any other value defaults to WorkflowEngine.amorphie
  static WorkflowEngine fromString(String value) {
    switch (value.toLowerCase()) {
      case 'vnext':
        return WorkflowEngine.vnext;
      case 'amorphie':
      default:
        return WorkflowEngine.amorphie;
    }
  }

  /// Returns the string representation of the workflow engine
  @override
  String toString() {
    switch (this) {
      case WorkflowEngine.vnext:
        return 'vnext';
      case WorkflowEngine.amorphie:
        return 'amorphie';
    }
  }
}
