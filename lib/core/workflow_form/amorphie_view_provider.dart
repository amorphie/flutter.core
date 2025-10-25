import 'package:get_it/get_it.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/query_providers/http_query_provider.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';
import 'package:neo_core/core/workflow_form/workflow_view_provider.dart';

class AmorphieViewProvider implements WorkflowViewProvider {
  static const String _endpointGetTransition = "get-page-response-from-workflow";

  final NeoNetworkManager _networkManager = GetIt.I<NeoNetworkManager>();

  @override
  Future<NeoResponse> loadView({
    required WorkflowInstanceEntity instance,
    Map<String, String>? headers,
  }) async {
    final response = await _networkManager.call(
      NeoHttpCall(
        endpoint: _endpointGetTransition,
        pathParameters: {
          'SOURCE': 'flow',
          'PAGE_ID': instance.currentState ?? instance.workflowName,
        },
        queryProviders: [HttpQueryProvider({'type': 'flutterwidget'})],
        headerParameters: {'InstanceId': instance.instanceId, ...?headers},
      ),
    );
    return response;
  }

  @override
  Future<NeoResponse?> loadData({
    required WorkflowInstanceEntity instance,
    Map<String, String>? headers,
  }) async {
    // Amorphie flow embeds data in view or separate mechanisms; return null by default
    return null;
  }
}


