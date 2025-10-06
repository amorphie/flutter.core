import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/http_client_config.dart';
import 'package:neo_core/core/network/models/neo_error.dart';
import 'package:neo_core/core/network/models/neo_http_call.dart';
import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_extensions.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_client.dart';
import 'package:neo_core/core/workflow_form/workflow_engine_config.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';
import 'package:neo_core/core/workflow_form/workflow_router.dart';
import 'package:neo_core/core/workflow_form/workflow_service.dart';
import 'package:neo_core/core/workflow_form/workflow_flutter_bridge.dart';
import 'package:neo_core/core/workflow_form/workflow_ui_events.dart';
import 'package:uuid/uuid.dart';

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
  
  WorkflowFlutterBridge? _bridge;
  WorkflowRouter? _workflowRouter;
  WorkflowService? _workflowService;
  VNextWorkflowClient? _vNextClient;
  WorkflowInstanceManager? _instanceManager;
  String? _currentInstanceId;
  bool _isLoading = false;
  bool _isPollingActive = false;
  String _status = 'Ready to initialize vNext OAuth workflow with automatic updates (using Bridge pattern)';
  
  // Workflow state
  Map<String, dynamic>? _workflowInstance;
  VNextExtensions? _extensions;
  Map<String, dynamic>? _viewData;
  Map<String, dynamic>? _instanceData;
  
  // UI event subscription (replaces manual timer)
  StreamSubscription<WorkflowUIEvent>? _uiEventSubscription;
  
  // Polling state check timer
  Timer? _pollingStateCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializeClient();
  }
  
  @override
  void dispose() {
    _uiEventSubscription?.cancel();
    _pollingStateCheckTimer?.cancel();
    _bridge?.dispose();
    _workflowRouter?.dispose();
    super.dispose();
  }

  void _initializeClient() {
    final logger = _SimpleLogger();
    final mockNetworkManager = _MockNeoNetworkManager(
      baseUrl: _baseUrlController.text,
      httpClient: http.Client(),
    );
    
    _vNextClient = VNextWorkflowClient(
      networkManager: mockNetworkManager,
      logger: logger,
    );
    
    // Create instance manager (shared across router/bridge)
    _instanceManager = WorkflowInstanceManager(logger: logger);
    
    // Create WorkflowRouter with automatic polling support
    final mockHttpClientConfig = _MockHttpClientConfig();
    final mockV1Manager = _MockNeoWorkflowManager();
    
    _workflowRouter = WorkflowRouter(
      v1Manager: mockV1Manager,
      vNextClient: _vNextClient!,
      logger: logger,
      httpClientConfig: mockHttpClientConfig,
      instanceManager: _instanceManager!,
      networkManager: mockNetworkManager,
    );
    
    // Create WorkflowService (pure business logic layer)
    _workflowService = WorkflowService(
      router: _workflowRouter!,
      instanceManager: _instanceManager!,
      logger: logger,
    );
    
    // Create WorkflowFlutterBridge (UI abstraction layer)
    _bridge = WorkflowFlutterBridge(
      workflowService: _workflowService!,
      logger: logger,
    );
    
    // ✅ CRITICAL: Subscribe to bridge UI events
    // This is how NeoClient receives automatic updates!
    _uiEventSubscription = _bridge!.uiEvents.listen(
      _handleUIEvent,
      onError: (error) {
        print('[UI_EVENT] ❌ Stream error: $error');
        _updateStatus('❌ Event stream error: $error');
      },
    );
    
    // Log polling configuration for debugging
    final pollingConfig = mockHttpClientConfig.getWorkflowConfig('oauth-authentication').config;
    print('┌─────────────────────────────────────────────────────────');
    print('│ [POLLING_CONFIG] Configuration loaded');
    print('├─────────────────────────────────────────────────────────');
    print('│ Interval: ${pollingConfig['pollingIntervalSeconds']}s');
    print('│ Duration: ${pollingConfig['pollingDurationSeconds']}s');
    print('│ Max Errors: ${pollingConfig['maxConsecutiveErrors']}');
    print('│ Request Timeout: ${pollingConfig['requestTimeoutSeconds']}s');
    print('└─────────────────────────────────────────────────────────\n');
    
    print('[INIT] ✅ Bridge pattern initialized - listening for UI events');
    
    // Start polling state checker (updates UI to show when polling stops)
    _startPollingStateChecker();
  }
  
  void _startPollingStateChecker() {
    // Cancel existing timer if any
    _pollingStateCheckTimer?.cancel();
    
    print('[POLLING_STATE_CHECK] ▶️ Starting state checker timer');
    _pollingStateCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkPollingState();
    });
  }
  
  void _checkPollingState() {
    if (_currentInstanceId == null || _workflowService == null) {
      print('[POLLING_STATE_CHECK] Skipped - instanceId: $_currentInstanceId, service: ${_workflowService != null}');
      return;
    }
    
    final isActive = _workflowService!.isPollingActive(_currentInstanceId!);
    print('[POLLING_STATE_CHECK] Instance: $_currentInstanceId, IsActive: $isActive, Previous: $_isPollingActive');
    
    if (isActive != _isPollingActive) {
      setState(() {
        _isPollingActive = isActive;
      });
      print('[POLLING_STATE] ⚡ Polling state changed: ${isActive ? "ACTIVE ✅" : "STOPPED 🛑"}');
      
      // Stop the timer when polling becomes inactive to save resources
      if (!isActive) {
        _stopPollingStateChecker();
      }
    }
  }
  
  void _stopPollingStateChecker() {
    print('[POLLING_STATE_CHECK] ⏹️ Stopping state checker timer (no active polling)');
    _pollingStateCheckTimer?.cancel();
    _pollingStateCheckTimer = null;
  }
  
  void _handleUIEvent(WorkflowUIEvent event) {
    print('┌─────────────────────────────────────────────────────────');
    print('│ [UI_EVENT] Received event from bridge');
    print('├─────────────────────────────────────────────────────────');
    print('│ Type: ${event.type}');
    print('│ Instance ID: ${event.instanceId}');
    print('│ Page ID: ${event.pageId}');
    print('│ Has Page Data: ${event.pageData != null}');
    print('└─────────────────────────────────────────────────────────\n');
    
    switch (event.type) {
      case WorkflowUIEventType.navigate:
        // Extract instance ID from event
        if (event.instanceId != null) {
          setState(() {
            _currentInstanceId = event.instanceId!;
            _isPollingActive = true; // Polling starts on workflow init
          });
          _updateStatus('🎯 Navigation event received - refreshing workflow...');
          _startPollingStateChecker(); // Restart checker for new workflow
          _refreshWorkflow();
        }
        break;
        
      case WorkflowUIEventType.updateData:
        // Automatic data update from long polling
        _updateStatus('🔄 Auto-update from long polling - refreshing...');
        if (_currentInstanceId != null) {
          _refreshWorkflow();
        }
        break;
        
      case WorkflowUIEventType.error:
        _updateStatus('❌ Error: ${event.error}');
        break;
        
      case WorkflowUIEventType.loading:
        // Handle loading state if needed
        setState(() {
          _isLoading = event.isLoading;
        });
        break;
        
      case WorkflowUIEventType.silent:
        // Silent event - workflow initialized but no page navigation
        print('[UI_EVENT] Silent event received - workflow initialized');
        if (event.instanceId != null) {
          setState(() {
            _currentInstanceId = event.instanceId!;
            _isPollingActive = true; // Polling starts on workflow init
          });
          _updateStatus('✅ Workflow initialized via silent event - fetching details...');
          _startPollingStateChecker(); // Restart checker for new workflow
          _refreshWorkflow();
        }
        break;
        
      case WorkflowUIEventType.showDialog:
        // Handle dialog if needed
        print('[UI_EVENT] Dialog event received');
        break;
    }
  }

  void _updateStatus(String status) {
    setState(() {
      _status = status;
    });
  }

  /// Generate required vNext headers as per Postman collection
  Map<String, String> _generateVNextHeaders() {
    const uuid = Uuid();
    return {
      'Accept-Language': 'tr-TR',
      'X-Request-Id': uuid.v4(),
      'X-Device-Id': uuid.v4(),
      'X-Token-Id': uuid.v4(),
      'X-Device-Info': 'Flutter Test Client',
      'X-Forwarded-For': '127.0.0.1',
    };
  }

  /// Step 1: Initialize vNext OAuth workflow
  Future<void> _initializeWorkflow() async {
    print('\n========== INIT WORKFLOW CALLED ==========');
    setState(() {
      _isLoading = true;
      _workflowInstance = null;
      _extensions = null;
      _currentInstanceId = null;
    });

    _updateStatus('Initializing workflow via WorkflowFlutterBridge (NeoClient pattern)...');

    try {
      print('[INIT] Calling _bridge.initWorkflow()...');
      
      // ✅ Use bridge instead of direct router call (matches NeoClient)
      await _bridge!.initWorkflow(
        workflowName: 'oauth-authentication',
        parameters: {
          'username': '34987491778',
          'password': '112233',
          'grant_type': 'password',
          'client_id': 'acme',
          'client_secret': '1q2w3e*',
          'scope': 'openid profile product-api',
        },
        headers: _generateVNextHeaders(),
        uiConfig: const WorkflowUIConfig(
          displayLoading: false, // We manage loading ourselves for demo purposes
        ),
      );
      
      print('[INIT] Bridge.initWorkflow() completed');
      print('[INIT] Current instance ID: $_currentInstanceId');
      
      // Bridge will emit a navigate or silent event
      // _handleUIEvent will be called automatically
      // Long polling starts automatically in WorkflowRouter
      _updateStatus('✅ Workflow initialized - waiting for UI events from bridge...');
      
    } catch (e, stackTrace) {
      _updateStatus('💥 Error during initialization: $e');
      print('[INIT] ❌ Exception: $e');
      print('[INIT] ❌ Stack trace: $stackTrace');
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('========== INIT WORKFLOW END ==========\n');
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
    print('[REFRESH] _refreshWorkflow called');
    print('[REFRESH] _currentInstanceId: $_currentInstanceId');
    print('[REFRESH] _workflowInstance: ${_workflowInstance != null ? "exists" : "null"}');
    
    if (_currentInstanceId == null) {
      print('[REFRESH] ❌ No instance ID available');
      _updateStatus('⚠️ No workflow instance to refresh');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _updateStatus('Refreshing workflow...');

    try {
      print('[REFRESH] Fetching workflow instance: $_currentInstanceId');
      final response = await _vNextClient!.getWorkflowInstance(
        domain: _domainController.text,
        workflowName: 'oauth-authentication',
        instanceId: _currentInstanceId!,
        headers: _generateVNextHeaders(),
      );
      
      print('[REFRESH] Response received: ${response.isSuccess ? "success" : "error"}');

      if (response.isSuccess) {
        final previousStatus = _extensions?.status;
        
        _workflowInstance = response.asSuccess.data;
        _extensions = VNextExtensions.fromJson(
          _workflowInstance!['extensions'] as Map<String, dynamic>
        );
        
        final newStatus = _extensions?.status;
        
        // Log status change if it happened
        if (previousStatus != null && previousStatus != newStatus) {
          print('[POLLING] 🔄 Status changed: $previousStatus → $newStatus');
        }
        
        // Status display - show actual polling state
        if (newStatus == 'B') {
          final pollingStatus = _isPollingActive ? 'long polling active' : 'long polling stopped';
          _updateStatus('🔄 Workflow refreshed - BLOCKED ($pollingStatus)');
        } else {
          _updateStatus('✅ Workflow refreshed - Status: $newStatus');
        }
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

  /// Approve Push Notification MFA
  Future<void> _approvePushMfa() async {
    final subflowInfo = _getActiveSubflowInfo();
    if (subflowInfo == null) {
      _updateStatus('⚠️ No active MFA subflow found');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('[DEBUG] Approving MFA for subflow:');
    print('  Domain: ${subflowInfo['domain']}');
    print('  Workflow: ${subflowInfo['workflowName']}');
    print('  Instance ID: ${subflowInfo['instanceId']}');
    print('  Transition: push-approved');

    _updateStatus('Approving push notification MFA...');

    try {
      final response = await _vNextClient!.postTransition(
        domain: subflowInfo['domain'] as String,
        workflowName: subflowInfo['workflowName'] as String,
        instanceId: subflowInfo['instanceId'] as String,
        transitionKey: 'push-approved',
        data: {},
        headers: _generateVNextHeaders(),
      );
      
      print('[DEBUG] MFA approval response status: ${response.isSuccess ? "SUCCESS" : "ERROR"}');

      if (response.isSuccess) {
        _updateStatus('✅ Push MFA approved! Refreshing workflow...');
        
        // Wait a bit for the backend to process
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Refresh to get updated state
        await _refreshWorkflow();
      } else {
        _updateStatus('❌ Failed to approve MFA: ${response.asError.error.error.description}');
      }
    } catch (e) {
      _updateStatus('💥 Error approving MFA: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Deny Push Notification MFA
  Future<void> _denyPushMfa() async {
    final subflowInfo = _getActiveSubflowInfo();
    if (subflowInfo == null) {
      _updateStatus('⚠️ No active MFA subflow found');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _updateStatus('Denying push notification MFA...');

    try {
      final response = await _vNextClient!.postTransition(
        domain: subflowInfo['domain'] as String,
        workflowName: subflowInfo['workflowName'] as String,
        instanceId: subflowInfo['instanceId'] as String,
        transitionKey: 'push-denied',
        data: {},
        headers: _generateVNextHeaders(),
      );

      if (response.isSuccess) {
        _updateStatus('❌ Push MFA denied. Authentication will fail.');
        
        // Wait a bit for the backend to process
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Refresh to get updated state
        await _refreshWorkflow();
      } else {
        _updateStatus('❌ Failed to deny MFA: ${response.asError.error.error.description}');
      }
    } catch (e) {
      _updateStatus('💥 Error denying MFA: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get active subflow information for MFA
  Map<String, dynamic>? _getActiveSubflowInfo() {
    if (_workflowInstance == null) return null;
    
    final extensions = _workflowInstance!['extensions'] as Map<String, dynamic>?;
    if (extensions == null) return null;
    
    final activeCorrelations = extensions['activeCorrelations'] as List<dynamic>?;
    if (activeCorrelations == null || activeCorrelations.isEmpty) return null;
    
    final correlation = activeCorrelations.first as Map<String, dynamic>;
    
    return {
      'instanceId': correlation['subFlowInstanceId'],
      'workflowName': correlation['subFlowName'],
      'domain': correlation['subFlowDomain'],
      'parentState': correlation['parentState'],
      'isCompleted': correlation['isCompleted'] ?? false,
    };
  }

  /// Check if workflow is in Push MFA state
  bool _isInPushMfaState() {
    if (_extensions == null) return false;
    
    final currentState = _extensions!.currentState;
    return currentState == 'push-notification-mfa';
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
                        // MFA Approve Button (shown only in push MFA state)
                        if (_isInPushMfaState())
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _approvePushMfa,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Approve MFA'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        // MFA Deny Button (shown only in push MFA state)
                        if (_isInPushMfaState())
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _denyPushMfa,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Deny MFA'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                    // Polling status indicator
                    if (_currentInstanceId != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _isPollingActive ? Icons.sync : Icons.sync_disabled,
                            size: 16,
                            color: _isPollingActive ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isPollingActive ? 'Long polling active' : 'Long polling stopped',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isPollingActive ? Colors.green.shade700 : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
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

                    // MFA State Alert Card
                    if (_isInPushMfaState()) ...[
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.security, color: Colors.blue.shade700, size: 32),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Multi-Factor Authentication Required',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Subflow: ${_getActiveSubflowInfo()?['workflowName'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade600,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'A push notification has been sent to the registered device. '
                                'Please approve or deny the authentication request using the buttons above.',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subflow Instance ID:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      _getActiveSubflowInfo()?['instanceId'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
    
    print('[NETWORK] Endpoint: ${neoCall.endpoint}');
    
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
      case 'vnext-post-transition':
        final domain = neoCall.pathParameters?['DOMAIN'] ?? 'core';
        final workflowName = neoCall.pathParameters?['WORKFLOW_NAME'] ?? 'test';
        final instanceId = neoCall.pathParameters?['INSTANCE_ID'] ?? 'test';
        final transitionKey = neoCall.pathParameters?['TRANSITION_KEY'] ?? 'transition';
        url = '$apiBasePath/$domain/workflows/$workflowName/instances/$instanceId/transitions/$transitionKey';
        print('[NETWORK] POST Transition URL: $url');
        print('[NETWORK] Transition Key: $transitionKey');
        print('[NETWORK] Body: ${jsonEncode(neoCall.body)}');
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
      
      // Determine HTTP method based on endpoint type
      String method;
      if (neoCall.endpoint == 'vnext-post-transition') {
        method = 'PATCH';
      } else if (neoCall.endpoint == 'vnext-init-workflow') {
        method = 'POST';
      } else {
        method = 'GET';
      }
      
      print('[NETWORK] Making request to: $url');
      print('[NETWORK] Method: $method');
      
      if (method == 'PATCH') {
        response = await httpClient.patch(
          uri,
          headers: {'Content-Type': 'application/json', ...neoCall.headerParameters},
          body: jsonEncode(neoCall.body),
        );
      } else if (method == 'POST') {
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
      
      print('[NETWORK] Response status: ${response.statusCode}');
      print('[NETWORK] Response body length: ${response.body.length}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return NeoResponse.success(data, responseHeaders: {}, statusCode: response.statusCode);
      } else {
        print('[NETWORK] Error response: ${response.body}');
        return NeoResponse.error(
          NeoError(responseCode: response.statusCode),
          responseHeaders: {},
        );
      }
    } catch (e) {
      print('[NETWORK] Exception: $e');
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

/// Mock HTTP Client Config for WorkflowRouter
class _MockHttpClientConfig implements HttpClientConfig {
  @override
  WorkflowEngineConfig getWorkflowConfig(String workflowName) {
    return WorkflowEngineConfig(
      workflowName: workflowName,
      engine: 'vnext',
      config: {
        'domain': 'core',
        'baseUrl': 'http://localhost:4201',
        'pollingIntervalSeconds': 5, // Poll every 5 seconds
        'pollingDurationSeconds': 20, // Stop polling after 20 seconds
        'maxConsecutiveErrors': 10,
        'requestTimeoutSeconds': 30,
      },
    );
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mock V1 Workflow Manager for WorkflowRouter
class _MockNeoWorkflowManager implements NeoWorkflowManager {
  @override
  String get instanceId => 'mock-instance-id';
  
  @override
  String get subFlowInstanceId => 'mock-subflow-instance-id';
  
  @override
  void setInstanceId(String? id, {bool isSubFlow = false}) {}
  
  @override
  void setWorkflowName(String name, {bool isSubFlow = false}) {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}