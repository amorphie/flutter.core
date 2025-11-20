// ignore_for_file: cascade_invocations

/*
 * neo_core
 *
 * VNext Error Handler: handles and formats vNext backend errors, especially validation errors
 */

import 'dart:convert';

import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_validation_error.dart';

/// Handler for vNext errors with support for validation error parsing and formatting
class VNextErrorHandler {
  final NeoLogger logger;

  VNextErrorHandler({required this.logger});

  /// Process an error response and log validation error details for developers
  /// 
  /// Logs validation errors with error code, validationErrors, and traceId for debugging.
  /// Returns the original error response unchanged (UI shows standard RFC 7807 message).
  /// Validation errors are UI issues that users cannot fix, so they shouldn't see technical details.
  NeoErrorResponse processErrorResponse(NeoErrorResponse errorResponse) {
    logger.logError('[VNextErrorHandler] ===== processErrorResponse CALLED =====');
    logger.logError('[VNextErrorHandler] Status Code: ${errorResponse.statusCode}');
    logger.logError('[VNextErrorHandler] Error Description: ${errorResponse.error.error.description}');
    logger.logError('[VNextErrorHandler] Error Body Type: ${errorResponse.error.body.runtimeType}');
    
    try {
      // Extract error body and parse it
      final errorBodyMap = _parseErrorBody(errorResponse.error.body);
      if (errorBodyMap == null) {
        logger.logError('[VNextErrorHandler] Error body is null or could not be parsed');
        return errorResponse;
      }

      logger.logError('[VNextErrorHandler] Error body parsed successfully, keys: ${errorBodyMap.keys.join(", ")}');

      // Extract traceId for logging
      final traceId = errorBodyMap['traceId'] as String?;
      final errorCode = errorBodyMap['code'] as String? ?? errorResponse.error.responseCode.toString();
      
      logger.logError('[VNextErrorHandler] Error Code: $errorCode');
      if (traceId != null) {
        logger.logError('[VNextErrorHandler] Trace ID: $traceId');
      }
      
      // Try to extract validation errors from the error body
      final validationErrors = _extractValidationErrors(errorResponse.error.body);
      
      logger.logError('[VNextErrorHandler] Validation errors extracted, hasErrors: ${validationErrors.hasErrors}');
      
      if (validationErrors.hasErrors) {
        // Log comprehensive validation error details for developers
        _logValidationErrors(
          errorCode: errorCode,
          statusCode: errorResponse.statusCode,
          validationErrors: validationErrors,
          traceId: traceId,
          originalDescription: errorResponse.error.error.description,
        );
      } else {
        logger.logError('[VNextErrorHandler] No validation errors found in error response');
      }
    } catch (e, stackTrace) {
      logger.logError('[VNextErrorHandler] Exception processing error response: $e');
      logger.logError('[VNextErrorHandler] Stack trace: $stackTrace');
    }

    logger.logError('[VNextErrorHandler] ===== processErrorResponse COMPLETE =====');
    // Always return original error response unchanged - UI shows standard message
    return errorResponse;
  }

  /// Parse error body to Map, handling both string and Map formats
  Map<String, dynamic>? _parseErrorBody(dynamic errorBody) {
    if (errorBody == null) {
      return null;
    }

    try {
      if (errorBody is String) {
        return jsonDecode(errorBody) as Map<String, dynamic>?;
      } else if (errorBody is Map<String, dynamic>) {
        return errorBody;
      }
    } catch (e) {
      logger.logError('[VNextErrorHandler] Failed to parse error body: $e');
    }

    return null;
  }

  /// Extract validation errors from error body
  VNextValidationErrors _extractValidationErrors(dynamic errorBody) {
    final bodyMap = _parseErrorBody(errorBody);
    if (bodyMap == null) {
      return const VNextValidationErrors(errors: []);
    }

    try {
      return VNextValidationErrors.fromJson(bodyMap);
    } catch (e) {
      logger.logError('[VNextErrorHandler] Failed to extract validation errors: $e');
      return const VNextValidationErrors(errors: []);
    }
  }

  /// Log validation errors with comprehensive details for developers
  void _logValidationErrors({
    required String errorCode,
    required int statusCode,
    required VNextValidationErrors validationErrors,
    String? traceId,
    String? originalDescription,
  }) {
    final affectedFields = validationErrors.affectedFields;
    
    // Log as a single structured log entry for easy searching in Elastic
    // This creates one searchable log entry with all validation error details
    final validationErrorsList = validationErrors.errors.map((err) => {
      'message': err.message,
      'members': err.members,
    }).toList();
    
    final logProperties = <String, dynamic>{
      'errorCode': errorCode,
      'statusCode': statusCode,
      'validationErrorsCount': validationErrors.errors.length,
      'validationErrors': validationErrorsList,
      'affectedFields': affectedFields,
      if (traceId != null && traceId.isNotEmpty) 'traceId': traceId,
      if (originalDescription != null) 'originalDescription': originalDescription,
      if (validationErrors.target != null) 'transitionTarget': validationErrors.target,
    };
    
    logger.logError(
      '[VNextErrorHandler] Validation Error: $errorCode - ${validationErrors.errors.length} error(s)',
      properties: logProperties,
    );
  }


  /// Extract validation errors from an error response
  /// 
  /// Useful for custom error handling or UI display
  VNextValidationErrors extractValidationErrors(NeoErrorResponse errorResponse) {
    return _extractValidationErrors(errorResponse.error.body);
  }
}
