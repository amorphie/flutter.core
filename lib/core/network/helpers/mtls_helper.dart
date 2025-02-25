import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_shield/secure_enclave.dart';

class MtlsHelper {
  late final _secureEnclavePlugin = SecureEnclave();

  Future<String?> sign({required String clientKeyTag, required Map? requestBody}) async {
    if (requestBody == null || requestBody.isEmpty) {
      return null;
    }
    final isKeyCreated = (await _secureEnclavePlugin.isKeyCreated(clientKeyTag, "C")).value ?? false;

    if (!isKeyCreated) {
      return null;
    }

    final result = await _secureEnclavePlugin.sign(
      tag: clientKeyTag,
      message: Uint8List.fromList(utf8.encode(requestBody.toString())),
    );

    return result.value;
  }
}
