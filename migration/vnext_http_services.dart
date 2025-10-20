/*
 * Migration helper: define vNext HttpService entries for HttpClientConfig
 *
 * Based on PR #261 (feature/344320-vNext) endpoint keys and placeholders.
 * Keys used by the vNext client:
 *  - 'vnext-init-workflow'
 *  - 'vnext-post-transition'
 *  - 'vnext-get-available-transitions'
 *  - 'vnext-get-workflow-instance'
 *  - 'vnext-list-workflow-instances'
 *  - 'vnext-get-instance-history'
 *  - 'vnext-get-system-health'
 *  - 'vnext-get-system-metrics'
 */

import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/core/network/models/http_service.dart';

// Path parameter placeholders expected by the client
const String _pDomain = 'DOMAIN';
const String _pWorkflowName = 'WORKFLOW_NAME';
const String _pInstanceId = 'INSTANCE_ID';
const String _pTransitionName = 'TRANSITION_NAME';

/// Returns canonical vNext HttpService entries to merge into HttpClientConfig.services
List<HttpService> getVNextHttpServices(String hostKey) {
  return <HttpService>[
    // POST /{DOMAIN}/workflows/{WORKFLOW_NAME}/instances
    HttpService(
      key: 'vnext-init-workflow',
      method: HttpMethod.post,
      host: hostKey,
      name: '/{$_pDomain}/workflows/{$_pWorkflowName}/instances',
    ),

    // POST /{DOMAIN}/workflows/{WORKFLOW_NAME}/instances/{INSTANCE_ID}/transitions/{TRANSITION_NAME}
    HttpService(
      key: 'vnext-post-transition',
      method: HttpMethod.post,
      host: hostKey,
      name: '/{$_pDomain}/workflows/{$_pWorkflowName}/instances/{$_pInstanceId}/transitions/{$_pTransitionName}',
    ),

    // GET /{DOMAIN}/workflows/{WORKFLOW_NAME}/instances/{INSTANCE_ID}/transitions
    HttpService(
      key: 'vnext-get-available-transitions',
      method: HttpMethod.get,
      host: hostKey,
      name: '/{$_pDomain}/workflows/{$_pWorkflowName}/instances/{$_pInstanceId}/transitions',
    ),

    // GET /{DOMAIN}/workflows/{WORKFLOW_NAME}/instances/{INSTANCE_ID}
    HttpService(
      key: 'vnext-get-workflow-instance',
      method: HttpMethod.get,
      host: hostKey,
      name: '/{$_pDomain}/workflows/{$_pWorkflowName}/instances/{$_pInstanceId}',
    ),

    // GET /{DOMAIN}/workflows/{WORKFLOW_NAME}/instances
    HttpService(
      key: 'vnext-list-workflow-instances',
      method: HttpMethod.get,
      host: hostKey,
      name: '/{$_pDomain}/workflows/{$_pWorkflowName}/instances',
    ),

    // GET /{DOMAIN}/workflows/{WORKFLOW_NAME}/instances/{INSTANCE_ID}/history
    HttpService(
      key: 'vnext-get-instance-history',
      method: HttpMethod.get,
      host: hostKey,
      name: '/{$_pDomain}/workflows/{$_pWorkflowName}/instances/{$_pInstanceId}/history',
    ),

    // GET /system/health
    HttpService(
      key: 'vnext-get-system-health',
      method: HttpMethod.get,
      host: hostKey,
      name: '/system/health',
    ),

    // GET /system/metrics
    HttpService(
      key: 'vnext-get-system-metrics',
      method: HttpMethod.get,
      host: hostKey,
      name: '/system/metrics',
    ),
  ];
}


