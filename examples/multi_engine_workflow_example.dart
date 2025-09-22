/*
 * neo_core
 *
 * Created on 22/9/2025.
 * Multi-Engine Workflow Example - Demonstrates usage of enhanced workflow management
 */

import 'package:flutter/material.dart';
import 'package:neo_core/core/analytics/neo_logger.dart';
import 'package:neo_core/core/network/models/http_client_config.dart';
import 'package:neo_core/core/workflow_form/neo_workflow_manager.dart';
import 'package:neo_core/core/workflow_form/vnext/vnext_workflow_client.dart';
import 'package:neo_core/core/workflow_form/workflow_router.dart';
import 'package:neo_core/core/workflow_form/workflow_instance_manager.dart';
import 'package:neo_core/core/workflow_form/workflow_engine_config.dart';
import 'package:http/http.dart' as http;

class MultiEngineWorkflowExample extends StatefulWidget {
  const MultiEngineWorkflowExample({super.key});

  @override
  State<MultiEngineWorkflowExample> createState() => _MultiEngineWorkflowExampleState();
}

class _MultiEngineWorkflowExampleState extends State<MultiEngineWorkflowExample> {
  late EnhancedWorkflowRouter workflowRouter;
  late WorkflowInstanceManager instanceManager;
  List<WorkflowInstanceEntity> instances = [];
  List<String> logs = [];
  Map<String, dynamic> stats = {};

  @override
  void initState() {
    super.initState();
    _initializeWorkflowRouter();
    _setupInstanceListener();
  }

  void _initializeWorkflowRouter() {
    // Create sample HTTP client configuration with workflow configurations
    final httpClientConfig = _createSampleHttpClientConfig();
    
    // Create instance manager
    instanceManager = WorkflowInstanceManager(
      logger: SimpleNeoLogger(),
    );

    // Create vNext client
    final vNextClient = VNextWorkflowClient(
      baseUrl: 'http://localhost:4201',
      httpClient: http.Client(),
      logger: SimpleNeoLogger(),
    );

    // Create V1 workflow manager
    final v1Manager = NeoWorkflowManager(null); // Using null for network manager in this example

    // Create enhanced workflow router
    workflowRouter = EnhancedWorkflowRouter(
      v1Manager: v1Manager,
      v2Client: vNextClient,
      logger: SimpleNeoLogger(),
      httpClientConfig: httpClientConfig,
      instanceManager: instanceManager,
    );

    _addLog('✅ Enhanced workflow router initialized');
    _addLog('📊 Configurations loaded: ${httpClientConfig.workflowConfigs.length} workflows');
    _addLog('🔧 vNext support: ${httpClientConfig.hasVNextWorkflows}');
  }

  HttpClientConfig _createSampleHttpClientConfig() {
    // Create sample workflow configurations
    final workflowConfigs = <String, WorkflowEngineConfig>{
      'ecommerce': WorkflowEngineConfig(
        workflowName: 'ecommerce',
        engine: 'vnext',
        config: {
          'baseUrl': 'http://localhost:4201',
          'domain': 'core',
          'fallbackToV1': true,
        },
      ),
      'banking': WorkflowEngineConfig(
        workflowName: 'banking',
        engine: 'amorphie',
        config: {},
      ),
      'payment': WorkflowEngineConfig(
        workflowName: 'payment',
        engine: 'vnext',
        config: {
          'baseUrl': 'http://localhost:4201',
          'domain': 'payments',
          'fallbackToV1': false,
        },
      ),
    };

    final defaultConfig = WorkflowEngineConfig(
      workflowName: 'default',
      engine: 'amorphie',
      config: {},
    );

    return HttpClientConfig(
      hosts: [], // Empty for this example
      config: HttpClientConfigParameters.fromJson({}),
      services: [], // Empty for this example
      workflowConfigs: workflowConfigs,
      defaultWorkflowConfig: defaultConfig,
    );
  }

  void _setupInstanceListener() {
    instanceManager.eventStream.listen((event) {
      setState(() {
        instances = instanceManager.searchInstances();
        stats = instanceManager.getManagerStats();
      });
      
      _addLog('📢 Event: ${event.type.name} for ${event.instance.workflowName} [${event.instance.instanceId.substring(0, 8)}...]');
    });
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      logs.insert(0, '[$timestamp] $message');
      if (logs.length > 50) logs.removeLast();
    });
  }

  Future<void> _createWorkflow(String workflowName) async {
    _addLog('🔄 Creating workflow: $workflowName');
    
    try {
      final engineConfig = workflowRouter.getWorkflowConfig(workflowName);
      _addLog('🎯 Engine selected: ${engineConfig.engine} (valid: ${engineConfig.isValid})');
      
      final response = await workflowRouter.initWorkflow(
        workflowName: workflowName,
        queryParameters: {
          'testMode': 'true',
          'createdVia': 'multi-engine-example',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.isSuccess) {
        _addLog('✅ Workflow created successfully: $workflowName');
        final data = response.asSuccess.data;
        _addLog('📋 Instance ID: ${data['instanceId']}');
        _addLog('📄 Current state: ${data['state'] ?? data['currentState']}');
      } else {
        _addLog('❌ Workflow creation failed: ${response.asError.error}');
      }
    } catch (e) {
      _addLog('🚨 Exception creating workflow: $e');
    }
  }

  Future<void> _postTransition(WorkflowInstanceEntity instance, String transitionName) async {
    _addLog('🔄 Posting transition: $transitionName for ${instance.workflowName}');
    
    try {
      final response = await workflowRouter.postTransition(
        transitionName: transitionName,
        body: {
          'instanceId': instance.instanceId,
          'transitionData': {
            'triggeredBy': 'multi-engine-example',
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );

      if (response.isSuccess) {
        _addLog('✅ Transition executed successfully: $transitionName');
      } else {
        _addLog('❌ Transition failed: ${response.asError.error}');
      }
    } catch (e) {
      _addLog('🚨 Exception posting transition: $e');
    }
  }

  void _terminateInstance(WorkflowInstanceEntity instance) {
    _addLog('🛑 Terminating instance: ${instance.workflowName} [${instance.instanceId.substring(0, 8)}...]');
    workflowRouter.terminateInstance(instance.instanceId, reason: 'Manual termination from example');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Engine Workflow Example'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control Panel
            _buildControlPanel(),
            const SizedBox(height: 16),
            
            // Statistics
            _buildStatistics(),
            const SizedBox(height: 16),
            
            // Instances
            Expanded(
              flex: 2,
              child: _buildInstancesList(),
            ),
            const SizedBox(height: 16),
            
            // Logs
            Expanded(
              flex: 1,
              child: _buildLogsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workflow Creation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _createWorkflow('ecommerce'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Text('Create E-commerce (vNext)', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () => _createWorkflow('banking'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Create Banking (amorphie)', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () => _createWorkflow('payment'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Create Payment (vNext)', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () => _createWorkflow('unknown-workflow'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Create Unknown (default)', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Total Instances: ${stats['currentInstances'] ?? 0}'),
            Text('Active Instances: ${stats['activeInstances'] ?? 0}'),
            Text('Total Created: ${stats['totalInstancesCreated'] ?? 0}'),
            Text('Transitions Executed: ${stats['totalTransitionsExecuted'] ?? 0}'),
            if (stats['engineDistribution'] != null) ...[
              Text('amorphie Instances: ${stats['engineDistribution']['amorphie'] ?? 0}'),
              Text('vNext Instances: ${stats['engineDistribution']['vnext'] ?? 0}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstancesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Instances (${instances.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: instances.isEmpty
                  ? const Center(child: Text('No active instances'))
                  : ListView.builder(
                      itemCount: instances.length,
                      itemBuilder: (context, index) {
                        final instance = instances[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text('${instance.workflowName} (${instance.engine.name})'),
                            subtitle: Text(
                              'ID: ${instance.instanceId.substring(0, 16)}...\n'
                              'Status: ${instance.status} | State: ${instance.currentState ?? 'N/A'}\n'
                              'Domain: ${instance.vNextDomain ?? 'N/A'}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                switch (action) {
                                  case 'transition':
                                    _postTransition(instance, 'test-transition');
                                    break;
                                  case 'terminate':
                                    _terminateInstance(instance);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'transition',
                                  child: Text('Post Transition'),
                                ),
                                const PopupMenuItem(
                                  value: 'terminate',
                                  child: Text('Terminate'),
                                ),
                              ],
                            ),
                            leading: CircleAvatar(
                              backgroundColor: instance.engine == WorkflowEngine.vnext ? Colors.purple : Colors.green,
                              child: Text(
                                instance.engine == WorkflowEngine.vnext ? 'V2' : 'V1',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activity Logs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      logs.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('No logs yet'))
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        Color? textColor;
                        if (log.contains('✅')) textColor = Colors.green;
                        else if (log.contains('❌') || log.contains('🚨')) textColor = Colors.red;
                        else if (log.contains('⚠️')) textColor = Colors.orange;
                        else if (log.contains('🔄')) textColor = Colors.blue;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple logger implementation for the example
class SimpleNeoLogger implements NeoLogger {
  @override
  void logConsole(String message) {
    print('[NeoLogger] $message');
  }

  @override
  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    print('[NeoLogger ERROR] $message');
    if (error != null) print('Error: $error');
    if (stackTrace != null) print('StackTrace: $stackTrace');
  }
}

// Stub implementation for HttpClientConfigParameters
class HttpClientConfigParameters {
  factory HttpClientConfigParameters.fromJson(Map<String, dynamic> json) {
    return HttpClientConfigParameters();
  }
}
