import "dart:convert";

import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;

class NeoElastic {
  const NeoElastic(this.url);

  final String url;

  Future<void> logCustom(dynamic message, String level) async {
    final uri = Uri.parse(url);
    final body = {
      "message": message,
      "level": level,
    };

    try {
      final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));

      if (response.statusCode != 200) {
        throw Exception("Failed to log message");
      }
    } catch (e) {
      debugPrint("Failed to log message: $e");
    }
  }
}
