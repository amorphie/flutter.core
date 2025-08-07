import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/helpers/mtls_helper.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/util/extensions/get_it_extensions.dart';

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

  NeoLogger? get _neoLogger => GetIt.I.getIfReady<NeoLogger>();

  Future<dynamic> intercept() async {
    if (response.headers[NeoNetworkHeaderKey.encrypt] != "true") {
      return body;
    }

    try {
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
        _neoLogger?.logCustom("Aes key is null", logLevel: Level.fatal);
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
        _neoLogger?.logCustom("Decrypted text is null", logLevel: Level.fatal);
        return body;
      }

      final decryptedBody = jsonDecode(utf8.decode(base64Decode(jsonDecode(decryptedText)["data"])));
      return decryptedBody;
    } catch (e) {
      _neoLogger?.logCustom("Response interception failed. $e", logLevel: Level.fatal);
      return body;
    }
  }
}
