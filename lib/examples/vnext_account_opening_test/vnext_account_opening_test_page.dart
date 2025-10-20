import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:neo_core/core/analytics/neo_adjust.dart';
import 'package:neo_core/core/analytics/neo_elastic.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/analytics/neo_logger_type.dart';
import 'package:neo_core/core/network/managers/neo_network_manager.dart';
import 'package:neo_core/core/network/models/http_client_config.dart';
import 'package:neo_core/core/network/models/http_client_config_parameters.dart';
import 'package:neo_core/core/storage/neo_core_secure_storage.dart';
import 'package:neo_core/core/storage/neo_shared_prefs.dart';
import 'package:neo_core/core/workflow_form/vnext/models/vnext_instance_snapshot.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_data_service.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_client.dart';

class VNextAccountOpeningTestPage extends StatefulWidget {
  const VNextAccountOpeningTestPage({super.key});

  @override
  State<VNextAccountOpeningTestPage> createState() => _VNextAccountOpeningTestPageState();
}

class _VNextAccountOpeningTestPageState extends State<VNextAccountOpeningTestPage> {
  bool _loading = false;
  String _status = 'Idle';
  // Config UI
  final TextEditingController _baseUrlController = TextEditingController(text: 'http://localhost:4201');
  final TextEditingController _domainController = TextEditingController(text: 'core');
  // Loaded/normalized data
  Map<String, dynamic>? _componentJson;
  Map<String, dynamic>? _viewDataRaw;
  Map<String, dynamic>? _instanceDataRaw;
  Map<String, dynamic>? _workflowInstanceJson;
  String? _currentInstanceId;
  VNextInstanceSnapshot? _snapshot;
  NeoSharedPrefs? _shared;
  NeoCoreSecureStorage? _storage;
  NeoNetworkManager? _network;
  NeoLogger? _logger;
  VNextWorkflowClient? _client;
  VNextDataService? _dataService;

  Future<void> _ensureInfraInitialized() async {
    if (_shared != null && _storage != null && _network != null && _logger != null && _client != null) {
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
    debugPrint('[VNextSample] Initializing network manager...');
    await _network!.init(enableSslPinning: false);
    debugPrint('[VNextSample] Network manager initialized');
    _logger = NeoLogger(
      neoAdjust: NeoAdjust(secureStorage: _storage!),
      neoElastic: NeoElastic(neoNetworkManager: _network!, secureStorage: _storage!),
      httpClientConfig: config,
    );
    await _logger!.init(enableLogging: true);
    _client = VNextWorkflowClient(networkManager: _network!, logger: _logger!);
    _dataService = VNextDataService(client: _client!, logger: _logger!);
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
      logger.logConsole('[VNextSample] Calling initWorkflow...');
      final initResp = await client.initWorkflow(
        domain: 'core',
        workflowName: 'account-opening',
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
        domain: 'core',
        workflowName: 'account-opening',
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
      final snapshot = VNextInstanceSnapshot.fromInstanceJson(instResp.asSuccess.data);
      _workflowInstanceJson = instResp.asSuccess.data;
      _snapshot = snapshot;
      logger.logConsole('[VNextSample] Snapshot: instanceId=${snapshot.instanceId}, state=${snapshot.state}, status=${snapshot.status}, viewHref=${snapshot.viewHref}, dataHref=${snapshot.dataHref}, loadData=${snapshot.loadData}');
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
                            const SizedBox(height: 8),
                            const Text('// TODO: Wire baseUrl/domain to HttpClientConfig vNext host'),
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
                            const SizedBox(height: 8),
                            const Text('// TODO: Add transition buttons wired to WorkflowFlutterBridge when available'),
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
                              Text('Current State: ${_snapshot!.state}'),
                              Text('Status: ${_snapshot!.status}'),
                              if ((_snapshot!.transitions).isNotEmpty)
                                Text('Available Transitions: ${_snapshot!.transitions.join(', ')}'),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_workflowInstanceJson != null)
                      _buildInfoCard('Workflow Instance', {
                        'Instance ID': _workflowInstanceJson!['id']?.toString() ?? 'Unknown',
                        'Flow': _workflowInstanceJson!['flow']?.toString() ?? 'Unknown',
                        'Domain': _workflowInstanceJson!['domain']?.toString() ?? 'Unknown',
                        'Version': _workflowInstanceJson!['flowVersion']?.toString() ?? 'Unknown',
                        'Current State': _snapshot?.state ?? 'Unknown',
                        'Status': _snapshot?.status ?? 'Unknown',
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
                          if (_viewDataRaw != null) ...[
                            _buildDataCard('Raw View Data', _viewDataRaw!),
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
                          const SizedBox(height: 8),
                          const Text('// TODO: Wire WorkflowRouter + WorkflowFlutterBridge for full PR parity'),
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
  void logError(String message) {
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
          hosts: const [],
          config: const HttpClientConfigParameters(cachePages: false, cacheStorage: false, logLevel: Level.info),
          services: const [],
        );
}


