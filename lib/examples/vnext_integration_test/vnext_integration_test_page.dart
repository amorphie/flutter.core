import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_extensions.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_client.dart';

/// Simple vNext Integration Test Page
/// Demonstrates: Init workflow -> Display view/data info -> Load actions
class VNextIntegrationTestPage extends StatefulWidget {
  const VNextIntegrationTestPage({Key? key}) : super(key: key);

  @override
  State<VNextIntegrationTestPage> createState() => _VNextIntegrationTestPageState();
}

class _VNextIntegrationTestPageState extends State<VNextIntegrationTestPage> {
  final TextEditingController _baseUrlController = TextEditingController(text: 'http://localhost:4201');
  final TextEditingController _domainController = TextEditingController(text: 'core');
  
  VNextWorkflowClient? _vNextClient;
  bool _isLoading = false;
  String _status = 'Ready to initialize vNext OAuth workflow';
  
  // Workflow state
  Map<String, dynamic>? _workflowInstance;
  VNextExtensions? _extensions;
  Map<String, dynamic>? _viewData;
  Map<String, dynamic>? _instanceData;

  @override
  void initState() {
    super.initState();
    _initializeClient();
  }

  void _initializeClient() {
    final mockNetworkManager = _MockNeoNetworkManager(
      baseUrl: _baseUrlController.text,
      httpClient: http.Client(),
    );
    
    _vNextClient = VNextWorkflowClient(
      networkManager: mockNetworkManager,
      logger: _SimpleLogger(),
    );
  }

  void _updateStatus(String status) {
    setState(() {
      _status = status;
    });
  }

  /// Step 1: Initialize vNext OAuth workflow
  Future<void> _initializeWorkflow() async {
    setState(() {
      _isLoading = true;
      _workflowInstance = null;
      _extensions = null;
      _viewData = null;
      _instanceData = null;
    });

    _updateStatus('Initializing OAuth workflow...');

    try {
      final response = await _vNextClient!.initWorkflow(
        domain: _domainController.text,
        workflowName: 'oauth-authentication',
        key: 'test-oauth-${DateTime.now().millisecondsSinceEpoch}',
        attributes: {
          'username': '34987491778',
          'password': '112233',
          'grant_type': 'password',
          'client_id': 'acme',
          'client_secret': '1q2w3e*',
          'scope': 'openid profile product-api',
        },
      );

      if (response.isSuccess) {
        final initResponse = response.asSuccess.data;
        final instanceId = initResponse['id'] as String?;
        
        if (instanceId != null) {
          _updateStatus('✅ Workflow initialized, fetching details...');
          
          // Fetch full workflow instance details
          final instanceResponse = await _vNextClient!.getWorkflowInstance(
            domain: _domainController.text,
            workflowName: 'oauth-authentication',
            instanceId: instanceId,
          );
          
          if (instanceResponse.isSuccess) {
            _workflowInstance = instanceResponse.asSuccess.data;
            
            // Parse extensions if they exist
            final extensionsData = _workflowInstance!['extensions'] as Map<String, dynamic>?;
            if (extensionsData != null) {
              _extensions = VNextExtensions.fromJson(extensionsData);
            }
            
            _updateStatus('✅ Workflow initialized and details loaded successfully');
          } else {
            _updateStatus('❌ Failed to fetch workflow details');
          }
        } else {
          _updateStatus('❌ No instance ID returned from initialization');
        }
      } else {
        _updateStatus('❌ Failed to initialize workflow: ${response.asError.error.error.description}');
      }
    } catch (e) {
      _updateStatus('💥 Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Step 2: Load view data from vNext extensions
  Future<void> _loadViewData() async {
    if (_extensions?.view?.href == null) {
      _updateStatus('⚠️ No view endpoint available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _updateStatus('Loading view data...');

    try {
      final response = await _vNextClient!.networkManager.call(
        NeoHttpCall(
          endpoint: 'vnext-direct-href',
          pathParameters: {'HREF': _extensions!.view!.href},
        ),
      );

      if (response.isSuccess) {
        _viewData = response.asSuccess.data;
        _updateStatus('✅ View data loaded successfully');
      } else {
        _updateStatus('❌ Failed to load view data');
      }
    } catch (e) {
      _updateStatus('💥 Error loading view: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Step 3: Load instance data from vNext extensions
  Future<void> _loadInstanceData() async {
    if (_extensions?.data?.href == null) {
      _updateStatus('⚠️ No data endpoint available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _updateStatus('Loading instance data...');

    try {
      final response = await _vNextClient!.networkManager.call(
        NeoHttpCall(
          endpoint: 'vnext-direct-href',
          pathParameters: {'HREF': _extensions!.data!.href},
        ),
      );

      if (response.isSuccess) {
        _instanceData = response.asSuccess.data;
        _updateStatus('✅ Instance data loaded successfully');
      } else {
        _updateStatus('❌ Failed to load instance data');
      }
    } catch (e) {
      _updateStatus('💥 Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Step 4: Refresh workflow instance
  Future<void> _refreshWorkflow() async {
    if (_workflowInstance == null) {
      _updateStatus('⚠️ No workflow to refresh');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _updateStatus('Refreshing workflow...');

    try {
      final instanceId = _workflowInstance!['id'] as String;
      final response = await _vNextClient!.getWorkflowInstance(
        domain: _domainController.text,
        workflowName: 'oauth-authentication',
        instanceId: instanceId,
      );

      if (response.isSuccess) {
        _workflowInstance = response.asSuccess.data;
        _extensions = VNextExtensions.fromJson(
          _workflowInstance!['extensions'] as Map<String, dynamic>
        );
        _updateStatus('✅ Workflow refreshed successfully');
      } else {
        _updateStatus('❌ Failed to refresh workflow');
      }
    } catch (e) {
      _updateStatus('💥 Error refreshing: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('vNext Integration Test'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _baseUrlController,
                            decoration: const InputDecoration(labelText: 'vNext Base URL'),
                            onChanged: (_) => _initializeClient(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _domainController,
                            decoration: const InputDecoration(labelText: 'Domain'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _initializeWorkflow,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Initialize OAuth Workflow'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading || _extensions?.view?.href == null ? null : _loadViewData,
                          icon: const Icon(Icons.visibility),
                          label: const Text('Load View Data'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading || _extensions?.data?.href == null ? null : _loadInstanceData,
                          icon: const Icon(Icons.data_object),
                          label: const Text('Load Instance Data'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading || _workflowInstance == null ? null : _refreshWorkflow,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Workflow'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_isLoading) 
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        _status.startsWith('✅') ? Icons.check_circle : 
                        _status.startsWith('❌') || _status.startsWith('💥') ? Icons.error :
                        Icons.info,
                        color: _status.startsWith('✅') ? Colors.green :
                               _status.startsWith('❌') || _status.startsWith('💥') ? Colors.red :
                               Colors.blue,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Workflow Instance Info
                    if (_workflowInstance != null) ...[
                      _buildInfoCard(
                        'Workflow Instance',
                        {
                          'Instance ID': _workflowInstance!['id']?.toString() ?? 'Unknown',
                          'Flow': _workflowInstance!['flow']?.toString() ?? 'Unknown',
                          'Domain': _workflowInstance!['domain']?.toString() ?? 'Unknown',
                          'Version': _workflowInstance!['flowVersion']?.toString() ?? 'Unknown',
                          'Current State': _extensions?.currentState ?? 'Unknown',
                          'Status': _extensions?.status ?? 'Unknown',
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Extensions Info
                    if (_extensions != null) ...[
                      _buildInfoCard(
                        'vNext Extensions',
                        {
                          'View Endpoint': _extensions!.view?.href ?? 'None',
                          'Load Data': (_extensions!.view?.loadData ?? false).toString(),
                          'Data Endpoint': _extensions!.data?.href ?? 'None',
                          'Available Transitions': _extensions!.transitions.isEmpty ? 'None' : _extensions!.transitions.join(', '),
                        },
                      ),
                      const SizedBox(height: 16),
                    ] else if (_workflowInstance != null) ...[
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Extensions Not Available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'This workflow instance does not have vNext extensions (view/data endpoints). '
                                'This might be normal depending on the workflow state or configuration.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // View Data
                    if (_viewData != null) ...[
                      _buildDataCard('View Data', _viewData!),
                      const SizedBox(height: 16),
                    ],

                    // Instance Data
                    if (_instanceData != null) ...[
                      _buildDataCard('Instance Data', _instanceData!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, Map<String, String> info) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...info.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text('${entry.key}:', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: Text(entry.value, style: const TextStyle(fontFamily: 'monospace')),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String title, Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                const JsonEncoder.withIndent('  ').convert(data),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple logger implementation
class _SimpleLogger implements NeoLogger {
  @override
  void logConsole(dynamic message, {dynamic logLevel}) {
    print('[LOG] $message');
  }

  @override
  void logError(String message, {Map<String, dynamic>? properties}) {
    print('[ERROR] $message');
    if (properties != null) print('Properties: $properties');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Minimal mock network manager
class _MockNeoNetworkManager implements NeoNetworkManager {
  final String baseUrl;
  final http.Client httpClient;
  
  // API base path for vNext endpoints
  String get apiBasePath => '$baseUrl/api/v1';

  _MockNeoNetworkManager({
    required this.baseUrl,
    required this.httpClient,
  });

  @override
  Future<NeoResponse> call(NeoHttpCall neoCall) async {
    String url;
    
    switch (neoCall.endpoint) {
      case 'vnext-init-workflow':
        final domain = neoCall.pathParameters?['DOMAIN'] ?? 'core';
        final workflowName = neoCall.pathParameters?['WORKFLOW_NAME'] ?? 'test';
        url = '$apiBasePath/$domain/workflows/$workflowName/instances/start';
        break;
      case 'vnext-get-workflow-instance':
        final domain = neoCall.pathParameters?['DOMAIN'] ?? 'core';
        final workflowName = neoCall.pathParameters?['WORKFLOW_NAME'] ?? 'test';
        final instanceId = neoCall.pathParameters?['INSTANCE_ID'] ?? 'test';
        url = '$apiBasePath/$domain/workflows/$workflowName/instances/$instanceId';
        break;
      case 'vnext-direct-href':
        final href = neoCall.pathParameters?['HREF'] ?? '';
        
        // TEMPORARY WORKAROUND: Backend bug fix needed
        // TODO: Remove this workaround once backend fixes the URL path
        // Issue: Backend returns 'workflows' but should return 'workflow' in the href
        // Example: 'core/workflows/oauth-authentication/...' should be 'core/workflow/oauth-authentication/...'
        final fixedHref = href.replaceFirst('/workflows/', '/workflow/');
        
        // Construct full API URL: backend returns relative path, we need full API path
        url = '$apiBasePath/$fixedHref';
        break;
      default:
        return NeoResponse.error(const NeoError(responseCode: 404), responseHeaders: {});
    }

    try {
      http.Response response;
      Uri uri = Uri.parse(url);
      
      if (neoCall.body != null && neoCall.body.isNotEmpty) {
        response = await httpClient.post(
          uri,
          headers: {'Content-Type': 'application/json', ...neoCall.headerParameters},
          body: jsonEncode(neoCall.body),
        );
      } else {
        response = await httpClient.get(
          uri,
          headers: neoCall.headerParameters,
        );
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return NeoResponse.success(data, responseHeaders: {}, statusCode: response.statusCode);
      } else {
        return NeoResponse.error(
          NeoError(responseCode: response.statusCode),
          responseHeaders: {},
        );
      }
    } catch (e) {
      return NeoResponse.error(const NeoError(responseCode: 500), responseHeaders: {});
    }
  }

  // Minimal implementations for required methods
  @override
  Future<void> init({required bool enableSslPinning}) async {}
  
  @override
  Future<NeoResponse> refreshToken() async => NeoResponse.error(const NeoError(responseCode: 501), responseHeaders: {});
  
  @override
  Future<bool> setTokensByAuthResponse(dynamic authResponse, {bool? isMobUnapproved}) async => false;
  
  @override
  Future<bool> getTemporaryTokenForNotLoggedInUser({NeoHttpCall? currentCall}) async => false;
  
  @override
  bool get isTokenExpired => false;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}