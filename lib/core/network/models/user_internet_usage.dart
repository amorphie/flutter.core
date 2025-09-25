/*
 * neo_core
 *
 * Created on 19/10/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

class UserInternetUsage {
  final int totalBytesUsed;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final DateTime lastUpdated;

  const UserInternetUsage({
    required this.totalBytesUsed,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.lastUpdated,
  });

  factory UserInternetUsage.empty() {
    return UserInternetUsage(
      totalBytesUsed: 0,
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      lastUpdated: DateTime.now(),
    );
  }

  factory UserInternetUsage.fromJson(Map<String, dynamic> json) {
    return UserInternetUsage(
      totalBytesUsed: json['totalBytesUsed'] as int? ?? 0,
      totalRequests: json['totalRequests'] as int? ?? 0,
      successfulRequests: json['successfulRequests'] as int? ?? 0,
      failedRequests: json['failedRequests'] as int? ?? 0,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBytesUsed': totalBytesUsed,
      'totalRequests': totalRequests,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  UserInternetUsage copyWith({
    int? totalBytesUsed,
    int? totalRequests,
    int? successfulRequests,
    int? failedRequests,
    DateTime? lastUpdated,
  }) {
    return UserInternetUsage(
      totalBytesUsed: totalBytesUsed ?? this.totalBytesUsed,
      totalRequests: totalRequests ?? this.totalRequests,
      successfulRequests: successfulRequests ?? this.successfulRequests,
      failedRequests: failedRequests ?? this.failedRequests,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Add usage data to current totals
  UserInternetUsage addUsage({
    required int bytesUsed,
    required bool isSuccess,
  }) {
    return copyWith(
      totalBytesUsed: totalBytesUsed + bytesUsed,
      totalRequests: totalRequests + 1,
      successfulRequests: successfulRequests + (isSuccess ? 1 : 0),
      failedRequests: failedRequests + (isSuccess ? 0 : 1),
      lastUpdated: DateTime.now(),
    );
  }

  /// Get success rate as percentage
  double get successRate {
    if (totalRequests == 0) return 0.0;
    return (successfulRequests / totalRequests) * 100;
  }

  /// Get average bytes per request
  double get averageBytesPerRequest {
    if (totalRequests == 0) return 0.0;
    return totalBytesUsed / totalRequests;
  }

  /// Format bytes in human readable format
  String get formattedBytesUsed {
    if (totalBytesUsed < 1024) {
      return '${totalBytesUsed}B';
    } else if (totalBytesUsed < 1024 * 1024) {
      return '${(totalBytesUsed / 1024).toStringAsFixed(1)}KB';
    } else if (totalBytesUsed < 1024 * 1024 * 1024) {
      return '${(totalBytesUsed / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(totalBytesUsed / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
}
