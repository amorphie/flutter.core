import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:neo_core/core/network/helpers/mtls_helper.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';

class NeoResponseInterceptor {
  final dynamic body;
  final Response response;
  final NeoCoreSecureStorage secureStorage;
  final MtlsHelper mtlsHelper;

  NeoResponseInterceptor({
    required this.body,
    required this.response,
    required this.secureStorage,
    required this.mtlsHelper,
  });

  Future<dynamic> intercept() async {
    if (response.headers[NeoNetworkHeaderKey.encrypt] != "true") {
      return body;
    }

    final result = await Future.wait([
      secureStorage.read(NeoCoreParameterKey.secureStorageCustomerId),
      secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId),
    ]);

    final userReference = result[0];
    final deviceId = result[1];
    final clientKeyTag = "$deviceId$userReference";

    final encryptedKey = body["data"]["encryptedKey"];
    final encryptedData = body["data"]["encryptData"];
    final encryptedKeyBytes = base64.decode(encryptedKey);
    final aesKeyString = await mtlsHelper.decrypt(
      clientKeyTag: clientKeyTag,
      message: Uint8List.fromList(encryptedKeyBytes),
    );

    if (aesKeyString == null) {
      return body;
    }

    final aesKeyBytes = base64.decode(aesKeyString);
    final encryptedDataBytes = base64.decode(encryptedData);
    final aesDecryptResult = await mtlsHelper.decryptWithAES(
      encryptedData: Uint8List.fromList(encryptedDataBytes),
      aesKey: Uint8List.fromList(aesKeyBytes),
    );

    final decryptedText = aesDecryptResult.value;
    if (decryptedText == null) {
      return body;
    }

    final decryptedBody = jsonDecode(utf8.decode(base64Decode(jsonDecode(decryptedText)["data"])));
    return decryptedBody;
  }
}
