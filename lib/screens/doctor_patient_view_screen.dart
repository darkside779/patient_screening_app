import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/access_control_service.dart';

class DoctorPatientViewScreen extends StatefulWidget {
  final String patientId;
  
  const DoctorPatientViewScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<DoctorPatientViewScreen> createState() => _DoctorPatientViewScreenState();
}

class _DoctorPatientViewScreenState extends State<DoctorPatientViewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _symptomEntries = [];
  bool _isLoading = true;
  String? _patientName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get patient symptom entries
      final entries = await AccessControlService.getPatientSymptomEntries(
        user.uid,
        widget.patientId,
      );
      
      // Get patient name from access records
      final patients = await AccessControlService.getDoctorPatients(user.uid);
      final patientAccess = patients.where((p) => p.patientId == widget.patientId).firstOrNull;
      
      setState(() {
        _symptomEntries = entries;
        _patientName = patientAccess?.patientName ?? 'Unknown Patient';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load patient data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[600]!, Colors.teal[400]!, Colors.white],
            stops: const [0.0, 0.2, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Tab Bar
              _buildTabBar(),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSymptomEntriesTab(),
                          _buildAnalysisTab(),
                          _buildNotesTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Patient Records',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _patientName ?? 'Loading...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.note_add, color: Colors.white),
              onPressed: () => context.push('/doctor-notes/${widget.patientId}'),
              tooltip: 'Add Note',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.teal[600],
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Symptoms'),
          Tab(text: 'Analysis'),
          Tab(text: 'Notes'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            'Loading patient data...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomEntriesTab() {
    if (_symptomEntries.isEmpty) {
      return _buildEmptyState(
        'No Symptom Entries',
        'This patient hasn\'t recorded any symptoms yet.',
        Icons.sick,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _symptomEntries.length,
      itemBuilder: (context, index) {
        final entry = _symptomEntries[index];
        return _buildSymptomEntryCard(entry);
      },
    );
  }

  Widget _buildAnalysisTab() {
    final analyzedEntries = _symptomEntries.where((entry) => 
      entry['analysis'] != null && entry['analysis'].isNotEmpty
    ).toList();

    if (analyzedEntries.isEmpty) {
      return _buildEmptyState(
        'No Analysis Available',
        'No symptom entries have been analyzed yet.',
        Icons.analytics,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: analyzedEntries.length,
      itemBuilder: (context, index) {
        final entry = analyzedEntries[index];
        return _buildAnalysisCard(entry);
      },
    );
  }

  Widget _buildNotesTab() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_add,
              size: 64,
              color: Colors.purple[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Doctor Notes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add professional notes and recommendations for this patient.',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/doctor-notes/${widget.patientId}'),
              icon: const Icon(Icons.add),
              label: const Text('Add Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomEntryCard(Map<String, dynamic> entry) {
    final symptoms = entry['symptoms'] as List<dynamic>? ?? [];
    final date = entry['date'] as DateTime?;
    final severity = entry['severity'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sick, color: Colors.teal[600]),
              const SizedBox(width: 8),
              Text(
                'Symptom Entry',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity)[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getSeverityColor(severity)[200]!),
                ),
                child: Text(
                  'Severity: $severity/10',
                  style: TextStyle(
                    color: _getSeverityColor(severity)[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (date != null) ...[
            Text(
              'Date: ${_formatDateTime(date)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          if (symptoms.isNotEmpty) ...[
            const Text(
              'Symptoms:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: symptoms.map<Widget>((symptom) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    _formatSymptom(symptom),
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/analysis/${entry['id']}'),
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('View Analysis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(Map<String, dynamic> entry) {
    final analysis = entry['analysis'] as Map<String, dynamic>? ?? {};
    final conditions = analysis['conditions'] as List<dynamic>? ?? [];
    final date = entry['date'] as DateTime?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text(
                'Analysis Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (date != null)
                Text(
                  _formatDateTime(date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (conditions.isNotEmpty) ...[
            const Text(
              'Possible Conditions:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...conditions.map<Widget>((condition) {
              final name = condition['name'] ?? 'Unknown';
              final probability = condition['probability'] ?? 0.0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${(probability * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/analysis/${entry['id']}'),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Full Analysis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  MaterialColor _getSeverityColor(int severity) {
    if (severity >= 7) return Colors.red;
    if (severity >= 4) return Colors.orange;
    return Colors.green;
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatSymptom(dynamic symptom) {
    if (symptom is Map<String, dynamic>) {
      final name = symptom['name'] ?? 'Unknown';
      final severity = symptom['severity'];
      final duration = symptom['duration'];
      
      String result = name;
      
      if (severity != null) {
        result += ' ($severity/10)';
      }
      
      if (duration != null && duration.toString().isNotEmpty) {
        result += ' - $duration';
      }
      
      return result;
    }
    
    // Fallback for other formats
    return symptom.toString();
  }
}
