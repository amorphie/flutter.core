import "dart:convert";

import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;

abstract class _Constants {
  static const String url = "https://dmztest-apisix.burgan.com.tr/ebanking/collect/log";
}

class NeoElastic {
  const NeoElastic();

  Future<void> logCustom(dynamic message, String level) async {
    final url = Uri.parse(_Constants.url);
    final body = {
      "message": message,
      "level": level,
    };

    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));

      if (response.statusCode != 200) {
        throw Exception("Failed to log message");
      }
    } catch (e) {
      debugPrint("Failed to log message: $e");
    }
  }
}
