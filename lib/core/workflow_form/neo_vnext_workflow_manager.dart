import 'package:neo_core/core/bus/widget_event_bus/neo_core_widget_event_keys.dart';
import 'package:neo_core/core/navigation/models/signalr_transition_data.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/neo_network.dart';
import 'package:neo_core/core/workflow_form/neo_vnext_view_manager.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_instance_snapshot.dart';

class NeoVNextWorkflowManager {
  final NeoNetworkManager neoNetworkManager;
  final NeoVNextViewManager neoVNextViewManager;

  NeoVNextWorkflowManager({required this.neoNetworkManager, required this.neoVNextViewManager});

  /// First key: workflow name
  /// Second key: instanceId
  /// Value: Workflow Status
  Map<String, Map<String, VNextInstanceStatus>> activeWorkflowInstances = {};

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
    if (response.isSuccess) {
      await startPolling(
        workflowName: workflowName,
        workflowDomain: workflowDomain,
        instanceId: response.asSuccess.data["id"],
      );
    }
    return response;
  }

  Future<NeoResponse> postTransitionToWorkflow({
    required String workflowName,
    required String workflowDomain,
    required String version,
    required String transitionName,
    required Map<String, dynamic> body,
    Map<String, String>? headerParameters,
  }) async {
    final instanceId = activeWorkflowInstances[workflowName]?.keys.first;
    if (instanceId == null) {
      throw Exception("Instance ID not found for workflow: $workflowName");
    }
    final response = await neoNetworkManager.call(
      NeoHttpCall(
        endpoint: "vnext-post-transition",
        pathParameters: {
          'DOMAIN': workflowDomain,
          'WORKFLOW_NAME': workflowName,
          'INSTANCE_ID': instanceId,
          'TRANSITION_NAME': transitionName,
        },
        queryProviders: [
          HttpQueryProvider({
            "sync": "true",
          }),
        ],
        body: body..removeWhere((key, value) => key != "accountType"),
        headerParameters: headerParameters ?? {},
        useHttps: false, // TODO STOPSHIP: Delete it when APIs are deployed
      ),
    );
    if (response.isSuccess) {
      await startPolling(
        workflowName: workflowName,
        workflowDomain: workflowDomain,
        instanceId: instanceId,
      );
    }
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
      activeWorkflowInstances[workflowName] = {instanceId: status};

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

  Future<bool> isVNextWorkflow(String workflowName) async {
    // TODO STOPSHIP: Get it from config
    final vNextWorkflowNames = [
      "account-opening",
    ];
    return vNextWorkflowNames.contains(workflowName);
  }
}
