/*
 * neo_core
 *
 * Minimal DataManager for workflow data management
 * 
 * This is a bare-minimum implementation focused on solving the vNext workflow
 * data storage and retrieval issue. Future enhancements can be added incrementally.
 */

import 'package:neo_core/core/data_manager/data_scope.dart';

/// Minimal DataManager for workflow data management
/// 
/// Provides unified storage for workflow instance data (backend) and
/// workflow transition data (user input).
class DataManager {
  // Storage maps: scope -> context -> key -> data
  final Map<DataScope, Map<DataContext, Map<String, dynamic>>> _storage = {
    DataScope.workflowInstance: {
      DataContext.device: {},
      DataContext.user: {},
    },
    DataScope.workflowTransition: {
      DataContext.device: {},
      DataContext.user: {},
    },
  };

  /// Set data in the specified scope and context
  /// 
  /// [scope] - The data scope (workflowInstance or workflowTransition)
  /// [context] - The data context (device or user)
  /// [key] - Unique key for the data (e.g., "core/account-opening/instance-id")
  /// [value] - The data to store (Map, List, String, int, bool, etc.)
  void setData(
    DataScope scope,
    DataContext context,
    String key,
    dynamic value,
  ) {
    if (key.isEmpty) {
      throw ArgumentError('Key cannot be empty');
    }
    
    _storage[scope]![context]![key] = value;
  }

  /// Get data from the specified scope and context
  /// 
  /// [scope] - The data scope (workflowInstance or workflowTransition)
  /// [context] - The data context (device or user)
  /// [key] - Unique key for the data
  /// [dataPath] - Optional path to nested property (e.g., "accountType" or "applicant.firstName")
  /// 
  /// Returns the data value, or null if not found
  dynamic getData(
    DataScope scope,
    DataContext context,
    String key, {
    String? dataPath,
  }) {
    if (key.isEmpty) {
      return null;
    }

    final data = _storage[scope]?[context]?[key];
    if (data == null) {
      return null;
    }

    // If no dataPath, return the entire data object
    if (dataPath == null || dataPath.isEmpty) {
      return data;
    }

    // Extract nested property using dataPath
    final result = _extractDataPath(data, dataPath);
    return result;
  }

  /// Delete data from the specified scope and context
  /// 
  /// [scope] - The data scope
  /// [context] - The data context
  /// [key] - Unique key for the data
  void deleteData(
    DataScope scope,
    DataContext context,
    String key,
  ) {
    _storage[scope]?[context]?.remove(key);
  }

  /// Clear all data for a specific scope and context
  /// 
  /// [scope] - The data scope
  /// [context] - The data context
  void clearScope(
    DataScope scope,
    DataContext context,
  ) {
    _storage[scope]?[context]?.clear();
  }

  /// Extract nested property from data using dot notation path
  /// 
  /// Examples:
  /// - "accountType" -> data["accountType"]
  /// - "applicant.firstName" -> data["applicant"]["firstName"]
  /// - "items[0].name" -> data["items"][0]["name"]
  dynamic _extractDataPath(dynamic data, String path) {
    if (data == null || path.isEmpty) {
      return null;
    }

    final parts = path.split('.');
    dynamic current = data;

    for (final part in parts) {
      if (current == null) {
        return null;
      }

      // Handle array access: "items[0]"
      if (part.contains('[') && part.contains(']')) {
        final indexMatch = RegExp(r'^(.+)\[(\d+)\]$').firstMatch(part);
        if (indexMatch != null) {
          final key = indexMatch.group(1);
          final index = int.tryParse(indexMatch.group(2)!);
          if (index == null) {
            return null;
          }

          if (current is Map) {
            current = current[key];
          } else {
            return null;
          }

          if (current is List && index >= 0 && index < current.length) {
            current = current[index];
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        // Regular map access
        if (current is Map) {
          current = current[part];
        } else {
          return null;
        }
      }
    }

    return current;
  }

  /// Get all keys for a specific scope and context
  /// 
  /// Useful for debugging and cleanup operations
  List<String> getKeys(DataScope scope, DataContext context) {
    return _storage[scope]?[context]?.keys.toList() ?? [];
  }

  /// Check if data exists for a specific key
  bool hasData(DataScope scope, DataContext context, String key) {
    return _storage[scope]?[context]?.containsKey(key) ?? false;
  }
}

