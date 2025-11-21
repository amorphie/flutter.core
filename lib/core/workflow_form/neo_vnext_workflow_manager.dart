import 'package:neo_core/core/bus/widget_event_bus/neo_core_widget_event_keys.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/neo_vnext_view_manager.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_instance_snapshot.dart';

class NeoVNextWorkflowManager {
  final NeoNetworkManager neoNetworkManager;
  final NeoVNextViewManager neoVNextViewManager;

  NeoVNextWorkflowManager({required this.neoNetworkManager, required this.neoVNextViewManager});

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
          final view = await neoVNextViewManager.fetchViewByHref(href: data["view"]["href"]);
          // TODO: Fetch data
          if (view == null) {
            // TODO STOPSHIP: Handle error when view or data is null
          } else {
            NeoCoreWidgetEventKeys.neoTransitionListenerSendTransitionSuccessEvent.sendEvent(
              data: SignalrTransitionData(
                instanceId: instanceId,
                navigationPath: view.pageId,
                navigationType: view.displayType.toNavigationType(),
                viewSource: NeoVNextViewManager.viewSource,
              ),
            );
          }
          break;

        case VNextInstanceStatus.passive:
        // TODO STOPSHIP: Ask what should happen
        case VNextInstanceStatus.completed:
        case VNextInstanceStatus.faulted:
          break;
      }
    }
  }
}
