import 'package:get_it/get_it.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/workflow_form/workflow_view_provider.dart';

class VNextViewProvider implements WorkflowViewProvider {
  final NeoNetworkManager _networkManager = GetIt.I<NeoNetworkManager>();
  final NeoLogger _logger = GetIt.I<NeoLogger>();

  // Generic vNext function executor endpoint
  static const String _endpointVNextExecute = 'vnext-execute';

  String _normalizeHref(String href) {
    // Ensure href is relative and normalized as /api/v1/<href>
    // Also fix backend bug: convert .../workflows/... -> .../workflow/...
    String trimmed = href.startsWith('/') ? href.substring(1) : href;

    // Apply workflows -> workflow conversion in a robust way
    // Handles both with and without existing /api/v1 prefix
    trimmed = trimmed
        .replaceFirst('core/workflows/', 'core/workflow/')
        .replaceFirst('api/v1/core/workflows/', 'api/v1/core/workflow/')
        .replaceFirst('/core/workflows/', '/core/workflow/');

    final withApi = trimmed.startsWith('api/v1/') ? trimmed : 'api/v1/$trimmed';
    return '/$withApi';
  }

  @override
  Future<NeoResponse> loadView({
    required WorkflowInstanceEntity instance,
    Map<String, String>? headers,
  }) async {
    final vnext = (instance.metadata)['vnextExtensions'] as Map<String, dynamic>?;
    final view = vnext != null ? vnext['view'] as Map<String, dynamic>? : null;
    final href = view != null ? view['href'] as String? : null;
    if (href == null || href.isEmpty) {
      _logger.logConsole('[VNextViewProvider] Missing view href in instance metadata');
      return NeoErrorResponse(
        NeoError(error: const NeoErrorDetail(description: 'vNext view href not available')),
        statusCode: 400,
        headers: const {},
      );
    }

    final normalizedPath = _normalizeHref(href);
    return _networkManager.call(
      NeoHttpCall(
        endpoint: _endpointVNextExecute,
        pathParameters: {'PATH': normalizedPath},
        headerParameters: {'InstanceId': instance.instanceId, ...?headers},
      ),
    );
  }

  @override
  Future<NeoResponse?> loadData({
    required WorkflowInstanceEntity instance,
    Map<String, String>? headers,
  }) async {
    final vnext = (instance.metadata)['vnextExtensions'] as Map<String, dynamic>?;
    final view = vnext != null ? vnext['view'] as Map<String, dynamic>? : null;
    final dataFn = vnext != null ? vnext['data'] as Map<String, dynamic>? : null;
    final shouldLoadData = view != null ? (view['loadData'] as bool? ?? false) : false;
    final href = dataFn != null ? dataFn['href'] as String? : null;

    if (!shouldLoadData || href == null || href.isEmpty) {
      return null;
    }

    final normalizedPath = _normalizeHref(href);
    return _networkManager.call(
      NeoHttpCall(
        endpoint: _endpointVNextExecute,
        pathParameters: {'PATH': normalizedPath},
        headerParameters: {'InstanceId': instance.instanceId, ...?headers},
      ),
    );
  }
}


