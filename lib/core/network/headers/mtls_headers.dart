import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/helpers/mtls_helper.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';

class MtlsHeaders {
  final NeoCoreSecureStorage secureStorage;
  final NeoLogger neoLogger;

  late final MtlsHelper _mtlsHelper = MtlsHelper(neoLogger: neoLogger);

  String? _deviceId;

  MtlsHeaders({required this.secureStorage, required this.neoLogger});

  Future<Map<String, String>> getHeaders(Map requestBody) async {
    return _getJwsSignatureHeader(requestBody);
  }

  Future<Map<String, String>> _getJwsSignatureHeader(Map requestBody) async {
    final userReference = await secureStorage.read(NeoCoreParameterKey.secureStorageCustomerId);
    final deviceId = _deviceId ??= await secureStorage.read(NeoCoreParameterKey.secureStorageDeviceId);
    if (userReference == null || deviceId == null) {
      return {};
    }
    final signedRequest = await _mtlsHelper.sign(clientKeyTag: "$deviceId$userReference", requestBody: requestBody);
    if (signedRequest == null) {
      return {};
    }
    return {NeoNetworkHeaderKey.jwsSignature: signedRequest};
  }
}
