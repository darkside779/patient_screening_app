import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/access_control_service.dart';
import '../models/doctor_patient_access.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  List<DoctorPatientAccess> _patients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final patients = await AccessControlService.getDoctorPatients(user.uid);
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load patients: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<DoctorPatientAccess> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    
    return _patients.where((patient) {
      final patientName = patient.patientName?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return patientName.contains(query);
    }).toList();
  }

  Future<void> _viewPatientData(DoctorPatientAccess patient) async {
    context.push('/doctor-patient-view/${patient.patientId}');
  }

  Future<void> _revokeAccess(DoctorPatientAccess patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text('Are you sure you want to revoke access to ${patient.patientName}\'s medical records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await AccessControlService.revokeAccess(patient.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );

        if (result.success) {
          _loadPatients(); // Refresh the list
        }
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
              
              // Search Bar
              _buildSearchBar(),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildPatientsList(),
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
          const Expanded(
            child: Text(
              'My Patients',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_filteredPatients.length} patients',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search patients...',
          prefixIcon: Icon(Icons.search, color: Colors.teal[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
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
            'Loading patients...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    final filteredPatients = _filteredPatients;

    if (filteredPatients.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = filteredPatients[index];
        return _buildPatientCard(patient);
      },
    );
  }

  Widget _buildEmptyState() {
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
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No patients found' : 'No patients yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No patients match your search "$_searchQuery"'
                  : 'You don\'t have access to any patient records yet. Use "Search Patients" to request access.',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/doctor-patient-search'),
                icon: const Icon(Icons.search),
                label: const Text('Search Patients'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(DoctorPatientAccess patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // Patient Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal[100],
                  radius: 25,
                  child: Text(
                    patient.patientName?.isNotEmpty == true 
                        ? patient.patientName![0].toUpperCase()
                        : 'P',
                    style: TextStyle(
                      color: Colors.teal[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.patientName ?? 'Unknown Patient',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getAccessLevelColor(patient.accessLevel)[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getAccessLevelColor(patient.accessLevel)[200]!,
                              ),
                            ),
                            child: Text(
                              patient.accessLevel == AccessLevel.read ? 'Read Only' : 'Full Access',
                              style: TextStyle(
                                color: _getAccessLevelColor(patient.accessLevel)[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Since ${_formatDate(patient.grantedAt)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _viewPatientData(patient);
                        break;
                      case 'revoke':
                        _revokeAccess(patient);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text('View Records'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'revoke',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Revoke Access', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewPatientData(patient),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Records'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/doctor-notes/${patient.patientId}'),
                    icon: const Icon(Icons.note_add, size: 18),
                    label: const Text('Add Note'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  MaterialColor _getAccessLevelColor(AccessLevel level) {
    switch (level) {
      case AccessLevel.read:
        return Colors.blue;
      case AccessLevel.full:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}
