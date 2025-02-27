import 'package:get_it/get_it.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/util/uuid_util.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';

abstract class _Constants {
  static const String languageCodeEn = "en";
}

class NeoDynamicHeaders {
  final NeoSharedPrefs neoSharedPrefs;
  final NeoCoreSecureStorage secureStorage;

  const NeoDynamicHeaders({required this.neoSharedPrefs, required this.secureStorage});

  Future<Map<String, String>> getHeaders() async {
    return {
      NeoNetworkHeaderKey.acceptLanguage: _languageCode,
      NeoNetworkHeaderKey.contentLanguage: _languageCode,
      NeoNetworkHeaderKey.requestId: UuidUtil.generateUUIDWithoutHyphen(),
      NeoNetworkHeaderKey.instanceId: _neoWorkflowManager?.instanceId ?? "",
      NeoNetworkHeaderKey.workflowName: _neoWorkflowManager?.getWorkflowName() ?? "",
    }..addAll(await _authHeader);
  }

  /// Read NeoWorkflowManager with try catch, because it depends on NeoNetworkManager
  NeoWorkflowManager? get _neoWorkflowManager {
    try {
      return GetIt.I.get<NeoWorkflowManager>();
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String>> get _authHeader async {
    final authToken = await _getToken();
    return authToken == null ? {} : {NeoNetworkHeaderKey.authorization: 'Bearer $authToken'};
  }

  Future<String?> _getToken() => secureStorage.read(NeoCoreParameterKey.secureStorageAuthToken);

  String get _languageCode {
    final languageCodeReadResult = neoSharedPrefs.read(NeoCoreParameterKey.sharedPrefsLanguageCode);
    final String languageCode = languageCodeReadResult != null ? languageCodeReadResult as String : "";

    if (languageCode == _Constants.languageCodeEn) {
      return "$languageCode-US";
    } else {
      return '$languageCode-${languageCode.toUpperCase()}';
    }
  }
}
