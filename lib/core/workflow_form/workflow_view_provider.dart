import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';

/// Engine-agnostic interface to load view and data for the current workflow state
abstract class WorkflowViewProvider {
  Future<NeoResponse> loadView({
    required WorkflowInstanceEntity instance,
    Map<String, String>? headers,
  });

  Future<NeoResponse?> loadData({
    required WorkflowInstanceEntity instance,
    Map<String, String>? headers,
  });
}


