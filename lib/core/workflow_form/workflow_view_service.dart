import 'package:get_it/get_it.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/workflow_form/amorphie_view_provider.dart';
import 'package:neo_core/core/workflow_form/vnext_view_provider.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';
import 'package:neo_core/core/workflow_form/workflow_view_provider.dart';

class WorkflowViewService {
  final AmorphieViewProvider _amorphie = AmorphieViewProvider();
  final VNextViewProvider _vnext = VNextViewProvider();
  final WorkflowInstanceManager _instanceManager = GetIt.I<WorkflowInstanceManager>();

  WorkflowViewProvider _resolveProvider(WorkflowInstanceEntity instance) {
    return instance.engine == WorkflowEngine.vnext ? _vnext : _amorphie;
  }

  Future<NeoResponse> loadView({
    required String instanceId,
    Map<String, String>? headers,
  }) async {
    final instance = _instanceManager.getInstance(instanceId);
    if (instance == null) {
      return NeoErrorResponse(
        NeoError(error: const NeoErrorDetail(description: 'Instance not found')),
        statusCode: 404,
        headers: const {},
      );
    }
    return _resolveProvider(instance).loadView(instance: instance, headers: headers);
  }

  Future<NeoResponse?> loadData({
    required String instanceId,
    Map<String, String>? headers,
  }) async {
    final instance = _instanceManager.getInstance(instanceId);
    if (instance == null) return null;
    return _resolveProvider(instance).loadData(instance: instance, headers: headers);
  }
}


