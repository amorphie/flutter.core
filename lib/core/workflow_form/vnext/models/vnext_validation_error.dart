/*
 * neo_core
 *
 * VNext Validation Error Model: represents validation errors from vNext backend
 */

import 'package:equatable/equatable.dart';

/// Represents a single validation error from vNext backend
class VNextValidationError extends Equatable {
  /// The validation error message
  final String message;
  
  /// The members/fields that this validation error applies to
  final List<String> members;

  const VNextValidationError({
    required this.message,
    required this.members,
  });

  factory VNextValidationError.fromJson(Map<String, dynamic> json) {
    return VNextValidationError(
      message: (json['message'] as String?) ?? '',
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'members': members,
    };
  }

  @override
  List<Object?> get props => [message, members];
}

/// Represents validation errors from a vNext error response
class VNextValidationErrors extends Equatable {
  /// List of validation errors
  final List<VNextValidationError> errors;
  
  /// The transition target that failed validation (if available)
  final String? target;

  const VNextValidationErrors({
    required this.errors,
    this.target,
  });

  factory VNextValidationErrors.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const VNextValidationErrors(errors: []);
    }

    final validationErrors = (json['validationErrors'] as List<dynamic>?)
            ?.map((e) => VNextValidationError.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return VNextValidationErrors(
      errors: validationErrors,
      target: json['data'] is Map<String, dynamic>
          ? (json['data'] as Map<String, dynamic>)['target'] as String?
          : null,
    );
  }

  /// Check if there are any validation errors
  bool get hasErrors => errors.isNotEmpty;

  /// Get all field names that have validation errors
  List<String> get affectedFields {
    final fields = <String>{};
    for (final error in errors) {
      fields.addAll(error.members);
    }
    return fields.toList();
  }

  /// Get a formatted error message combining all validation errors
  String getFormattedMessage({String? defaultMessage}) {
    if (!hasErrors) {
      return defaultMessage ?? 'Validation failed';
    }

    final messages = <String>[];
    for (final error in errors) {
      if (error.members.isNotEmpty) {
        final fields = error.members.join(', ');
        messages.add('${error.message} (${fields})');
      } else {
        messages.add(error.message);
      }
    }
    return messages.join('\n');
  }

  @override
  List<Object?> get props => [errors, target];
}

