import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:neo_core/core/network/models/neo_network_header_key.dart';
import 'package:neo_core/core/storage/neo_core_parameter_key.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/util/uuid_util.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';

/// Request interceptor that adds dynamic headers to every request.
class DynamicHeadersRequestInterceptor extends Interceptor {
  DynamicHeadersRequestInterceptor({required this.secureStorage});

  final NeoCoreSecureStorage secureStorage;

  static NeoWorkflowManager? _cachedNeoWorkflowManager;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers.addAll(await _headers);
    handler.next(options);
  }

  Future<Map<String, String>> get _headers async {
    return {
      NeoNetworkHeaderKey.requestId: UuidUtil.generateUUIDWithoutHyphen(),
      NeoNetworkHeaderKey.instanceId: _neoWorkflowManager?.instanceId ?? "",
      NeoNetworkHeaderKey.workflowName: _neoWorkflowManager?.getWorkflowName() ?? "",
    }..addAll(await _authHeader);
  }

  Future<Map<String, String>> get _authHeader async {
    final authToken = await secureStorage.read(NeoCoreParameterKey.secureStorageAuthToken);
    return authToken == null ? {} : {NeoNetworkHeaderKey.authorization: 'Bearer $authToken'};
  }

  /// Read NeoWorkflowManager with try catch, because it depends on NeoNetworkManager
  NeoWorkflowManager? get _neoWorkflowManager {
    try {
      return _cachedNeoWorkflowManager ??= GetIt.I.get<NeoWorkflowManager>();
    } catch (e) {
      return null;
    }
  }
}
