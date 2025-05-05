import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_shield/secure_enclave.dart';

class MtlsHelper {
  late final _secureEnclavePlugin = SecureEnclave();

  Future<String?> sign({required String clientKeyTag, required Map? requestBody}) async {
    print('TEST: Sign started with tag: $clientKeyTag');
    if (requestBody == null || requestBody.isEmpty) {
      return null;
    }
    final isKeyCreated = (await _secureEnclavePlugin.isKeyCreated(clientKeyTag, "C")).value ?? false;
    print('TEST: Sign isKeyCreated: $isKeyCreated');

    if (!isKeyCreated) {
      return null;
    }

    final result = await _secureEnclavePlugin.sign(
      tag: clientKeyTag,
      message: Uint8List.fromList(utf8.encode(jsonEncode(requestBody))),
    );
    print('TEST: Sign completed with tag: $clientKeyTag. Result: ${result.value}');
    if (result.value == null) {
      return null;
    }

    return base64Encode(Uint8List.fromList(utf8.encode(result.value!)));
  }

  Future<void> storePrivateKeyWithCertificate({
    required String clientKeyTag,
    required String privateKey,
    required String certificate,
  }) async {
    await _secureEnclavePlugin.storeServerPrivateKey(tag: clientKeyTag, privateKeyData: base64Decode(privateKey));
    await _secureEnclavePlugin.storeCertificate(tag: clientKeyTag, certificateData: utf8.encode(certificate));
    print('TEST: Certificate stored successfully with tag: $clientKeyTag');
  }

  Future<String?> getCertificate({required String clientKeyTag}) async {
    final certificateResult = await _secureEnclavePlugin.getCertificate(tag: clientKeyTag);
    print('TEST: Certificate retrieved successfully with tag: $clientKeyTag. Value: ${certificateResult.value}');
    return certificateResult.value;
  }

  Future<String?> getServerPrivateKey({required String clientKeyTag}) async {
    final privateKeyResult = await _secureEnclavePlugin.getServerKey(tag: clientKeyTag);
    print('TEST: Server private key retrieved successfully with tag: $clientKeyTag. Value: ${privateKeyResult.value}');
    return privateKeyResult.value;
  }
}
