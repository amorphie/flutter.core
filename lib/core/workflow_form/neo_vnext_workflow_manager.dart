import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_instance_snapshot.dart';

class NeoVNextWorkflowManager {
  final NeoNetworkManager neoNetworkManager;

  NeoVNextWorkflowManager(this.neoNetworkManager);

  /// Key: instanceId
  /// Value: Workflow Status
  Map<String, VNextInstanceStatus> activeWorkflowInstances = {};

  Future<NeoResponse> startWorkflow({
    required String workflowName,
    required String workflowDomain,
    required String version,
  }) async {
    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: "vnext-init-workflow",
        pathParameters: {
          "DOMAIN": workflowDomain,
          "WORKFLOW_NAME": workflowName,
        },
        body: {
          "key": DateTime.now().millisecondsSinceEpoch.toString(),
          "attributes": const {"channel": "mobile"},
          "version": version,
        },
        useHttps: false, // TODO STOPSHIP: Delete it when APIs are deployed
      ),
    );
    print('TEST: Response is $response');
    return response;
  }

  Future<void> startPolling({
    required String workflowName,
    required String workflowDomain,
    required String instanceId,
  }) async {
    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: "vnext-get-workflow-instance-current-state",
        pathParameters: {
          'DOMAIN': workflowDomain,
          'WORKFLOW_NAME': workflowName,
          'INSTANCE_ID': instanceId,
        },
        useHttps: false, // TODO STOPSHIP: Delete it when APIs are deployed
      ),
    );
    if (response.isSuccess) {
      final data = response.asSuccess.data;
      final status = VNextInstanceStatus.fromCode(data["status"]);
      activeWorkflowInstances[instanceId] = status;

      switch (status) {
        case VNextInstanceStatus.busy:
          // TODO STOPSHIP: Handle using polling config
          Future.delayed(const Duration(seconds: 2), () {
            startPolling(
              workflowDomain: workflowDomain,
              workflowName: workflowName,
              instanceId: instanceId,
            );
          });
          break;
        case VNextInstanceStatus.active:
        // Check and update state

        case VNextInstanceStatus.passive:
        // TODO STOPSHIP: Ask what should happen
        case VNextInstanceStatus.completed:
        case VNextInstanceStatus.faulted:
          break;
      }
    }
  }
}
