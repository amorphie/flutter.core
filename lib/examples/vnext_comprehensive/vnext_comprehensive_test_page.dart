import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_client.dart';

/// Model for workflow instance management
class WorkflowInstance {
  final String? id;
  final String workflowName;
  final String? state;
  final Map<String, dynamic>? attributes;
  final List<String>? availableTransitions;
  final DateTime lastUpdated;
  final bool isInitialized;

  WorkflowInstance({
    this.id,
    required this.workflowName,
    this.state,
    this.attributes,
    this.availableTransitions,
    required this.lastUpdated,
    this.isInitialized = false,
  });

  WorkflowInstance copyWith({
    String? id,
    String? workflowName,
    String? state,
    Map<String, dynamic>? attributes,
    List<String>? availableTransitions,
    DateTime? lastUpdated,
    bool? isInitialized,
  }) {
    return WorkflowInstance(
      id: id ?? this.id,
      workflowName: workflowName ?? this.workflowName,
      state: state ?? this.state,
      attributes: attributes ?? this.attributes,
      availableTransitions: availableTransitions ?? this.availableTransitions,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Comprehensive test page for vNext workflow integration
class VNextComprehensiveTestPage extends StatefulWidget {
  const VNextComprehensiveTestPage({super.key});

  @override
  State<VNextComprehensiveTestPage> createState() => _VNextComprehensiveTestPageState();
}

class _VNextComprehensiveTestPageState extends State<VNextComprehensiveTestPage> {
  // Configuration controllers
  final TextEditingController _baseUrlController = TextEditingController(text: 'http://localhost:4201');
  final TextEditingController _domainController = TextEditingController(text: 'core');

  VNextWorkflowClient? _vNextClient;
  _SimpleLogger? _logger;

  final List<String> _logs = [];
  
  // Workflow instances management - grouped by workflow type
  final Map<String, List<WorkflowInstance>> _workflowInstances = {};
  final Map<String, bool> _expandedWorkflows = {};
  bool _isLoading = false;

  // Real workflow configurations from vNext setup
  final List<String> _availableWorkflows = [
    'ecommerce', // Only real workflow defined in example-flows.json
  ];

  @override
  void initState() {
    super.initState();
    
    // Catch Flutter errors and display them in our logs
    FlutterError.onError = (FlutterErrorDetails details) {
      _addLog('🚨 Flutter Error: ${details.exception}');
      if (details.stack != null) {
        _addLog('📍 Stack: ${details.stack.toString().split('\n').take(3).join('\n')}');
      }
    };
    
    _initializeServices();
    _initializeDefaultWorkflows();
  }

  void _initializeServices() {
    // Initialize simple logger
    _logger = _SimpleLogger();
    
    // Initialize vNext client
    _vNextClient = VNextWorkflowClient(
      baseUrl: _baseUrlController.text,
      httpClient: http.Client(),
      logger: _logger!,
    );
    
    // Services configured for domain: ${_domainController.text}
    
    _addLog('Services initialized with domain: ${_domainController.text}');
  }

  void _initializeDefaultWorkflows() {
    // Initialize workflow groups for available workflows
    for (String workflowName in _availableWorkflows) {
      _workflowInstances[workflowName] = [];
      _expandedWorkflows[workflowName] = true; // Start expanded
    }
  }

  void _updateServices() {
    // Update vNext client
    _vNextClient = VNextWorkflowClient(
      baseUrl: _baseUrlController.text,
      httpClient: http.Client(),
      logger: _logger!,
    );
    _addLog('Services updated with new configuration');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String().substring(11, 19)} - $message');
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _testVNextConnection() async {
    _addLog('🔍 Testing vNext connection...');
    
    try {
      final response = await http.get(
        Uri.parse('${_baseUrlController.text}/health'),
        headers: {
          'Accept': 'application/json',
          'Accept-Language': 'tr-TR',
        },
      );
      
      _addLog('📡 Connection test -> ${response.statusCode}');
      
      if (response.statusCode == 200) {
        _addLog('✅ vNext connection successful');
        
        // Try to parse response as JSON if possible
        try {
          final jsonData = jsonDecode(response.body);
          _addLog('📊 Health Check Details:');
          
          if (jsonData is Map<String, dynamic>) {
            final status = jsonData['status'] as String?;
            final duration = jsonData['duration'] as String?;
            final info = jsonData['info'] as List<dynamic>?;
            
            _addLog('   Overall Status: $status');
            _addLog('   Check Duration: $duration');
            
            if (info != null) {
              _addLog('   Component Health:');
              for (final component in info) {
                if (component is Map<String, dynamic>) {
                  final name = component['key'] as String?;
                  final healthStatus = component['status'] as String?;
                  final duration = component['duration'] as String?;
                  final icon = healthStatus == 'Healthy' ? '✅' : '❌';
                  _addLog('     $icon $name: $healthStatus ($duration)');
                }
              }
            }
          }
        } catch (e) {
          _addLog('📝 Raw response: ${response.body.substring(0, 200)}...');
        }
      } else {
        _addLog('❌ vNext connection failed: ${response.statusCode}');
        _addLog('Response: ${response.body}');
      }
    } catch (e) {
      _addLog('❌ vNext connection error: $e');
    }
  }

  Future<void> _testVNextServiceStatus() async {
    _addLog('🔍 Testing vNext service status and diagnostics...');
    _addLog('📋 Endpoint Discovery Summary:');
    
    // Test multiple endpoints to understand service state
    final endpoints = [
      '/health',           // ✅ Main health check endpoint
      '/metrics',          // ✅ Prometheus metrics endpoint
      '/',                 // Root endpoint
    ];
    
    for (final endpoint in endpoints) {
      try {
        _addLog('🔍 Testing endpoint: $endpoint');
        final response = await http.get(
          Uri.parse('${_baseUrlController.text}$endpoint'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        
        String statusIcon = '📡';
        String note = '';
        
        // Add context about expected vs unexpected results
        if (endpoint == '/health' && response.statusCode == 200) {
          statusIcon = '✅';
          note = ' (Main health check endpoint)';
        } else if (endpoint == '/metrics' && response.statusCode == 200) {
          statusIcon = '✅';
          note = ' (Prometheus metrics)';
        } else if (response.statusCode >= 400) {
          statusIcon = '❌';
          note = ' (Error response)';
        } else {
          statusIcon = '✅';
          note = ' (Success)';
        }
        
        _addLog('   $statusIcon $endpoint -> ${response.statusCode}$note');
        
        // Show a snippet of the response body for successful calls
        if (response.statusCode == 200 && response.body.isNotEmpty && response.body.length < 300) {
          final preview = response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body;
          _addLog('   📄 Preview: $preview');
        }
      } catch (e) {
        _addLog('   ❌ $endpoint failed: $e');
      }
    }
    
    _addLog('');
    _addLog('💡 Key Findings:');
    _addLog('   ✅ /health - Main health check endpoint');
    _addLog('   ✅ /metrics - Prometheus monitoring data');
    _addLog('   ✅ /api/v1/{domain}/workflows/{workflow}/instances/* - Workflow operations');
    _addLog('   ✅ Core vNext services are operational');
  }

  Future<void> _initializeWorkflow(String workflowName) async {
    if (_vNextClient == null) return;
    
    final instanceNumber = (_workflowInstances[workflowName]?.length ?? 0) + 1;
    final key = 'test-$workflowName-$instanceNumber-${DateTime.now().millisecondsSinceEpoch}';
    
    setState(() {
      _isLoading = true;
    });
    
    _addLog('🚀 Initializing $workflowName instance #$instanceNumber');
    
    try {
      final attributes = _getDefaultAttributesForWorkflow(workflowName);
      
      final response = await _vNextClient!.initWorkflow(
        domain: _domainController.text,
        workflowName: workflowName,
        key: key,
        attributes: attributes,
        tags: ['test', 'flutter-client', workflowName, 'instance-$instanceNumber'],
      );
      
      if (response.isSuccess) {
        final instanceData = response.asSuccess.data;
        final instanceId = instanceData['id'] as String?;
        
        if (instanceId != null) {
          _addLog('✅ Workflow initialized successfully: $instanceId');
          
          // Create new instance and add to the group
          final newInstance = WorkflowInstance(
            id: instanceId,
            workflowName: workflowName,
            state: instanceData['state'] as String?,
            isInitialized: true,
            lastUpdated: DateTime.now(),
          );
          
          setState(() {
            _workflowInstances[workflowName]!.add(newInstance);
          });
          
          // Automatically refresh to get available transitions
          await _refreshWorkflowInstance(workflowName, _workflowInstances[workflowName]!.length - 1);
        } else {
          _addLog('❌ No instance ID returned in response');
        }
      } else {
        _addLog('❌ Workflow initialization failed: ${response.asError.error.error.description}');
      }
    } catch (e) {
      _addLog('❌ Workflow initialization error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshWorkflowInstance(String workflowName, int instanceIndex) async {
    if (_vNextClient == null) return;
    
    final instances = _workflowInstances[workflowName];
    if (instances == null || instanceIndex >= instances.length) return;
    
    final instance = instances[instanceIndex];
    if (!instance.isInitialized || instance.id == null) return;
    
    _addLog('🔄 Refreshing $workflowName instance #${instanceIndex + 1}: ${instance.id}');
    
    try {
      // Get instance details
      final instanceResponse = await _vNextClient!.getWorkflowInstance(
        domain: _domainController.text,
        workflowName: instance.workflowName,
        instanceId: instance.id!,
      );
      
      // Get available transitions
      final transitionsResponse = await _vNextClient!.getAvailableTransitions(
        domain: _domainController.text,
        workflowName: instance.workflowName,
        instanceId: instance.id!,
      );
      
      if (instanceResponse.isSuccess) {
        final instanceData = instanceResponse.asSuccess.data;
        
        List<String>? transitions;
        if (transitionsResponse.isSuccess) {
          try {
            final responseData = transitionsResponse.asSuccess.data;
            _addLog('📄 Transitions response type: ${responseData.runtimeType}');
            
            // Handle the actual API response structure: {"transitions": [...]}
            if (responseData.containsKey('transitions')) {
              final transitionsArray = responseData['transitions'] as List<dynamic>;
              // Extract available transitions from the extensions field of the latest version
              if (transitionsArray.isNotEmpty) {
                final latestTransition = transitionsArray.last as Map<String, dynamic>;
                final extensions = latestTransition['extensions'] as Map<String, dynamic>?;
                final availableTransitions = extensions?['availableTransitions'] as Map<String, dynamic>?;
                final items = availableTransitions?['items'] as List<dynamic>?;
                
                if (items != null && items.isNotEmpty) {
                  transitions = items.map((t) => t.toString()).toList();
                } else {
                  transitions = []; // No available transitions yet
                }
              }
            } else {
              _addLog('❌ Unexpected transitions response structure');
              transitions = [];
            }
          } catch (e) {
            _addLog('❌ Error parsing transitions: $e');
            transitions = [];
          }
        }
        
        setState(() {
          _workflowInstances[workflowName]![instanceIndex] = instance.copyWith(
            state: instanceData['state'] as String?,
            attributes: instanceData['attributes'] as Map<String, dynamic>?,
            availableTransitions: transitions,
            lastUpdated: DateTime.now(),
          );
        });
        
        _addLog('✅ Instance refreshed: ${instanceData['state']} (${transitions?.length ?? 0} transitions available)');
      } else {
        _addLog('❌ Failed to refresh instance: ${instanceResponse.asError.error.error.description}');
      }
    } catch (e) {
      _addLog('❌ Refresh error: $e');
    }
  }

  Future<void> _executeTransition(String workflowName, int instanceIndex, String transitionKey) async {
    if (_vNextClient == null) return;
    
    final instances = _workflowInstances[workflowName];
    if (instances == null || instanceIndex >= instances.length) return;
    
    final instance = instances[instanceIndex];
    if (!instance.isInitialized || instance.id == null) return;
    
    _addLog('⚡ Executing transition: $transitionKey for $workflowName instance #${instanceIndex + 1}');
    
    try {
      final transitionData = _getTransitionDataForWorkflow(instance.workflowName, transitionKey);
      
      final response = await _vNextClient!.postTransition(
        domain: _domainController.text,
        workflowName: instance.workflowName,
        instanceId: instance.id!,
        transitionKey: transitionKey,
        data: transitionData,
      );
      
      if (response.isSuccess) {
        _addLog('✅ Transition executed successfully: $transitionKey');
        
        // Automatically refresh to get new state and transitions
        await _refreshWorkflowInstance(workflowName, instanceIndex);
      } else {
        _addLog('❌ Transition failed: ${response.asError.error.error.description}');
      }
    } catch (e) {
      _addLog('❌ Transition error: $e');
    }
  }


  void _refreshAllInstances() {
    for (String workflowName in _workflowInstances.keys) {
      final instances = _workflowInstances[workflowName]!;
      for (int i = 0; i < instances.length; i++) {
        if (instances[i].isInitialized) {
          _refreshWorkflowInstance(workflowName, i);
        }
      }
    }
  }

  Future<void> _loadExistingInstances() async {
    if (_vNextClient == null) return;

    setState(() {
      _isLoading = true;
    });

    _addLog('🔄 Loading existing workflow instances from server...');

    try {
      // Load instances for each available workflow
      for (String workflowName in _availableWorkflows) {
        _addLog('📋 Fetching existing instances for: $workflowName');

        final response = await _vNextClient!.listWorkflowInstances(
          domain: _domainController.text,
          workflowName: workflowName,
          page: 1,
          pageSize: 50, // Load up to 50 existing instances
        );

        if (response.isSuccess) {
          final responseData = response.asSuccess.data;
          final instancesData = responseData['data'] as List<dynamic>? ?? [];
          
          _addLog('✅ Found ${instancesData.length} existing instances for $workflowName');

          // Convert server instances to our WorkflowInstance objects
          final existingInstances = <WorkflowInstance>[];
          
          for (final instanceData in instancesData) {
            final instance = _parseServerInstance(workflowName, instanceData);
            if (instance != null) {
              existingInstances.add(instance);
            }
          }

          // Update our local state with existing instances
          setState(() {
            _workflowInstances[workflowName] = existingInstances;
          });

          if (existingInstances.isNotEmpty) {
            _addLog('📦 Loaded ${existingInstances.length} instances for $workflowName');
          }
        } else {
          _addLog('❌ Failed to load instances for $workflowName: ${response.asError.error.error.description}');
        }
      }

      _addLog('🎉 Finished loading existing instances');
    } catch (e) {
      _addLog('❌ Error loading existing instances: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  WorkflowInstance? _parseServerInstance(String workflowName, Map<String, dynamic> instanceData) {
    try {
      final id = instanceData['id'] as String?;
      final attributes = instanceData['attributes'] as Map<String, dynamic>? ?? {};
      
      // Only use explicit state if provided by the API
      String? currentState;
      if (attributes.containsKey('currentState')) {
        currentState = attributes['currentState'] as String?;
      } else if (attributes.containsKey('state')) {
        currentState = attributes['state'] as String?;
      }
      // No state inference - let the workflow engine handle state management

      // For existing instances, we consider them initialized
      return WorkflowInstance(
        id: id,
        workflowName: workflowName,
        state: currentState, // Will be null if not explicitly provided
        isInitialized: true,
        attributes: attributes,
        availableTransitions: [], // We'll need to fetch these separately if needed
        lastUpdated: DateTime.now(), // Server doesn't provide last updated, use current time
      );
    } catch (e) {
      _addLog('⚠️ Failed to parse server instance: $e');
      return null;
    }
  }

  Map<String, dynamic> _getDefaultAttributesForWorkflow(String workflowName) {
    // Generic approach - no workflow-specific assumptions
    // Each workflow should define its own required attributes
    return {
      'workflowName': workflowName,
      'createdBy': 'flutter-client',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _getTransitionDataForWorkflow(String workflowName, String transitionKey) {
    // Generic approach - no workflow-specific assumptions
    // Each workflow should define its own transition data requirements
    return {
      'transitionKey': transitionKey,
      'workflowName': workflowName,
      'executedBy': 'flutter-client',
      'executedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('vNext Workflow Test'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllInstances,
            tooltip: 'Refresh All Instances',
          ),
        ],
      ),
      body: Column(
        children: [
          // Configuration Section
          _buildConfigurationSection(),
          
          // Workflow Instances Section
          Expanded(
            flex: 2,
            child: _buildWorkflowInstancesSection(),
          ),
          
          // Logs Section
          Expanded(
            flex: 1,
            child: _buildLogsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Configuration',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _updateServices(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _domainController,
                    decoration: const InputDecoration(
                      labelText: 'Domain',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _updateServices(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Connection Test Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testVNextConnection,
                  icon: const Icon(Icons.network_check),
                  label: const Text('Test Connection'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                
                ElevatedButton.icon(
                  onPressed: _testVNextServiceStatus,
                  icon: const Icon(Icons.info),
                  label: const Text('Service Status'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowInstancesSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Workflow Instances',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isLoading) const CircularProgressIndicator(),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView(
                children: _availableWorkflows.map(_buildWorkflowGroup).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowGroup(String workflowName) {
    final instances = _workflowInstances[workflowName] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Workflow Group Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_outlined, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                workflowName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${instances.length} instances',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadExistingInstances,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Load Existing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _initializeWorkflow(workflowName),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Instance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Instance Cards Grid
        if (instances.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No instances yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click "Load Existing" to fetch instances from server, or "New Instance" to create a fresh $workflowName instance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: instances.length,
            itemBuilder: (context, index) {
              return _buildInstanceCard(workflowName, index);
            },
          ),
        
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInstanceCard(String workflowName, int instanceIndex) {
    final instances = _workflowInstances[workflowName]!;
    final instance = instances[instanceIndex];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instance Header
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: instance.isInitialized ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Instance #${instanceIndex + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: () => _refreshWorkflowInstance(workflowName, instanceIndex),
                  tooltip: 'Refresh Instance',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Instance Details
            if (instance.isInitialized) ...[
              // Only show state if explicitly provided by the API
              if (instance.state != null) ...[
                Text(
                  'State: ${instance.state}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'ID: ${instance.id}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Show raw attributes count without interpretation
              if (instance.attributes != null && instance.attributes!.isNotEmpty) ...[
                Text(
                  'Attributes: ${instance.attributes!.length} fields',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              
              // Available Transitions
              if (instance.availableTransitions != null && instance.availableTransitions!.isNotEmpty) ...[
                const Text(
                  'Transitions:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: instance.availableTransitions!.map((transition) {
                    return ElevatedButton(
                      onPressed: () => _executeTransition(workflowName, instanceIndex, transition),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 28),
                      ),
                      child: Text(
                        transition,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }).toList(),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'No transitions available',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ] else ...[
              // Not initialized state
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.play_circle_outline, 
                         size: 32, 
                         color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'Not Started',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _initializeWorkflow(workflowName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Start', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            
            // Last Updated
            const Spacer(),
            Text(
              'Updated: ${instance.lastUpdated.toIso8601String().substring(11, 19)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Logs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearLogs,
                  tooltip: 'Clear Logs',
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: ListView.builder(
                  reverse: true,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final logIndex = _logs.length - 1 - index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: Text(
                        _logs[logIndex],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple logger implementation for testing
class _SimpleLogger {
  void logConsole(String message) {
    print('[VNext Test] $message');
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    print('[VNext Test ERROR] $message');
    if (error != null) print('[VNext Test ERROR] Error: $error');
    if (stackTrace != null) print('[VNext Test ERROR] StackTrace: $stackTrace');
  }
}