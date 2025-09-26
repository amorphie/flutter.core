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

import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/neo_user_internet_usage.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';

class NeoUserInternetUsageStorage {
  final NeoSharedPrefs neoSharedPrefs;

  static const String _usageKey = "user_internet_usage";

  NeoUserInternetUsageStorage({required this.neoSharedPrefs});

  NeoLogger? get _neoLogger => GetIt.I.getIfReady<NeoLogger>();

  bool enableLog = true;
  int logRequestLimit = 0;

  void init({required bool? isEnabled, required int? loggerRequestLimit}) {
    enableLog = isEnabled ?? enableLog;
    logRequestLimit = loggerRequestLimit ?? logRequestLimit;
  }

  /// Get current user internet usage
  Future<NeoUserInternetUsage> getUsage() async {
    try {
      final usageJson = neoSharedPrefs.read(_usageKey);
      if (usageJson == null) {
        return NeoUserInternetUsage.empty();
      }

      final usageMap = jsonDecode(usageJson as String) as Map<String, dynamic>;
      return NeoUserInternetUsage.fromJson(usageMap);
    } catch (e) {
      _neoLogger?.logError("[UserInternetUsageStorage]: Failed to get usage: $e");
      return NeoUserInternetUsage.empty();
    }
  }

  /// Add usage data to current totals
  Future<void> addUsage({
    required int bytesUsed,
    required bool isSuccess,
    required String endpoint,
  }) async {
    if (!enableLog) {
      return;
    }

    try {
      final currentUsage = await getUsage();
      final updatedUsage = currentUsage.addUsage(
        bytesUsed: bytesUsed,
        isSuccess: isSuccess,
        endpoint: endpoint,
      );
      await _saveUsage(updatedUsage);

      _neoLogger?.logConsole(
        "[UserInternetUsageStorage]: Added $bytesUsed bytes (${isSuccess ? 'SUCCESS' : 'FAILED'}) - Total: ${updatedUsage.formattedBytesUsed}",
      );
    } catch (e) {
      _neoLogger?.logError("[UserInternetUsageStorage]: Failed to add usage: $e");
    }
  }

  /// Save usage data
  Future<void> _saveUsage(NeoUserInternetUsage usage) async {
    try {
      final usageJson = jsonEncode(usage.toJson());
      await neoSharedPrefs.write(_usageKey, usageJson);
    } catch (e) {
      _neoLogger?.logError("[UserInternetUsageStorage]: Failed to save usage: $e");
    }
  }

  /// Reset usage data
  Future<void> resetUsage() async {
    try {
      await neoSharedPrefs.delete(_usageKey);
      _neoLogger?.logConsole("[UserInternetUsageStorage]: Usage data reset");
    } catch (e) {
      _neoLogger?.logError("[UserInternetUsageStorage]: Failed to reset usage: $e");
    }
  }

  /// Get usage statistics
  Future<Map<String, dynamic>> getUsageStats() async {
    try {
      final usage = await getUsage();
      return {
        'totalBytesUsed': usage.totalBytesUsed,
        'formattedBytesUsed': usage.formattedBytesUsed,
        'totalRequests': usage.totalRequests,
        'successfulRequests': usage.successfulRequests,
        'failedRequests': usage.failedRequests,
        'successRate': usage.successRate,
        'averageBytesPerRequest': usage.averageBytesPerRequest,
        'lastUpdated': usage.lastUpdated.toIso8601String(),
      };
    } catch (e) {
      _neoLogger?.logError("[UserInternetUsageStorage]: Failed to get usage stats: $e");
      return {};
    }
  }
}
