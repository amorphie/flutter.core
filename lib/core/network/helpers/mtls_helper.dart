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

  Future<void> storePrivateKeyWithCertificate({
    required String clientKeyTag,
    required String privateKey,
    required String certificate,
  }) async {
    await _secureEnclavePlugin.storeServerPrivateKey(tag: clientKeyTag, privateKeyData: base64Decode(privateKey));
    await _secureEnclavePlugin.storeCertificate(tag: clientKeyTag, certificateData: utf8.encode(certificate));
  }

  Future<String?> getCertificate({required String clientKeyTag}) async {
    final certificateResult = await _secureEnclavePlugin.getCertificate(tag: clientKeyTag);
    return certificateResult.value;
  }

  Future<String?> getServerPrivateKey({required String clientKeyTag}) async {
    final privateKeyResult = await _secureEnclavePlugin.getServerKey(tag: clientKeyTag);
    return privateKeyResult.value;
  }
}
