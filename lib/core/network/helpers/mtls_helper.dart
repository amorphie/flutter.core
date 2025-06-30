// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_shield/secure_enclave.dart';
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';

class MtlsHelper {
  MtlsHelper();

  NeoLogger? get _neoLogger => GetIt.I.getIfReady<NeoLogger>();

  late final _secureEnclavePlugin = SecureEnclave()
    ..log =
        (logData) async => _neoLogger?.logCustom("[SecureEnclave][${logData.method}]${json.encode(logData.toJson())}");

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
      message: Uint8List.fromList(utf8.encode(jsonEncode(requestBody))),
    );
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
