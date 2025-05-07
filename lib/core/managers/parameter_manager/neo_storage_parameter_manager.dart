import 'package:neo_core/core/storage/neo_core_secure_storage.dart';

class NeoStorageParameterManager {
  final NeoCoreSecureStorage neoCoreSecureStorage;

  NeoStorageParameterManager({required this.neoCoreSecureStorage});

  Future<dynamic> read(String key) {
    return neoCoreSecureStorage.read(key);
  }

  void delete(String key) {
    neoCoreSecureStorage.delete(key);
  }
}
