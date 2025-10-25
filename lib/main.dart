/*
 * neo_core
 *
 * Created on 22/9/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

import 'package:flutter/material.dart';
import 'package:neo_core/examples/vnext_account_opening_test/vnext_account_opening_test_page.dart';
import 'package:neo_core/examples/vnext_integration_test/vnext_integration_test_page.dart';
import 'package:neo_core/neo_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NeoCore.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neo Core Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainNavigationPage(),
    );
  }
}

/// Main navigation page to choose which demo to run
class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neo Core Demos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose a Demo:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // vNext Comprehensive Test Page - The only working test
            _buildDemoCard(
              context: context,
              title: '🚀 vNext Comprehensive Test',
              subtitle: 'Complete vNext workflow integration testing',
              description: 'Test all vNext workflow operations: connection validation, workflow initialization, state transitions, and real-time workflow management with direct backend integration.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VNextComprehensiveTestPage()),
                );
              },
              color: Colors.deepOrange,
            ),

            const SizedBox(height: 20),

            // vNext Integration Test Page - OAuth workflow testing
            _buildDemoCard(
              context: context,
              title: '🔧 vNext OAuth Integration',
              subtitle: 'Test OAuth authentication workflow',
              description: 'Test OAuth2 authentication flow with client validation, MFA (push notification), and automatic polling for workflow state updates.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VNextIntegrationTestPage()),
                );
              },
              color: Colors.teal,
            ),

            const SizedBox(height: 20),

            // vNext Account Opening Test Page - Account opening workflow testing
            _buildDemoCard(
              context: context,
              title: '🏦 vNext Account Opening',
              subtitle: 'Test account opening workflow',
              description: 'Test complete account opening flow with account type selection, details input, confirmation, and automatic state transitions.',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VNextAccountOpeningTestPage()),
                );
              },
              color: Colors.green,
            ),

            const SizedBox(height: 40),

            // Information card about other demos
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'About Other Demos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Other test demos have been removed to focus on the working vNext integration. '
                      'This follows the minimal changes approach where only essential vNext components are included. '
                      'Additional test demos will be available after full architectural refactoring post-vNext deployment.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Open Demo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}