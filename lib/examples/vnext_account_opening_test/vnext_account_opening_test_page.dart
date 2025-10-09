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
import 'package:neo_core/core/workflow_form/workflow_flutter_bridge.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';
import 'package:neo_core/core/workflow_form/workflow_router.dart';
import 'package:neo_core/core/workflow_form/workflow_service.dart';
import 'package:neo_core/core/workflow_form/workflow_ui_events.dart';
import 'package:uuid/uuid.dart';

/// vNext Account Opening Integration Test Page
/// Demonstrates: Init account opening workflow -> Display view/data info -> Handle transitions
class VNextAccountOpeningTestPage extends StatefulWidget {
  const VNextAccountOpeningTestPage({Key? key}) : super(key: key);

  @override
  State<VNextAccountOpeningTestPage> createState() => _VNextAccountOpeningTestPageState();
}

class _VNextAccountOpeningTestPageState extends State<VNextAccountOpeningTestPage> {
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
  String _status = 'Ready to initialize vNext Account Opening workflow with automatic updates (using Bridge pattern)';
  
  // Workflow state
  Map<String, dynamic>? _workflowInstance;
  VNextExtensions? _extensions;
  
  // Legacy page content loading (REMOVED - use _viewData instead)
  
  // Workflow view and instance data (similar to OAuth sample)
  Map<String, dynamic>? _viewData;
  Map<String, dynamic>? _instanceData;
  
  // UI event subscription (replaces manual timer)
  StreamSubscription<WorkflowUIEvent>? _uiEventSubscription;
  
  // Polling state check timer
  Timer? _pollingStateCheckTimer;

  // Account opening form data
  final TextEditingController _accountNameController = TextEditingController(text: 'My Savings Account');
  final TextEditingController _initialDepositController = TextEditingController(text: '1000');
  String _selectedAccountType = 'demand-deposit';
  String _selectedCurrency = 'TRY';
  String _selectedBranchCode = '0001';
  String _selectedAccountPurpose = 'personal-banking';

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
    
    // Create WorkflowService (business logic layer)
    _workflowService = WorkflowService(
      router: _workflowRouter!,
      logger: logger,
      instanceManager: _instanceManager!,
    );
    
    // Create WorkflowFlutterBridge (UI integration layer)
    _bridge = WorkflowFlutterBridge(
      workflowService: _workflowService!,
      logger: logger,
    );
    
    // Subscribe to UI events from bridge
    _uiEventSubscription = _bridge!.uiEvents.listen(_handleUIEvent);
    
    logger.logConsole('[LOG] [WorkflowInstanceManager] Initialized');
    logger.logConsole('[LOG] [VNextWorkflowMessageHandlerFactory] Factory initialized');
    logger.logConsole('[LOG] [WorkflowRouter] Router initialized with vNext message handler support');
    
    print('[INIT] ✅ Bridge pattern initialized - listening for UI events');
    
    _updateStatus('✅ vNext Account Opening client initialized with bridge pattern');
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

  /// Step 1: Initialize vNext Account Opening workflow
  Future<void> _initializeWorkflow() async {
    print('\n========== INIT ACCOUNT OPENING WORKFLOW CALLED ==========');
    setState(() {
      _isLoading = true;
      _workflowInstance = null;
      _extensions = null;
      _currentInstanceId = null;
    });

    _updateStatus('Initializing account opening workflow via WorkflowFlutterBridge (NeoClient pattern)...');

    try {
      print('[INIT] Calling _bridge.initWorkflow()...');
      
      // ✅ Use bridge instead of direct router call (matches NeoClient)
      await _bridge!.initWorkflow(
        workflowName: 'account-opening',
        parameters: {
          // Initial account type selection
          'accountType': _selectedAccountType,
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
      _updateStatus('✅ Account opening workflow initialized - waiting for UI events from bridge...');
      
    } catch (e, stackTrace) {
      print('[INIT] ❌ Error initializing workflow: $e');
      print('[INIT] Stack trace: $stackTrace');
      _updateStatus('❌ Error initializing workflow: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    
    print('========== INIT ACCOUNT OPENING WORKFLOW END ==========\n');
  }

  /// Handle UI events from the bridge (replaces manual polling)
  void _handleUIEvent(WorkflowUIEvent event) {
    print('\n┌─────────────────────────────────────────────────────────');
    print('│ [UI_EVENT] Received event from bridge');
    print('├─────────────────────────────────────────────────────────');
    print('│ Type: ${event.type}');
    print('│ Instance ID: ${event.instanceId}');
    print('│ Page ID: ${event.pageId}');
    print('│ Has Page Data: ${event.pageData?.isNotEmpty ?? false}');
    print('└─────────────────────────────────────────────────────────');
    
    setState(() {
      _currentInstanceId = event.instanceId;
      
      // Update polling state
      if (event.type == WorkflowUIEventType.navigate || event.type == WorkflowUIEventType.silent) {
        _isPollingActive = true;
        _startPollingStateChecker();
      }
    });
    
    // Refresh workflow data after UI event
    if (event.instanceId != null) {
      _refreshWorkflow();
    }
    
    _updateStatus('📨 UI Event: ${event.type} - Instance: ${event.instanceId}');
  }

  /// Refresh workflow instance data
  Future<void> _refreshWorkflow() async {
    if (_currentInstanceId == null) {
      print('[REFRESH] No current instance ID, skipping refresh');
      return;
    }
    
    print('[REFRESH] _refreshWorkflow called');
    print('[REFRESH] _currentInstanceId: $_currentInstanceId');
    print('[REFRESH] _workflowInstance: ${_workflowInstance != null ? 'exists' : 'null'}');
    
    try {
      print('[REFRESH] Fetching workflow instance: $_currentInstanceId');
      
      final response = await _vNextClient!.getWorkflowInstance(
        workflowName: 'account-opening',
        instanceId: _currentInstanceId!,
        domain: _domainController.text,
        headers: _generateVNextHeaders(),
      );
      
      print('[REFRESH] Response received: ${response.isSuccess ? 'success' : 'error'}');
      
      if (response.isSuccess && response is NeoSuccessResponse) {
        setState(() {
          _workflowInstance = response.data;
          _extensions = VNextExtensions.fromJson(response.data['extensions'] ?? {});
        });
        
        _updateStatus('✅ Workflow refreshed - State: ${_extensions?.status ?? 'unknown'}');
      } else if (response is NeoErrorResponse) {
        print('[REFRESH] ❌ Error refreshing workflow: ${response.error.error.description}');
        _updateStatus('❌ Error refreshing workflow: ${response.error.error.description}');
      }
    } catch (e, stackTrace) {
      print('[REFRESH] ❌ Exception refreshing workflow: $e');
      print('[REFRESH] Stack trace: $stackTrace');
      _updateStatus('❌ Exception refreshing workflow: $e');
    }
  }

  /// Start polling state checker
  void _startPollingStateChecker() {
    _pollingStateCheckTimer?.cancel();
    _pollingStateCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkPollingState();
    });
  }

  /// Check if polling is still active
  void _checkPollingState() {
    final isActive = _workflowService?.isPollingActive(_currentInstanceId ?? '') ?? false;
    
    if (_isPollingActive != isActive) {
      print('[POLLING_CHECK] 🔄 Polling state changed: $_isPollingActive -> $isActive');
      setState(() {
        _isPollingActive = isActive;
      });
      
      if (!isActive) {
        print('[POLLING_CHECK] ⏹️ Polling stopped - stopping state checker');
        _stopPollingStateChecker();
      }
    }
  }

  /// Stop polling state checker
  void _stopPollingStateChecker() {
    _pollingStateCheckTimer?.cancel();
    _pollingStateCheckTimer = null;
  }

  /// Submit account type selection
  Future<void> _submitAccountTypeSelection() async {
    if (_currentInstanceId == null) {
      _updateStatus('❌ No active workflow instance');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _bridge!.postTransition(
        transitionName: 'select-demand-deposit',
        body: {
          'accountType': _selectedAccountType,
        },
        headers: _generateVNextHeaders(),
        instanceId: _currentInstanceId,
      );
      
      _updateStatus('✅ Account type selected: $_selectedAccountType');
    } catch (e) {
      print('[TRANSITION] ❌ Error submitting account type: $e');
      _updateStatus('❌ Error submitting account type: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Submit account details
  Future<void> _submitAccountDetails() async {
    if (_currentInstanceId == null) {
      _updateStatus('❌ No active workflow instance');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _bridge!.postTransition(
        transitionName: 'submit-account-details',
        body: {
          'accountName': _accountNameController.text,
          'currency': _selectedCurrency,
          'branchCode': _selectedBranchCode,
          'initialDeposit': double.tryParse(_initialDepositController.text) ?? 0.0,
          'accountPurpose': _selectedAccountPurpose,
          'notifications': {
            'smsNotifications': true,
            'emailNotifications': true,
            'pushNotifications': true,
          },
        },
        headers: _generateVNextHeaders(),
        instanceId: _currentInstanceId,
      );
      
      _updateStatus('✅ Account details submitted');
    } catch (e) {
      print('[TRANSITION] ❌ Error submitting account details: $e');
      _updateStatus('❌ Error submitting account details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Confirm account opening
  Future<void> _confirmAccountOpening() async {
    if (_currentInstanceId == null) {
      _updateStatus('❌ No active workflow instance');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _bridge!.postTransition(
        transitionName: 'confirm-account-opening',
        body: {
          'confirmed': true,
          'termsAccepted': true,
          'privacyPolicyAccepted': true,
        },
        headers: _generateVNextHeaders(),
        instanceId: _currentInstanceId,
      );
      
      _updateStatus('✅ Account opening confirmed');
    } catch (e) {
      print('[TRANSITION] ❌ Error confirming account opening: $e');
      _updateStatus('❌ Error confirming account opening: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Check if current state allows account type selection
  bool _canSelectAccountType() {
    final currentState = _extensions?.currentState;
    return currentState == 'account-type-selection';
  }

  /// Check if current state allows account details input
  bool _canInputAccountDetails() {
    final currentState = _extensions?.currentState;
    return currentState == 'account-details-input';
  }

  /// Check if current state allows account confirmation
  bool _canConfirmAccount() {
    final currentState = _extensions?.currentState;
    return currentState == 'account-confirmation';
  }

  /// Check if account opening is completed
  bool _isAccountOpeningCompleted() {
    final currentState = _extensions?.currentState;
    return currentState == 'account-opening-success';
  }

  /// Get view key for current state
  String? _getViewKeyForCurrentState() {
    final currentState = _extensions?.currentState;
    if (currentState == null) return null;
    
    // Map workflow states to view keys based on our workflow definition
    switch (currentState) {
      case 'account-type-selection':
        return 'account-type-selection-view';
      case 'account-details-input':
        return 'account-details-input-view';
      case 'account-confirmation':
        return 'account-confirmation-view';
      case 'account-opening-success':
        return 'account-opening-success-view';
      default:
        return null;
    }
  }

  /// REMOVED: Load page content for current state (REDUNDANT - use _loadViewData instead)
  /*
  Future<void> _loadPageContent() async {
    final viewKey = _getViewKeyForCurrentState();
    if (viewKey == null) {
      _updateStatus('❌ No view key available for current state: ${_extensions?.currentState}');
      return;
    }

    setState(() {
      _isLoading = true;
      _pageContent = null;
      _loadedViewKey = null;
    });

    try {
      _updateStatus('🔄 Loading page content for view: $viewKey...');

      // Construct the view fetch URL
      // Based on vNext API structure: /api/v1/{domain}/views/{viewKey}
      final viewUrl = '${_baseUrlController.text}/api/v1/${_domainController.text}/views/$viewKey';
      
      print('[PAGE_CONTENT] Fetching view from: $viewUrl');
      
      final response = await http.get(
        Uri.parse(viewUrl),
        headers: {
          'Content-Type': 'application/json',
          ..._generateVNextHeaders(),
        },
      );

      print('[PAGE_CONTENT] Response status: ${response.statusCode}');
      print('[PAGE_CONTENT] Response body length: ${response.body.length}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        
        setState(() {
          _pageContent = data;
          _loadedViewKey = viewKey;
        });
        
        _updateStatus('✅ Page content loaded for view: $viewKey');
        print('[PAGE_CONTENT] ✅ Successfully loaded content for: $viewKey');
      } else {
        print('[PAGE_CONTENT] ❌ Error response: ${response.body}');
        _updateStatus('❌ Error loading page content: HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('[PAGE_CONTENT] ❌ Exception loading page content: $e');
      print('[PAGE_CONTENT] Stack trace: $stackTrace');
      _updateStatus('❌ Exception loading page content: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  */

  /// Load view data from vNext extensions (similar to OAuth sample)
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

  /// Load instance data from vNext extensions (similar to OAuth sample)
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

  /// REMOVED: Get content from loaded page data (REDUNDANT - use _viewData instead)
  /*
  String? _getPageContentString() {
    if (_pageContent == null) return null;
    
    // Try to extract content from the attributes.content field
    final attributes = _pageContent!['attributes'] as Map<String, dynamic>?;
    final content = attributes?['content'] as String?;
    
    if (content != null && content.isNotEmpty && content != '{}') {
      return content;
    }
    
    // Fallback to showing the entire page content
    return jsonEncode(_pageContent);
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('vNext Account Opening Test'),
        backgroundColor: Colors.green,
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
                    
                    // Initialize Workflow
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _initializeWorkflow,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Initialize Account Opening Workflow', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Removed redundant "Load Page Content" - use "Load View Data" instead
                    
                    // OAuth-style View and Instance Data Buttons
                    if (_currentInstanceId != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading || _extensions?.view?.href == null ? null : _loadViewData,
                              icon: const Icon(Icons.visibility),
                              label: const Text('Load View Data'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading || _extensions?.data?.href == null ? null : _loadInstanceData,
                              icon: const Icon(Icons.data_object),
                              label: const Text('Load Instance Data'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Account Type Selection
                    if (_canSelectAccountType()) ...[
                      const Text('Account Type Selection:', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: _selectedAccountType,
                        onChanged: (value) => setState(() => _selectedAccountType = value!),
                        items: const [
                          DropdownMenuItem(value: 'demand-deposit', child: Text('Demand Deposit Account')),
                          DropdownMenuItem(value: 'time-deposit', child: Text('Time Deposit Account')),
                          DropdownMenuItem(value: 'investment-account', child: Text('Investment Account')),
                          DropdownMenuItem(value: 'savings-account', child: Text('Savings Account')),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitAccountTypeSelection,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text('Select Account Type', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Account Details Input
                    if (_canInputAccountDetails()) ...[
                      const Text('Account Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextField(
                        controller: _accountNameController,
                        decoration: const InputDecoration(labelText: 'Account Name'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedCurrency,
                              onChanged: (value) => setState(() => _selectedCurrency = value!),
                              items: const [
                                DropdownMenuItem(value: 'TRY', child: Text('Turkish Lira (TRY)')),
                                DropdownMenuItem(value: 'USD', child: Text('US Dollar (USD)')),
                                DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR)')),
                                DropdownMenuItem(value: 'GBP', child: Text('British Pound (GBP)')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _initialDepositController,
                              decoration: const InputDecoration(labelText: 'Initial Deposit'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitAccountDetails,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text('Submit Account Details', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Account Confirmation
                    if (_canConfirmAccount()) ...[
                      const Text('Confirm Account Opening:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Please review your account details and confirm to proceed.'),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _confirmAccountOpening,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Confirm Account Opening', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Success Message
                    if (_isAccountOpeningCompleted()) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('🎉 Account Opening Completed Successfully!', 
                                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (_isPollingActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 4),
                                Text('Long Polling Active', style: TextStyle(fontSize: 12, color: Colors.green)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_currentInstanceId != null) ...[
                      const SizedBox(height: 8),
                      Text('Instance ID: $_currentInstanceId', style: const TextStyle(fontFamily: 'monospace')),
                    ],
                    if (_extensions != null) ...[
                      const SizedBox(height: 8),
                      Text('Current State: ${_extensions!.currentState ?? 'unknown'}'),
                      Text('Status: ${_extensions!.status ?? 'unknown'}'),
                      if (_extensions!.transitions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Available Transitions: ${_extensions!.transitions.join(', ')}'),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Removed redundant Page Content section - use View Data section instead

            const SizedBox(height: 16),

            // Workflow Instance Info (enhanced from OAuth sample)
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

            // Extensions Info (enhanced from OAuth sample)
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

            // View Data (from OAuth sample)
            if (_viewData != null) ...[
              _buildDataCard('View Data', _viewData!),
              const SizedBox(height: 16),
            ],

            // Instance Data (from OAuth sample)
            if (_instanceData != null) ...[
              _buildDataCard('Instance Data', _instanceData!),
              const SizedBox(height: 16),
            ],

            // Workflow Data (Debug)
            if (_workflowInstance != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Workflow Data (Debug)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              const JsonEncoder.withIndent('  ').convert(_workflowInstance),
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build info card for displaying key-value pairs (from OAuth sample)
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

  /// Build data card for displaying JSON data (from OAuth sample)
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
        final workflowName = neoCall.pathParameters?['WORKFLOW_NAME'] ?? 'account-opening';
        url = '$apiBasePath/$domain/workflows/$workflowName/instances/start';
        break;
      case 'vnext-get-workflow-instance':
        final domain = neoCall.pathParameters?['DOMAIN'] ?? 'core';
        final workflowName = neoCall.pathParameters?['WORKFLOW_NAME'] ?? 'account-opening';
        final instanceId = neoCall.pathParameters?['INSTANCE_ID'] ?? 'test';
        url = '$apiBasePath/$domain/workflows/$workflowName/instances/$instanceId';
        break;
      case 'vnext-post-transition':
        final domain = neoCall.pathParameters?['DOMAIN'] ?? 'core';
        final workflowName = neoCall.pathParameters?['WORKFLOW_NAME'] ?? 'account-opening';
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
        // Example: 'core/workflows/account-opening/...' should be 'core/workflow/account-opening/...'
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