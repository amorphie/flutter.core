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

class VNextScheduledPaymentsTestPage extends StatefulWidget {
  const VNextScheduledPaymentsTestPage({super.key});

  @override
  State<VNextScheduledPaymentsTestPage> createState() => _VNextScheduledPaymentsTestPageState();
}

class _VNextScheduledPaymentsTestPageState extends State<VNextScheduledPaymentsTestPage> {
  bool _loading = false;
  String _status = 'Idle';
  bool _isLongPollingActive = false;
  // Config UI
  final TextEditingController _baseUrlController = TextEditingController(text: 'http://localhost:4201');
  final TextEditingController _domainController = TextEditingController(text: 'core');
  // Store domain and workflowName separately (backend doesn't return them in snapshot)
  String _domain = 'core';
  String _workflowName = 'scheduled-payments';
  // Loaded/normalized data
  Map<String, dynamic>? _componentJson;
  Map<String, dynamic>? _viewDataRaw;
  Map<String, dynamic>? _instanceDataRaw;
  Map<String, dynamic>? _workflowInstanceJson;
  Map<String, dynamic>? _functionResponseData; // Store function call response
  String? _currentInstanceId;
  VNextInstanceSnapshot? _snapshot;
  Map<String, dynamic> _formData = {};
  // Form controllers for payment configuration
  late final TextEditingController _userIdController;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _frequencyController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _paymentMethodIdController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _recipientIdController;
  late final TextEditingController _maxRetriesController;
  
  // Boolean values
  bool _isAutoRetry = true;
  
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
    _userIdController = TextEditingController(text: '123');
    _amountController = TextEditingController(text: '100.00');
    _currencyController = TextEditingController(text: 'USD');
    _frequencyController = TextEditingController(text: 'monthly');
    // Use full ISO 8601 date-time format in UTC (not just date)
    _startDateController = TextEditingController(text: DateTime.now().toUtc().toIso8601String());
    _endDateController = TextEditingController(text: DateTime.now().add(const Duration(days: 365)).toUtc().toIso8601String());
    _paymentMethodIdController = TextEditingController(text: 'payment-method-1');
    _descriptionController = TextEditingController(text: 'Monthly subscription payment');
    _recipientIdController = TextEditingController(text: 'recipient-123');
    _maxRetriesController = TextEditingController(text: '3');
    
    // Initialize form data with default values
    _formData = {
      'userId': 123, // userId must be an integer
      'amount': 100.00,
      'currency': 'USD',
      'frequency': 'monthly',
      'startDate': DateTime.now().toUtc().toIso8601String(), // Full ISO 8601 date-time format in UTC
      'endDate': DateTime.now().add(const Duration(days: 365)).toUtc().toIso8601String(), // Full ISO 8601 date-time format in UTC
      'paymentMethodId': 'payment-method-1',
      'description': 'Monthly subscription payment',
      'recipientId': 'recipient-123',
      'isAutoRetry': true,
      'maxRetries': 3,
    };
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _frequencyController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _paymentMethodIdController.dispose();
    _descriptionController.dispose();
    _recipientIdController.dispose();
    _maxRetriesController.dispose();
    _pollingSubscription?.cancel();
    _pollingEventSubscription?.cancel();
    _pollingManager?.stopAllPolling();
    super.dispose();
  }

  List<Widget> _buildFormFieldsForState(String state) {
    switch (state) {
      case 'payment-configuration':
        return [
          TextField(
            controller: _userIdController,
            decoration: const InputDecoration(
              labelText: 'User ID',
              hintText: 'Enter user ID (integer)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _formData['userId'] = int.tryParse(value) ?? 123,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              hintText: 'Enter payment amount',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _formData['amount'] = double.tryParse(value) ?? 0.0,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _currencyController,
            decoration: const InputDecoration(
              labelText: 'Currency',
              hintText: 'USD, EUR, TRY, etc.',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _formData['currency'] = value,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _frequencyController,
            decoration: const InputDecoration(
              labelText: 'Frequency',
              hintText: 'monthly, weekly, daily, yearly',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _formData['frequency'] = value,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _startDateController,
            decoration: const InputDecoration(
              labelText: 'Start Date (ISO 8601 date-time)',
              hintText: '2024-01-01T00:00:00Z',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // Try to parse as date-time, if fails try to convert date-only to date-time
              if (value.isNotEmpty) {
                try {
                  DateTime dateTime;
                  // If it's just a date (YYYY-MM-DD), convert to date-time
                  if (value.length == 10 && value.contains('-')) {
                    dateTime = DateTime.parse(value);
                  } else {
                    // Try parsing as full date-time
                    dateTime = DateTime.parse(value);
                  }
                  // Convert to UTC and format as ISO 8601
                  _formData['startDate'] = dateTime.toUtc().toIso8601String();
                } catch (e) {
                  // If parsing fails, use the value as-is (will be validated by backend)
                  _formData['startDate'] = value;
                }
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _endDateController,
            decoration: const InputDecoration(
              labelText: 'End Date (ISO 8601 date-time)',
              hintText: '2025-01-01T00:00:00Z',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // Try to parse as date-time, if fails try to convert date-only to date-time
              if (value.isNotEmpty) {
                try {
                  DateTime dateTime;
                  // If it's just a date (YYYY-MM-DD), convert to date-time
                  if (value.length == 10 && value.contains('-')) {
                    dateTime = DateTime.parse(value);
                  } else {
                    // Try parsing as full date-time
                    dateTime = DateTime.parse(value);
                  }
                  // Convert to UTC and format as ISO 8601
                  _formData['endDate'] = dateTime.toUtc().toIso8601String();
                } catch (e) {
                  // If parsing fails, use the value as-is (will be validated by backend)
                  _formData['endDate'] = value;
                }
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paymentMethodIdController,
            decoration: const InputDecoration(
              labelText: 'Payment Method ID',
              hintText: 'Enter payment method ID',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _formData['paymentMethodId'] = value,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter payment description',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _formData['description'] = value,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _recipientIdController,
            decoration: const InputDecoration(
              labelText: 'Recipient ID',
              hintText: 'Enter recipient ID',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _formData['recipientId'] = value,
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('Auto Retry'),
            subtitle: const Text('Enable automatic retry on failure'),
            value: _isAutoRetry,
            onChanged: (value) {
              setState(() {
                _isAutoRetry = value ?? true;
                _formData['isAutoRetry'] = _isAutoRetry;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxRetriesController,
            decoration: const InputDecoration(
              labelText: 'Max Retries',
              hintText: 'Maximum number of retry attempts',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _formData['maxRetries'] = int.tryParse(value) ?? 3,
          ),
        ];
      
      case 'payment-deactive':
        return [
          const Text(
            'Payment is deactivated. You can reactivate, update, or delete it.',
            style: TextStyle(fontSize: 14),
          ),
        ];
      
      default:
        return [
          const Text(
            'No form fields available for this state.',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
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

      // 1) Refresh form data to ensure we have latest values
      _refreshFormData();

      // 2) init workflow with required payment configuration fields
      _domain = 'core';
      _workflowName = 'scheduled-payments';
      logger.logConsole('[VNextSample] Calling initWorkflow...');
      final initResp = await client.initWorkflow(
        domain: _domain,
        workflowName: _workflowName,
        key: DateTime.now().millisecondsSinceEpoch.toString(),
        attributes: {
          'userId': _formData['userId'] as int, // userId must be an integer
          'amount': _formData['amount'] as double,
          'currency': _formData['currency'] as String,
          'frequency': _formData['frequency'] as String,
          'startDate': _formData['startDate'] as String, // ISO 8601 date-time format
          'endDate': _formData['endDate'] as String, // ISO 8601 date-time format
          'paymentMethodId': _formData['paymentMethodId'] as String,
          'recipientId': _formData['recipientId'] as String,
          // Optional fields
          if (_formData['description'] != null && (_formData['description'] as String).isNotEmpty) 
            'description': _formData['description'] as String,
          if (_formData['isAutoRetry'] != null) 'isAutoRetry': _formData['isAutoRetry'] as bool,
          if (_formData['maxRetries'] != null) 'maxRetries': _formData['maxRetries'] as int,
        },
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

  Future<void> _callGetUserInfoFunction() async {
    if (_client == null || _currentInstanceId == null) {
      setState(() {
        _status = 'Workflow not started yet';
      });
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Calling function-get-user-info function...';
    });

    try {
      // Call the function via the workflow instance
      // The function endpoint is: /{domain}/workflows/{workflow}/instances/{instance}/functions/{function}
      final functionUrl = '/${_domain}/workflows/${_workflowName}/instances/$_currentInstanceId/functions/function-get-user-info';
      
      _logger?.logConsole('[VNextSample] Calling function: $functionUrl');
      
      // Use the client's fetchByPath method
      final response = await _client!.fetchByPath(href: functionUrl);

      if (response.isSuccess) {
        final responseData = response.asSuccess.data as Map<String, dynamic>?;
        _logger?.logConsole('[VNextSample] Function response: ${jsonEncode(responseData)}');
        
        setState(() {
          _functionResponseData = responseData;
          _status = 'Function called successfully';
          _loading = false;
        });
      } else {
        setState(() {
          _status = 'Function call failed: ${response.asError.error.error.description}';
          _loading = false;
        });
        _logger?.logError('[VNextSample] Function call failed: ${response.asError.error.error.description}');
      }
    } catch (e) {
      _logger?.logConsole('[VNextSample] Exception during function call: $e');
      setState(() {
        _status = 'Error calling function: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('vNext Scheduled Payments Test'),
        backgroundColor: Colors.blue,
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
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                child: const Text('Initialize Scheduled Payments Workflow', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            
                            // Function call button
                            if (_currentInstanceId != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _loading ? null : _callGetUserInfoFunction,
                                  icon: const Icon(Icons.functions),
                                  label: const Text('Call function-get-user-info', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            
                            // Form inputs - dynamic based on workflow state
                            if (_snapshot != null) ...[
                              const SizedBox(height: 16),
                              const Text('Form Inputs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ..._buildFormFieldsForState(_snapshot!.state),
                              const SizedBox(height: 16),
                              
                              // Transition buttons integrated with form
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
                    color: _snapshot?.state != null ? Colors.blue.shade50 : Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(_snapshot?.state != null ? Icons.payment : Icons.help_outline,
                              color: _snapshot?.state != null ? Colors.blue : Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (_snapshot?.state ?? 'NO ACTIVE STATE').replaceAll('-', ' ').toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _snapshot?.state != null ? Colors.blue.shade700 : Colors.grey.shade600,
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
                          
                          if (_functionResponseData != null) ...[
                            _buildDataCard('Function Response (function-get-user-info)', _functionResponseData!),
                            const SizedBox(height: 16),
                          ],
                          
                          if (_componentJson == null && _viewDataRaw == null && _instanceDataRaw == null && _functionResponseData == null)
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
                                    Text('Start the scheduled payments workflow to enable data fetching.',
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
    // Helper function to convert date string to ISO 8601 date-time format (UTC)
    String _ensureDateTimeFormat(String dateStr) {
      if (dateStr.isEmpty) return dateStr;
      try {
        DateTime dateTime;
        // If it's just a date (YYYY-MM-DD), convert to date-time at midnight UTC
        if (dateStr.length == 10 && dateStr.contains('-')) {
          dateTime = DateTime.parse(dateStr);
        } else {
          // Try parsing as full date-time
          dateTime = DateTime.parse(dateStr);
        }
        // Convert to UTC and format as ISO 8601 with 'Z' suffix
        final utcDateTime = dateTime.toUtc();
        // Format: YYYY-MM-DDTHH:mm:ss.sssZ
        return utcDateTime.toIso8601String();
      } catch (e) {
        // If parsing fails, return as-is (will be validated by backend)
        return dateStr;
      }
    }

    _formData = {
      'userId': int.tryParse(_userIdController.text) ?? 123, // userId must be an integer
      'amount': double.tryParse(_amountController.text) ?? 0.0,
      'currency': _currencyController.text,
      'frequency': _frequencyController.text,
      'startDate': _ensureDateTimeFormat(_startDateController.text),
      'endDate': _ensureDateTimeFormat(_endDateController.text),
      'paymentMethodId': _paymentMethodIdController.text,
      'description': _descriptionController.text,
      'recipientId': _recipientIdController.text,
      'isAutoRetry': _isAutoRetry,
      'maxRetries': int.tryParse(_maxRetriesController.text) ?? 3,
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
            // After refreshing instance, reload view/data if snapshot is renderable
            if (_snapshot != null && _snapshot!.isRenderable) {
              _logger?.logConsole('[VNextSample] onEvent.stopped -> reloadForSnapshot(renderable=true)');
              await _reloadForSnapshot(_snapshot!);
            }
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
      case 'payment-configuration':
        return {
          'userId': _formData['userId'] ?? 123, // userId must be an integer
          'amount': _formData['amount'] ?? 100.00,
          'currency': _formData['currency'] ?? 'USD',
          'frequency': _formData['frequency'] ?? 'monthly',
          'startDate': _formData['startDate'] ?? DateTime.now().toUtc().toIso8601String(), // ISO 8601 date-time format in UTC
          'endDate': _formData['endDate'] ?? DateTime.now().add(const Duration(days: 365)).toUtc().toIso8601String(), // ISO 8601 date-time format in UTC
          'paymentMethodId': _formData['paymentMethodId'] ?? 'payment-method-1',
          'description': _formData['description'] ?? 'Monthly subscription payment',
          'recipientId': _formData['recipientId'] ?? 'recipient-123',
          'isAutoRetry': _formData['isAutoRetry'] ?? true,
          'maxRetries': _formData['maxRetries'] ?? 3,
        };
      
      case 'payment-deactive':
        // For deactive state, transitions might need different payloads
        // For now, return empty payload for manual transitions
        return {};
      
      default:
        return {};
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
          
          // After handling status change, reload view/data if snapshot is renderable
          // (This handles the case where long polling stops immediately after transition)
          if (_snapshot!.isRenderable) {
            _logger?.logConsole('[VNextSample] _executeTransition -> reloadForSnapshot(renderable=true)');
            await _reloadForSnapshot(_snapshot!);
          }
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

