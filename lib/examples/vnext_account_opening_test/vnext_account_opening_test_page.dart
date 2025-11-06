import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/neo_adjust.dart';
import 'package:neo_core/core/analytics/neo_elastic.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/analytics/neo_logger_type.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/managers/vnext_long_polling_manager.dart';
import 'package:neo_core/core/network/managers/vnext_polling_event.dart';
import 'package:neo_core/core/network/managers/vnext_polling_event_type.dart';
import 'package:neo_core/core/network/models/http_active_host.dart';
import 'package:neo_core/core/network/models/http_client_config.dart';
import 'package:neo_core/core/network/models/http_client_config_parameters.dart';
import 'package:neo_core/core/network/models/http_host_details.dart';
import 'package:neo_core/core/network/models/http_method.dart';
import 'package:neo_core/core/network/models/http_service.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_instance_snapshot.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_polling_config.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_data_service.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_client.dart';
// NOTE: Cannot import migration helper into lib; define minimal services here for the demo

class VNextAccountOpeningTestPage extends StatefulWidget {
  const VNextAccountOpeningTestPage({super.key});

  @override
  State<VNextAccountOpeningTestPage> createState() => _VNextAccountOpeningTestPageState();
}

class _VNextAccountOpeningTestPageState extends State<VNextAccountOpeningTestPage> {
  bool _loading = false;
  String _status = 'Idle';
  bool _isLongPollingActive = false;
  // Config UI
  final TextEditingController _baseUrlController = TextEditingController(text: 'http://localhost:4201');
  final TextEditingController _domainController = TextEditingController(text: 'core');
  // Store domain and workflowName separately (backend doesn't return them in snapshot)
  String _domain = 'core';
  String _workflowName = 'account-opening';
  // Loaded/normalized data
  Map<String, dynamic>? _componentJson;
  Map<String, dynamic>? _viewDataRaw;
  Map<String, dynamic>? _instanceDataRaw;
  Map<String, dynamic>? _workflowInstanceJson;
  String? _currentInstanceId;
  VNextInstanceSnapshot? _snapshot;
  Map<String, dynamic> _formData = {};
  // Form controllers for different workflow states
  late final TextEditingController _accountTypeController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _currencyController;
  late final TextEditingController _branchCodeController;
  late final TextEditingController _initialDepositController;
  late final TextEditingController _accountPurposeController;
  
  // Boolean values for confirmation step
  bool _confirmed = false;
  bool _termsAccepted = false;
  bool _privacyPolicyAccepted = false;
  
  NeoSharedPrefs? _shared;
  NeoCoreSecureStorage? _storage;
  NeoNetworkManager? _network;
  NeoLogger? _logger;
  VNextWorkflowClient? _client;
  VNextDataService? _dataService;
  VNextLongPollingManager? _pollingManager;
  StreamSubscription<VNextInstanceSnapshot>? _pollingSubscription;
  StreamSubscription<VNextPollingEvent>? _pollingEventSubscription;
  bool _isRefreshingFromPolling = false;

  @override
  void initState() {
    super.initState();
    // Initialize form controllers with default values
    _accountTypeController = TextEditingController(text: 'demand-deposit');
    _accountNameController = TextEditingController(text: 'John Doe');
    _currencyController = TextEditingController(text: 'TRY');
    _branchCodeController = TextEditingController(text: '1001');
    _initialDepositController = TextEditingController(text: '1000');
    _accountPurposeController = TextEditingController(text: 'personal-banking');
    
    // Initialize form data with default values
    _formData = {
      'accountType': 'demand-deposit',
      'accountName': 'John Doe',
      'currency': 'TRY',
      'branchCode': '1001',
      'initialDeposit': 1000,
      'accountPurpose': 'personal-banking',
      'confirmed': false,
      'termsAccepted': false,
      'privacyPolicyAccepted': false,
    };
  }

  @override
  void dispose() {
    _accountTypeController.dispose();
    _accountNameController.dispose();
    _currencyController.dispose();
    _branchCodeController.dispose();
    _initialDepositController.dispose();
    _accountPurposeController.dispose();
    _pollingSubscription?.cancel();
    _pollingEventSubscription?.cancel();
    _pollingManager?.stopAllPolling();
    super.dispose();
  }

  List<Widget> _buildFormFieldsForState(String state) {
    switch (state) {
      case 'account-type-selection':
        return [
          TextField(
            controller: _accountTypeController,
            decoration: const InputDecoration(
              labelText: 'Account Type',
              hintText: 'demand-deposit, savings, time-deposit, investment-account',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _formData['accountType'] = value,
          ),
        ];
      
      case 'account-details-input':
        return [
          TextField(
            controller: _accountNameController,
            decoration: const InputDecoration(
              labelText: 'Account Name',
              hintText: 'Enter account holder name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _formData['accountName'] = value,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _currencyController,
            decoration: const InputDecoration(
              labelText: 'Currency',
              hintText: 'TRY, USD, EUR, GBP',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _formData['currency'] = value,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _branchCodeController,
            decoration: const InputDecoration(
              labelText: 'Branch Code',
              hintText: '4-digit branch code (e.g., 1001)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _formData['branchCode'] = value,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _initialDepositController,
            decoration: const InputDecoration(
              labelText: 'Initial Deposit (Optional)',
              hintText: 'Enter initial deposit amount',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _formData['initialDeposit'] = double.tryParse(value) ?? 0,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _accountPurposeController,
            decoration: const InputDecoration(
              labelText: 'Account Purpose',
              hintText: 'personal-banking, salary-account, savings, business-expenses',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _formData['accountPurpose'] = value,
          ),
        ];
      
      case 'account-confirmation':
        return [
          CheckboxListTile(
            title: const Text('I confirm the account opening'),
            subtitle: const Text('Please confirm that you want to open this account'),
            value: _confirmed,
            onChanged: (value) {
              setState(() {
                _confirmed = value ?? false;
                _formData['confirmed'] = _confirmed;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Terms and Conditions'),
            subtitle: const Text('I accept the terms and conditions'),
            value: _termsAccepted,
            onChanged: (value) {
              setState(() {
                _termsAccepted = value ?? false;
                _formData['termsAccepted'] = _termsAccepted;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Privacy Policy'),
            subtitle: const Text('I accept the privacy policy'),
            value: _privacyPolicyAccepted,
            onChanged: (value) {
              setState(() {
                _privacyPolicyAccepted = value ?? false;
                _formData['privacyPolicyAccepted'] = _privacyPolicyAccepted;
              });
            },
          ),
        ];
      
      default:
        return [
          TextField(
            controller: _accountTypeController,
            decoration: const InputDecoration(
              labelText: 'Account Type',
              hintText: 'demand-deposit, savings, time-deposit, investment-account',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _formData['accountType'] = value,
          ),
        ];
    }
  }

  Future<void> _ensureInfraInitialized() async {
    if (_shared != null && _storage != null && _network != null && _logger != null && _client != null && _dataService != null && _pollingManager != null) {
      return;
    }
    final config = _DummyConfig();
    if (!GetIt.I.isRegistered<HttpClientConfig>()) {
      GetIt.I.registerSingleton<HttpClientConfig>(config, signalsReady: true);
      GetIt.I.signalReady(config);
    }
    _shared = NeoSharedPrefs();
    await _shared!.init();
    _storage = NeoCoreSecureStorage(neoSharedPrefs: _shared!, httpClientConfig: config);
    await _storage!.init();
    _network = NeoNetworkManager(
      httpClientConfig: config,
      secureStorage: _storage!,
      neoSharedPrefs: _shared!,
      workflowClientId: 'demo-client',
      workflowClientSecret: 'demo-secret',
      logScale: NeoNetworkManagerLogScale.none,
    );
    await _network!.init(enableSslPinning: false);
    // Use a console logger for the sample page to ensure logs are visible
    _logger = _PrintLogger();
    await _logger!.init(enableLogging: true);
    // Register logger in GetIt so other services can access it
    if (!GetIt.I.isRegistered<NeoLogger>()) {
      GetIt.I.registerSingleton<NeoLogger>(_logger!, signalsReady: true);
      GetIt.I.signalReady(_logger!);
    }
    _client = VNextWorkflowClient(networkManager: _network!, logger: _logger!);
    _dataService = VNextDataService(client: _client!, logger: _logger!);
    _pollingManager = VNextLongPollingManager(networkManager: _network!, logger: _logger!);
  }

  Future<void> _start() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _status = 'Starting vNext workflow...';
      _componentJson = null;
    });

    await _ensureInfraInitialized();
    final NeoLogger logger = _logger!;
    try {
      // Sanity: check vNext endpoints exist in HttpClientConfig
      final hasInit = _network!.httpClientConfig.getServiceMethodByKey('vnext-init-workflow') != null;
      if (!hasInit) {
        logger.logConsole('[VNextSample] vNext endpoints are NOT registered in HttpClientConfig. initWorkflow call will fail.');
      } else {
        logger.logConsole('[VNextSample] vNext endpoints detected in HttpClientConfig. Proceeding with init.');
      }

      final client = _client!;
      final dataService = _dataService!;

      // 1) init workflow
      _domain = 'core';
      _workflowName = 'account-opening';
      logger.logConsole('[VNextSample] Calling initWorkflow...');
      final initResp = await client.initWorkflow(
        domain: _domain,
        workflowName: _workflowName,
        key: DateTime.now().millisecondsSinceEpoch.toString(),
        attributes: const {'channel': 'mobile'},
        version: '1.0.0',
      );
      if (initResp.isSuccess) {
        logger.logConsole('[VNextSample] Init SUCCESS: status=${initResp.asSuccess.statusCode}');
      } else {
        logger.logConsole('[VNextSample] Init ERROR: status=${initResp.asError.statusCode} desc=${initResp.asError.error.error.description}');
      }
      if (initResp.isError) {
        setState(() {
          _status = 'Init failed: ${initResp.asError.error.error.description}';
          _loading = false;
        });
        return;
      }

      final initData = initResp.asSuccess.data;
      logger.logConsole('[VNextSample] Init data keys: ${initData.keys.toList()}');
      final instanceId = (initData['instanceId'] as String?) ?? (initData['id'] as String?);
      if (instanceId == null || instanceId.isEmpty) {
        setState(() {
          _status = 'Init succeeded but no instanceId returned';
          _loading = false;
        });
        return;
      }
      setState(() {
        _status = 'Instance: $instanceId';
        _currentInstanceId = instanceId;
      });

      // 2) fetch instance to get extensions for hrefs
      logger.logConsole('[VNextSample] Fetching workflow instance...');
      final instResp = await client.getWorkflowInstance(
        domain: _domain,
        workflowName: _workflowName,
        instanceId: instanceId,
      );
      if (instResp.isSuccess) {
        logger.logConsole('[VNextSample] Instance SUCCESS: status=${instResp.asSuccess.statusCode}');
      } else {
        logger.logConsole('[VNextSample] Instance ERROR: status=${instResp.asError.statusCode} desc=${instResp.asError.error.error.description}');
      }
      if (instResp.isError) {
        setState(() {
          _status = 'Instance fetch failed: ${instResp.asError.error.error.description}';
          _loading = false;
        });
        return;
      }

      // 3) Create snapshot and load view via data service
      // Inject domain and workflowName into response data before parsing (backend doesn't return them)
      Map<String, dynamic> instanceData = instResp.asSuccess.data;
      if (_domain.isNotEmpty) {
        instanceData = {...instanceData, 'domain': _domain};
      }
      if (_workflowName.isNotEmpty) {
        instanceData = {...instanceData, 'flow': _workflowName};
      }
      final snapshot = VNextInstanceSnapshot.fromInstanceJson(instanceData);
      _workflowInstanceJson = instResp.asSuccess.data;
      _snapshot = snapshot;
      logger.logConsole('[VNextSample] Snapshot: instanceId=${snapshot.instanceId}, state=${snapshot.state}, status=${snapshot.status}, viewHref=${snapshot.viewHref}, dataHref=${snapshot.dataHref}, loadData=${snapshot.loadData}');
      
      // Check if we need to start/stop long polling based on status
      await _handleStatusChange(snapshot.status.code);
      
      logger.logConsole('[VNextSample] Loading view via data service...');
      final viewResp = await dataService.loadView(snapshot: snapshot);
      if (viewResp.isError) {
        setState(() {
          _status = 'View load failed: ${viewResp.asError.error.error.description}';
          _loading = false;
        });
        return;
      }

      final body = viewResp.asSuccess.data['body'] as Map<String, dynamic>?;
      logger.logConsole('[VNextSample] View loaded. ComponentJson keys: ${body?.keys.toList()}');
      setState(() {
        _componentJson = body;
        _status = 'View loaded (state=${snapshot.state})';
        _loading = false;
      });
    } catch (e, st) {
      logger.logError('[VNextSample] Exception: $e\n$st');
      setState(() {
        _status = 'Exception: $e';
        _loading = false;
      });
    }
  }

  Future<void> _fetchViewRaw() async {
    if (_snapshot?.viewHref == null) return;
    setState(() => _loading = true);
    try {
      final resp = await _client!.fetchByPath(href: _snapshot!.viewHref!);
      if (resp.isSuccess) {
        setState(() => _viewDataRaw = resp.asSuccess.data);
      } else {
        _logger?.logError('[VNextSample] Fetch view raw error: ${resp.asError.error.error.description}');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchInstanceDataRaw() async {
    if (_snapshot?.dataHref == null) return;
    setState(() => _loading = true);
    try {
      final resp = await _client!.fetchByPath(href: _snapshot!.dataHref!);
      if (resp.isSuccess) {
        setState(() => _instanceDataRaw = resp.asSuccess.data);
      } else {
        _logger?.logError('[VNextSample] Fetch data raw error: ${resp.asError.error.error.description}');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
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
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _start,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: const Text('Initialize Account Opening Workflow', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            
                            // Form inputs - dynamic based on workflow state
                            if (_snapshot != null) ...[
                              const SizedBox(height: 16),
                              const Text('Form Inputs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ..._buildFormFieldsForState(_snapshot!.state),
                              const SizedBox(height: 16),
                              
                              // Transition buttons integrated with form (like in the PR)
                              if (_snapshot!.transitions.isNotEmpty) ...[
                                const Text('Available Transitions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ...(_snapshot!.transitions.map((transition) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : () => _executeTransition(transition['name']!, transition['href']!),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(double.infinity, 40),
                                    ),
                                    child: Text('${transition['name']}'),
                                  ),
                                ))),
                              ],
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
                            const Text('Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(_status),
                            if (_currentInstanceId != null) ...[
                              const SizedBox(height: 8),
                              Text('Instance ID: $_currentInstanceId', style: const TextStyle(fontFamily: 'monospace')),
                            ],
                            if (_snapshot != null) ...[
                              const SizedBox(height: 8),
                              Text('Workflow Name: ${_snapshot!.workflowName}'),
                              Text('Current State: ${_snapshot!.state}'),
                              Text('Status: ${_snapshot!.status}'),
                              Text('Domain: ${_snapshot!.domain}'),
                              Text('Version: ${_snapshot!.flowVersion}'),
                            if ((_snapshot!.transitions).isNotEmpty)
                              Text('Available Transitions: ${_snapshot!.transitions.map((t) => t['name']).join(', ')}'),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Prefer live snapshot status; fall back to internal flag
                              Builder(builder: (context) {
                                final bool isActiveUi = _snapshot?.status.isBusy ?? _isLongPollingActive;
                                return Icon(
                                  isActiveUi ? Icons.sync : Icons.sync_disabled,
                                  color: isActiveUi ? Colors.green : Colors.grey,
                                  size: 16,
                                );
                              }),
                              const SizedBox(width: 4),
                              Builder(builder: (context) {
                                final bool isActiveUi = _snapshot?.status.isBusy ?? _isLongPollingActive;
                                return Text(
                                  isActiveUi ? 'Long Polling Active' : 'Long Polling Inactive',
                                  style: TextStyle(
                                    color: isActiveUi ? Colors.green : Colors.grey,
                                  ),
                                );
                              }),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isLongPollingActive ? _stopLongPolling : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(100, 32),
                                ),
                                child: const Text('Stop', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_snapshot != null)
                      _buildInfoCard('Workflow Instance (from Snapshot)', {
                        'Instance ID': _snapshot!.instanceId,
                        'Key': _snapshot!.key,
                        'Workflow Name': _snapshot!.workflowName,
                        'Domain': _snapshot!.domain,
                        'Version': _snapshot!.flowVersion,
                        'ETag': _snapshot!.etag,
                        'Current State': _snapshot!.state,
                        'Status': _snapshot!.status.code,
                        'Tags': _snapshot!.tags.isEmpty ? '(none)' : _snapshot!.tags.join(', '),
                        'Active Correlations': _snapshot!.activeCorrelations.isEmpty ? '(none)' : _snapshot!.activeCorrelations.join(', '),
                        'View Href': _snapshot!.viewHref ?? '(none)',
                        'Data Href': _snapshot!.dataHref ?? '(none)',
                        'Load Data': _snapshot!.loadData.toString(),
                      }),

                    const SizedBox(height: 16),

                    if (_workflowInstanceJson != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Workflow Data (Debug)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 300,
                                child: SingleChildScrollView(
                                  child: Text(
                                    const JsonEncoder.withIndent('  ').convert(_workflowInstanceJson),
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Right Panel - Data Views
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: _snapshot?.state != null ? Colors.green.shade50 : Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(_snapshot?.state != null ? Icons.play_circle_filled : Icons.help_outline,
                              color: _snapshot?.state != null ? Colors.green : Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (_snapshot?.state ?? 'NO ACTIVE STATE').replaceAll('-', ' ').toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _snapshot?.state != null ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_currentInstanceId != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loading || _snapshot?.viewHref == null ? null : _fetchViewRaw,
                            icon: const Icon(Icons.visibility),
                            label: const Text('Fetch View'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loading || _snapshot?.dataHref == null ? null : _fetchInstanceDataRaw,
                            icon: const Icon(Icons.data_object),
                            label: const Text('Fetch Data'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (_componentJson != null) ...[
                            _buildDataCard('Normalized View (renderer input)', _componentJson!),
                            const SizedBox(height: 16),
                          ],
                      
                          if (_instanceDataRaw != null) ...[
                            _buildDataCard('Raw Instance Data', _instanceDataRaw!),
                            const SizedBox(height: 16),
                          ],
                          if (_componentJson == null && _viewDataRaw == null && _instanceDataRaw == null)
                            Card(
                              color: Colors.grey.shade50,
                              child: const Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(Icons.launch, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('Initialize Workflow',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    SizedBox(height: 8),
                                    Text('Start the account opening workflow to enable data fetching.',
                                        style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
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

  void _refreshFormData() {
    _formData = {
      'accountType': _accountTypeController.text,
      'accountName': _accountNameController.text,
      'currency': _currencyController.text,
      'branchCode': _branchCodeController.text,
      'initialDeposit': double.tryParse(_initialDepositController.text) ?? 0,
      'accountPurpose': _accountPurposeController.text,
      'confirmed': _confirmed,
      'termsAccepted': _termsAccepted,
      'privacyPolicyAccepted': _privacyPolicyAccepted,
    };
  }

  /// Handle status changes to start/stop long polling as needed
  Future<void> _handleStatusChange(String status) async {
    _logger?.logConsole('[VNextSample] _handleStatusChange(status=$status, wasActive=$_isLongPollingActive)');
    
    if (status == 'B') {
      // Status 'B' means workflow is busy - start long polling
      if (_snapshot != null && !_isLongPollingActive) {
        _logger?.logConsole('[VNextSample] starting long polling for ${_snapshot!.instanceId}');
        await _startLongPolling(_snapshot!.instanceId);
        setState(() {
          _isLongPollingActive = true;
        });
      }
    } else {
      // Status 'A', 'C', 'E', 'S' means workflow is not busy - stop long polling
      _logger?.logConsole('[VNextSample] stopping long polling due to non-busy status');
      await _stopLongPolling();
      setState(() {
        _isLongPollingActive = false;
      });
    }
  }

  Future<void> _startLongPolling(String instanceId) async {
    
    if (_pollingManager == null || _snapshot == null) {
      return;
    }

    // Cancel any existing subscription
    await _pollingSubscription?.cancel();

    final String targetInstanceId = instanceId;

    // Listen to polling updates (workflow data) BEFORE starting, to not miss first message
    _pollingSubscription = _pollingManager!.messageStream.listen(
      (snapshot) async {
        if (snapshot.instanceId != targetInstanceId) {
          return; // ignore other instances
        }
        _logger?.logConsole('[VNextSample] onMessage instance=${snapshot.instanceId} state=${snapshot.state} status=${snapshot.status.code}');
        setState(() {
          _snapshot = snapshot;
          _status = 'Long polling: ${snapshot.status} - ${snapshot.state}';
          // Make the UI immediately reflect busy/non-busy even before stop events
          _isLongPollingActive = snapshot.status.isBusy;
        });

        // React to status changes coming from polling
        _logger?.logConsole('[VNextSample] onMessage -> _handleStatusChange(${snapshot.status.code})');
        await _handleStatusChange(snapshot.status.code);

        // When workflow becomes renderable (non-busy and has view), refresh the view
        if (snapshot.isRenderable) {
          _logger?.logConsole('[VNextSample] onMessage -> reloadForSnapshot(renderable=true)');
          await _reloadForSnapshot(snapshot);
        }
      },
      onError: (error) {
        setState(() {
          _status = 'Long polling error: $error';
        });
      },
    );

    // Listen to polling events (lifecycle events)
    _pollingEventSubscription = _pollingManager!.eventStream.listen(
      (event) async {
        if (event.instanceId != targetInstanceId) {
          return; // ignore other instances
        }
        _logger?.logConsole('[VNextSample] onEvent type=${event.type} reason=${event.reason}');
        
        switch (event.type) {
          case VNextPollingEventType.started:
            setState(() {
              _isLongPollingActive = true;
            });
            break;
          case VNextPollingEventType.stopped:
            setState(() {
              _isLongPollingActive = false;
            });
            // Ensure snapshot reflects the final state after polling stops
            // (in case the last message was missed due to timing)
            _logger?.logConsole('[VNextSample] onEvent.stopped -> _refreshInstance');
            await _refreshInstance();
            break;
          case VNextPollingEventType.error:
            setState(() {
              _isLongPollingActive = false;
              _status = 'Polling error: ${event.reason}';
            });
            break;
          case VNextPollingEventType.timeout:
            setState(() {
              _isLongPollingActive = false;
              _status = 'Polling timeout: ${event.reason}';
            });
            break;
        }
      },
      onError: (error) {
        setState(() {
          _isLongPollingActive = false;
          _status = 'Polling event error: $error';
        });
      },
    );

    // Start polling with extended config for testing AFTER listeners are attached
    // Use stored domain/workflowName instead of snapshot (backend doesn't return them)
    await _pollingManager!.startPolling(
      instanceId,
      domain: _domain,
      workflowName: _workflowName,
      config: VNextPollingConfig(
        interval: const Duration(seconds: 2), // Poll every 2 seconds
        duration: const Duration(minutes: 5), // Poll for up to 5 minutes
        requestTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<void> _reloadForSnapshot(VNextInstanceSnapshot snapshot) async {
    if (_dataService == null) return;
    if (_isRefreshingFromPolling) return;
    _isRefreshingFromPolling = true;
    try {
      _logger?.logConsole('[VNextSample] _reloadForSnapshot(state=${snapshot.state}, status=${snapshot.status.code})');
      final viewResp = await _dataService!.loadView(snapshot: snapshot);
      if (viewResp.isSuccess) {
        final body = viewResp.asSuccess.data['body'] as Map<String, dynamic>?;
        setState(() {
          _componentJson = body;
          _status = 'View refreshed (state=${snapshot.state})';
        });
        _logger?.logConsole('[VNextSample] _reloadForSnapshot DONE');
      } else {
        setState(() {
          _status = 'View refresh failed: ${viewResp.asError.error.error.description}';
        });
        _logger?.logConsole('[VNextSample] _reloadForSnapshot FAILED: ${viewResp.asError.error.error.description}');
      }
    } catch (e) {
      setState(() {
        _status = 'View refresh error: $e';
      });
      _logger?.logConsole('[VNextSample] _reloadForSnapshot ERROR: $e');
    } finally {
      _isRefreshingFromPolling = false;
    }
  }

  Future<void> _stopLongPolling() async {
    if (_pollingManager == null || _currentInstanceId == null) return;

    _logger?.logConsole('[VNextSample] _stopLongPolling(instanceId=$_currentInstanceId)');
    await _pollingManager!.stopPolling(_currentInstanceId!);
    await _pollingSubscription?.cancel();
    await _pollingEventSubscription?.cancel();
    _pollingSubscription = null;
    _pollingEventSubscription = null;
    
    setState(() {
      _isLongPollingActive = false;
    });
  }

  Map<String, dynamic> _buildPayloadForState(String state) {
    switch (state) {
      case 'account-type-selection':
        return {
          'accountType': _formData['accountType'] ?? 'demand-deposit',
        };
      
      case 'account-details-input':
        return {
          'accountName': _formData['accountName'] ?? 'John Doe',
          'currency': _formData['currency'] ?? 'TRY',
          'branchCode': _formData['branchCode'] ?? '1001',
          'initialDeposit': _formData['initialDeposit'] ?? 1000,
          'accountPurpose': _formData['accountPurpose'] ?? 'personal-banking',
        };
      
      case 'account-confirmation':
        return {
          'confirmed': _formData['confirmed'] ?? false,
          'termsAccepted': _formData['termsAccepted'] ?? false,
          'privacyPolicyAccepted': _formData['privacyPolicyAccepted'] ?? false,
        };
      
      default:
        return {
          'accountType': _formData['accountType'] ?? 'demand-deposit',
        };
    }
  }

  Future<void> _executeTransition(String transitionName, String transitionHref) async {
    if (_client == null || _currentInstanceId == null) return;

    setState(() {
      _loading = true;
      _status = 'Executing transition: $transitionName';
    });

    try {
      
      // Refresh form data from controllers to ensure we have latest values
      _refreshFormData();

      // Prepare payload based on current workflow state
      final payload = _buildPayloadForState(_snapshot!.state);


      // Execute the transition with properly structured payload
      // Use stored domain/workflowName instead of snapshot (backend doesn't return them)
      final response = await _client!.postTransition(
        domain: _domain,
        workflowName: _workflowName,
        instanceId: _currentInstanceId!,
        transitionKey: transitionName,
        data: payload,
      );


      if (response.isSuccess) {
        // Refresh the instance to get updated state
        await _refreshInstance();
        
        // Handle status change after transition
        if (_snapshot != null) {
          await _handleStatusChange(_snapshot!.status.code);
        }
        
        setState(() {
          _status = 'Transition executed successfully: $transitionName';
        });
      } else {
        setState(() {
          _status = 'Transition failed: ${response.asError.error.error.description}';
        });
      }
      } catch (e) {
      setState(() {
        _status = 'Transition error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _refreshInstance() async {
    if (_client == null || _currentInstanceId == null) return;

    try {
      _logger?.logConsole('[VNextSample] _refreshInstance(instanceId=$_currentInstanceId)');
      
      // Use stored domain/workflowName instead of snapshot (backend doesn't return them)
      final instResp = await _client!.getWorkflowInstance(
        domain: _domain,
        workflowName: _workflowName,
        instanceId: _currentInstanceId!,
      );
      
      if (instResp.isSuccess) {
        _workflowInstanceJson = instResp.asSuccess.data;
        // Inject domain and workflowName into response data before parsing (backend doesn't return them)
        Map<String, dynamic> instanceData = instResp.asSuccess.data;
        if (_domain.isNotEmpty) {
          instanceData = {...instanceData, 'domain': _domain};
        }
        if (_workflowName.isNotEmpty) {
          instanceData = {...instanceData, 'flow': _workflowName};
        }
        _snapshot = VNextInstanceSnapshot.fromInstanceJson(instanceData);
        _logger?.logConsole('[VNextSample] _refreshInstance SUCCESS: state=${_snapshot!.state} status=${_snapshot!.status.code}');
        
      } else {
        _logger?.logConsole('[VNextSample] _refreshInstance FAILED: ${instResp.asError.error.error.description}');
      }
      } catch (e) {
      _logger?.logConsole('[VNextSample] _refreshInstance ERROR: $e');
    }
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

class _PrintLogger extends NeoLogger {
  _PrintLogger()
      : super(
          neoAdjust: NeoAdjust(secureStorage: NeoCoreSecureStorage(neoSharedPrefs: NeoSharedPrefs(), httpClientConfig: _DummyConfig())),
          neoElastic: NeoElastic(neoNetworkManager: NeoNetworkManager(
            httpClientConfig: _DummyConfig(),
            secureStorage: NeoCoreSecureStorage(neoSharedPrefs: NeoSharedPrefs(), httpClientConfig: _DummyConfig()),
            neoSharedPrefs: NeoSharedPrefs(),
            workflowClientId: 'demo',
            workflowClientSecret: 'demo',
          ), secureStorage: NeoCoreSecureStorage(neoSharedPrefs: NeoSharedPrefs(), httpClientConfig: _DummyConfig())),
          httpClientConfig: _DummyConfig(),
        );

  @override
  Future<void> init({bool enableLogging = true}) async {}

  @override
  void logConsole(dynamic message, {Level logLevel = Level.info}) {
    // ignore: avoid_print
    print(message);
  }

  @override
  void logCustom(dynamic message, {Level logLevel = Level.info, List<NeoLoggerType> logTypes = NeoLogger.defaultAnalytics, Map<String, dynamic>? properties, Map<String, dynamic>? options}) {
    // ignore: avoid_print
    print(message);
  }

  @override
  void logError(String message, {Map<String, dynamic>? properties}) {
    // ignore: avoid_print
    print(message);
  }

  @override
  void logException(exception, StackTrace stackTrace, {Map<String, dynamic>? parameters}) {
    // ignore: avoid_print
    print('Exception: $exception');
  }
}

class _DummyConfig extends HttpClientConfig {
  _DummyConfig()
      : super(
          hosts: const [
            HttpHostDetails(
              key: 'vnext',
              workflowHubUrl: '',
              activeHosts: [HttpActiveHost(host: 'localhost:4201/api/v1', mtlsHost: '', retryCount: 0)],
            ),
          ],
          config: const HttpClientConfigParameters(cachePages: false, cacheStorage: false, logLevel: Level.info),
          services: const [
            // Use /instances/start for init
            HttpService(key: 'vnext-init-workflow', method: HttpMethod.post, host: 'vnext', name: '/{DOMAIN}/workflows/{WORKFLOW_NAME}/instances/start'),
            HttpService(key: 'vnext-post-transition', method: HttpMethod.patch, host: 'vnext', name: '/{DOMAIN}/workflows/{WORKFLOW_NAME}/instances/{INSTANCE_ID}/transitions/{TRANSITION_NAME}'),
            HttpService(key: 'vnext-get-available-transitions', method: HttpMethod.get, host: 'vnext', name: '/{DOMAIN}/workflows/{WORKFLOW_NAME}/instances/{INSTANCE_ID}/transitions'),
            HttpService(key: 'vnext-get-workflow-instance', method: HttpMethod.get, host: 'vnext', name: '/{DOMAIN}/workflows/{WORKFLOW_NAME}/instances/{INSTANCE_ID}/functions/state'),
            HttpService(key: 'vnext-list-workflow-instances', method: HttpMethod.get, host: 'vnext', name: '/{DOMAIN}/workflows/{WORKFLOW_NAME}/instances'),
            HttpService(key: 'vnext-get-instance-history', method: HttpMethod.get, host: 'vnext', name: '/{DOMAIN}/workflows/{WORKFLOW_NAME}/instances/{INSTANCE_ID}/history'),
            HttpService(key: 'vnext-get-system-health', method: HttpMethod.get, host: 'vnext', name: '/system/health'),
            HttpService(key: 'vnext-get-system-metrics', method: HttpMethod.get, host: 'vnext', name: '/system/metrics'),
            HttpService(key: 'vnext-fetch-by-path', method: HttpMethod.get, host: 'vnext', name: '/{PATH}'),
          ],
        );
}
