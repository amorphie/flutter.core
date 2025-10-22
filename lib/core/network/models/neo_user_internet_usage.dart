import 'package:neo_core/core/util/extensions/internet_usage_format_extension.dart';

class NeoUserInternetUsage {
  final int totalBytesUsed;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final DateTime lastUpdated;
  final List<Map<String, dynamic>> usageHistory;

  const NeoUserInternetUsage({
    required this.totalBytesUsed,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.lastUpdated,
    this.usageHistory = const [],
  });

  factory NeoUserInternetUsage.empty() {
    return NeoUserInternetUsage(
      totalBytesUsed: 0,
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      lastUpdated: DateTime.now(),
    );
  }

  factory NeoUserInternetUsage.fromJson(Map<String, dynamic> json) {
    return NeoUserInternetUsage(
      totalBytesUsed: json['totalBytesUsed'] as int? ?? 0,
      totalRequests: json['totalRequests'] as int? ?? 0,
      successfulRequests: json['successfulRequests'] as int? ?? 0,
      failedRequests: json['failedRequests'] as int? ?? 0,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ?? DateTime.now(),
      usageHistory:
          (json['usageHistory'] as List<dynamic>?)?.map((item) => Map<String, dynamic>.from(item as Map)).toList() ??
              [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBytesUsed': totalBytesUsed.formattedBytesUsed,
      'totalRequests': totalRequests,
      'successfulRequests': successfulRequests,
      'failedRequests': failedRequests,
      'lastUpdated': lastUpdated.toString(),
      'usageHistory': usageHistory,
    };
  }

  NeoUserInternetUsage copyWith({
    int? totalBytesUsed,
    int? totalRequests,
    int? successfulRequests,
    int? failedRequests,
    DateTime? lastUpdated,
    List<Map<String, dynamic>>? usageHistory,
  }) {
    return NeoUserInternetUsage(
      totalBytesUsed: totalBytesUsed ?? this.totalBytesUsed,
      totalRequests: totalRequests ?? this.totalRequests,
      successfulRequests: successfulRequests ?? this.successfulRequests,
      failedRequests: failedRequests ?? this.failedRequests,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      usageHistory: usageHistory ?? this.usageHistory,
    );
  }

  /// Add usage data to current totals
  NeoUserInternetUsage addUsage({
    required int bytesUsed,
    required bool isSuccess,
    required String endpoint,
  }) {
    final Map<String, dynamic> historyEntry = {
      endpoint: "Date:${DateTime.now().toIso8601String()} - Usage:${bytesUsed.formattedBytesUsed}",
    };

    return copyWith(
      totalBytesUsed: totalBytesUsed + bytesUsed,
      totalRequests: totalRequests + 1,
      successfulRequests: successfulRequests + (isSuccess ? 1 : 0),
      failedRequests: failedRequests + (isSuccess ? 0 : 1),
      lastUpdated: DateTime.now(),
      usageHistory: [...usageHistory, historyEntry],
    );
  }
}
