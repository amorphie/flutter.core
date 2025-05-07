import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:neo_core/core/managers/parameter_manager/neo_cached_parameter_manager.dart';
import 'package:neo_core/core/managers/parameter_manager/neo_storage_parameter_manager.dart';

abstract class _Constant {
  static const prefixCache = "cache";
  static const prefixSecureStorage = "secureStorage";
  static const urnSplitter = ":";
}

/// STOPSHIP: Add folder based caching mechanism
class NeoParameterManager {
  NeoParameterManager({
    required this.neoStorageParameterManager,
    required this.neoCachedParameterManager,
  });

  final NeoStorageParameterManager neoStorageParameterManager;
  final NeoCachedParameterManager neoCachedParameterManager;

  Future<dynamic> read(String keyUrn) async {
    final splitResult = keyUrn.split(_Constant.urnSplitter);
    if (splitResult.length < 2) {
      return null;
    }
    final parameterLocation = splitResult[0];

    switch (parameterLocation) {
      case _Constant.prefixCache:
        return neoCachedParameterManager.read(keyUrn);
      case _Constant.prefixSecureStorage:
        return neoStorageParameterManager.read(keyUrn);
      default:
        return null;
    }
  }

  dynamic readFromCache(String keyUrn) {
    final splitResult = keyUrn.split(_Constant.urnSplitter);
    if (splitResult.length < 2 || splitResult[0] != _Constant.prefixCache) {
      if (kDebugMode) {
        throw Exception("[NeoParameterManagerException]: Format error! Key urn: $keyUrn");
      }
      return null;
    }
    return neoCachedParameterManager.read(keyUrn);
  }

  void writeToCache(String key, dynamic value) {
    neoCachedParameterManager.write(key, value);
  }

  void delete(String keyUrn) {
    final splitResult = keyUrn.split(_Constant.urnSplitter);
    if (splitResult.length < 2) {
      return;
    }
    final parameterLocation = splitResult[0];

    switch (parameterLocation) {
      case _Constant.prefixCache:
        return neoCachedParameterManager.delete(keyUrn);
      case _Constant.prefixSecureStorage:
        return neoStorageParameterManager.delete(keyUrn);
      default:
        return;
    }
  }

  void clearCache() {
    neoCachedParameterManager.clear();
  }
}
