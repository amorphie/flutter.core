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

import 'dart:async';
import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/neo_user_internet_usage.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';

class NeoUserInternetUsageStorage {
  final NeoSharedPrefs neoSharedPrefs;

  static const String _usageKey = "user_internet_usage";

  NeoUserInternetUsageStorage({required this.neoSharedPrefs});

  NeoLogger? get _neoLogger => GetIt.I.getIfReady<NeoLogger>();

  bool _enableLog = false;
  int _logRequestLimit = 0;

  NeoUserInternetUsage _internetUsage = NeoUserInternetUsage.empty();

  void init({required bool? isEnabled, required int? loggerRequestLimit}) {
    _enableLog = isEnabled ?? _enableLog;
    _logRequestLimit = loggerRequestLimit ?? _logRequestLimit;
    unawaited(getUsage());
  }

  /// Get current user internet usage
  Future<void> getUsage() async {
    try {
      final usageJson = neoSharedPrefs.read(_usageKey);
      if (usageJson == null) {
        return;
      }

      final usageMap = jsonDecode(usageJson as String) as Map<String, dynamic>;
      _internetUsage = NeoUserInternetUsage.fromJson(usageMap);
    } catch (e) {
      _neoLogger?.logError("[UserInternetUsageStorage]: Failed to get usage: $e");
      return;
    }
  }

  /// Add usage data to current totals
  Future<void> addUsage({
    required int bytesUsed,
    required bool isSuccess,
    required String endpoint,
  }) async {
    if (!_enableLog) {
      return;
    }

    try {
      final updatedUsage = _internetUsage.addUsage(
        bytesUsed: bytesUsed,
        isSuccess: isSuccess,
        endpoint: endpoint,
      );
      await _saveUsage(updatedUsage);
      _internetUsage = updatedUsage;

      _neoLogger?.logConsole(
        "[UserInternetUsageStorage]: Added $bytesUsed bytes (${isSuccess ? 'SUCCESS' : 'FAILED'}) - Total: ${updatedUsage.formattedBytesUsed}",
      );
      if (_logRequestLimit > 0 && _internetUsage.totalRequests >= _logRequestLimit) {
        await _logUsage(_internetUsage);
        await resetUsage();
        _internetUsage = NeoUserInternetUsage.empty();
      }
    } catch (e) {
      _neoLogger?.logError("[UserInternetUsageStorage]: Failed to add internet usage: $e");
    }
  }

  Future<void> _logUsage(NeoUserInternetUsage usage) async {
    _neoLogger?.logCustom("Internet Usage Tracker", logLevel: Level.fatal, properties: usage.toJson());
  }

  /// Save usage data
  Future<void> _saveUsage(NeoUserInternetUsage usage) async {
    try {
      final usageJson = jsonEncode(usage.toJson());
      await neoSharedPrefs.write(_usageKey, usageJson);
      print("lasttt savedddd:  ${usageJson}");
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
