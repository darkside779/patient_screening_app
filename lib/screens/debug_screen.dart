// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/debug_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _debugOutput = '';
  bool _isLoading = false;

  void _addToOutput(String message) {
    setState(() {
      _debugOutput += '$message\n';
    });
  }

  Future<void> _runDebugCommand(String command) async {
    setState(() {
      _isLoading = true;
      _debugOutput = 'Running: $command\n';
    });

    // Clear previous output
    DebugService.clearOutput();

    try {
      switch (command) {
        case 'list_users':
          await DebugService.listAllUsers();
          break;
        case 'check_user':
          await DebugService.checkCurrentUser();
          break;
        case 'create_test_users':
          await DebugService.createRealTestUsers();
          break;
        case 'test_patient_search':
          final query = _searchController.text.trim();
          if (query.isNotEmpty) {
            await DebugService.testPatientSearch(query);
          } else {
            DebugService.clearOutput();
            _addToOutput('Please enter a search query first');
          }
          break;
        case 'test_doctor_search':
          final query = _searchController.text.trim();
          if (query.isNotEmpty) {
            await DebugService.testDoctorSearch(query);
          } else {
            DebugService.clearOutput();
            _addToOutput('Please enter a search query first');
          }
          break;
        case 'check_symptom_entries':
          await DebugService.checkSymptomEntries();
          break;
        case 'create_test_symptoms':
          await DebugService.createTestSymptomEntries();
          break;
        case 'fix_current_user_role':
          await DebugService.fixCurrentUserRole();
          break;
        case 'fix_all_user_roles':
          await DebugService.fixAllUsersRoles();
          break;
        case 'test_access_queries':
          await DebugService.testAccessControlQueries();
          break;
      }
      
      // Get the captured output
      setState(() {
        _debugOutput = DebugService.output;
      });
      
    } catch (e) {
      _addToOutput('Error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Console'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Tools',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Search input
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Query (for testing)',
                hintText: 'Enter email or name to test search',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Debug buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _runDebugCommand('list_users'),
                  child: const Text('List All Users'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _runDebugCommand('check_user'),
                  child: const Text('Check Current User'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _runDebugCommand('create_test_users'),
                  child: const Text('Create Test Users'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _runDebugCommand('test_patient_search'),
                  child: const Text('Test Patient Search'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _runDebugCommand('test_doctor_search'),
                  child: const Text('Test Doctor Search'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _runDebugCommand('check_symptom_entries'),
                  child: const Text('Check Symptom Entries'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _runDebugCommand('create_test_symptoms'),
                  child: const Text('Create Test Symptoms'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _runDebugCommand('fix_current_user_role'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Fix My Role'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _runDebugCommand('fix_all_user_roles'),
                  child: const Text('Fix All Roles (Admin)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _runDebugCommand('test_access_queries'),
                  child: const Text('Test Access Queries'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Clear button
            ElevatedButton(
              onPressed: () => setState(() => _debugOutput = ''),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear Output'),
            ),
            
            const SizedBox(height: 16),
            
            // Output area
            const Text(
              'Debug Output:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput.isEmpty ? 'No output yet. Run a debug command.' : _debugOutput,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
