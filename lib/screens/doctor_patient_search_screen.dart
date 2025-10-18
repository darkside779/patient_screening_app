import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/access_control_service.dart';
import '../models/user_model.dart';
import '../models/doctor_patient_access.dart';

class DoctorPatientSearchScreen extends StatefulWidget {
  const DoctorPatientSearchScreen({super.key});

  @override
  State<DoctorPatientSearchScreen> createState() =>
      _DoctorPatientSearchScreenState();
}

class _DoctorPatientSearchScreenState extends State<DoctorPatientSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  bool _isRequesting = false;
  AccessLevel _selectedAccessLevel = AccessLevel.read;

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _searchPatients(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isSearching = true);
    }

    try {
      final results = await AccessControlService.searchPatients(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestAccess(UserModel patient) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show request dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _buildAccessRequestDialog(patient),
    );

    if (result == true) {
      if (mounted) {
        setState(() => _isRequesting = true);
      }

      try {
        final accessResult = await AccessControlService.requestPatientAccess(
          doctorId: user.uid,
          patientEmail: patient.email,
          accessLevel: _selectedAccessLevel,
          message: _messageController.text.trim().isNotEmpty
              ? _messageController.text.trim()
              : null,
        );

        if (mounted) {
          setState(() => _isRequesting = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(accessResult.message),
              backgroundColor: accessResult.success ? Colors.green : Colors.red,
            ),
          );

          if (accessResult.success) {
            _messageController.clear();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isRequesting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
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

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // Search Section
                      _buildSearchSection(),
                      const SizedBox(height: 24),

                      // Results Section
                      _buildResultsSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
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
          const Expanded(
            child: Text(
              'Search Patients',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.teal[600]),
              const SizedBox(width: 8),
              Text(
                'Find Patient',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _searchController,
            onChanged: _searchPatients,
            decoration: InputDecoration(
              hintText: 'Enter patient email address...',
              prefixIcon: Icon(Icons.email_outlined, color: Colors.teal[600]),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        if (mounted) {
                          setState(() => _searchResults = []);
                        }
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.teal[600]!),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search by patient email to request access to their medical records.',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_searchController.text.trim().isEmpty) {
      return _buildEmptyState();
    }

    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.teal[600]),
                const SizedBox(width: 8),
                Text(
                  'Search Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_searchResults.length} found',
                    style: TextStyle(
                      color: Colors.teal[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final patient = _searchResults[index];
              return _buildPatientTile(patient);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPatientTile(UserModel patient) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Colors.teal[100],
        child: Text(
          patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
          style: TextStyle(
            color: Colors.teal[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        patient.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        patient.email,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
      trailing: ElevatedButton(
        onPressed: _isRequesting ? null : () => _requestAccess(patient),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isRequesting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Request Access', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
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
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Search for Patients',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a patient\'s email address to search and request access to their medical records.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
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
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
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
        children: [
          Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Patients Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No patients found with email "${_searchController.text}". Please check the email address and try again.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildAccessRequestDialog(UserModel patient) {
    return StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          title: const Text('Request Patient Access'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient: ${patient.name}'),
                Text('Email: ${patient.email}'),
                const SizedBox(height: 16),

                const Text(
                  'Access Level:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<AccessLevel>(
                  initialValue: _selectedAccessLevel,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: AccessLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(
                        level == AccessLevel.read ? 'Read Only' : 'Full Access',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _selectedAccessLevel = value!;
                      });
                      setDialogState(() {});
                    }
                  },
                ),

                const SizedBox(height: 16),

                const Text(
                  'Message (Optional):',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Explain why you need access to this patient\'s records...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.of(dialogContext).pop(false);
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isRequesting ? null : () {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: _isRequesting 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Send Request'),
            ),
          ],
        );
      },
    );
  }
}
