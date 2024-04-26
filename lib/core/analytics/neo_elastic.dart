import "package:flutter/foundation.dart";
import "package:get_it/get_it.dart";
import "package:neo_core/core/network/managers/neo_network_manager.dart";
import "package:neo_core/core/network/models/neo_http_call.dart";

abstract class _Constants {
  static const endpoint = "elastic";
}

class NeoElastic {
  NeoElastic();

  late final NeoNetworkManager _neoNetworkManager = GetIt.I.get<NeoNetworkManager>();

  Future<void> logCustom(dynamic message, String level) async {
    final body = {
      "message": message,
      "level": level,
    };

    try {
      await _neoNetworkManager.call(NeoHttpCall(endpoint: _Constants.endpoint, body: body));
    } catch (e) {
      debugPrint("Failed to log message: $e");
    }
  }
}
