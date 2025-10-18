import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/access_control_service.dart';
import '../models/user_model.dart';
import '../models/doctor_patient_access.dart';

class PatientDoctorSearchScreen extends StatefulWidget {
  const PatientDoctorSearchScreen({super.key});

  @override
  State<PatientDoctorSearchScreen> createState() => _PatientDoctorSearchScreenState();
}

class _PatientDoctorSearchScreenState extends State<PatientDoctorSearchScreen> {
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

  Future<void> _searchDoctors(String query) async {
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
      final results = await AccessControlService.searchDoctors(query);
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

  Future<void> _requestAccess(UserModel doctor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show request dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _buildAccessRequestDialog(doctor),
    );

    if (result == true) {
      if (mounted) {
        setState(() => _isRequesting = true);
      }

      try {
        final accessResult = await AccessControlService.requestDoctorAccess(
          patientId: user.uid,
          doctorId: doctor.id,
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
            colors: [Colors.blue[600]!, Colors.blue[400]!, Colors.white],
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
              'Find Doctors',
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
              Icon(Icons.medical_services, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Find Healthcare Professionals',
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
            onChanged: _searchDoctors,
            decoration: InputDecoration(
              hintText: 'Search by doctor name or specialization...',
              prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
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
                borderSide: BorderSide(color: Colors.blue[600]!),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Request access from verified doctors to get professional medical insights on your symptoms.',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
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
                Icon(Icons.local_hospital, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Available Doctors',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_searchResults.length} found',
                    style: TextStyle(
                      color: Colors.blue[700],
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
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) {
              final doctor = _searchResults[index];
              return _buildDoctorTile(doctor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorTile(UserModel doctor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            radius: 25,
            child: Text(
              doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D',
              style: TextStyle(
                color: Colors.blue[700],
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
                  'Dr. ${doctor.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal[200]!),
                      ),
                      child: Text(
                        doctor.specialization ?? 'General Medicine',
                        style: TextStyle(
                          color: Colors.teal[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 12, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (doctor.hospital != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    doctor.hospital!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isRequesting ? null : () => _requestAccess(doctor),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                : const Text(
                    'Request Access',
                    style: TextStyle(fontSize: 12),
                  ),
          ),
        ],
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
          Icon(
            Icons.medical_services,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Find Healthcare Professionals',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for doctors by name or specialization to request access to share your medical records for professional consultation.',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Cardiology',
              'Dermatology',
              'Neurology',
              'Pediatrics',
              'Psychiatry',
            ].map((specialization) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = specialization;
                  _searchDoctors(specialization);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    specialization,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
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
            'Searching for doctors...',
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
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Doctors Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No verified doctors found matching "${_searchController.text}". Try searching with different keywords or specializations.',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessRequestDialog(UserModel doctor) {
    return StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          title: const Text('Request Medical Consultation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Doctor: Dr. ${doctor.name}'),
                Text('Specialization: ${doctor.specialization ?? "General Medicine"}'),
                if (doctor.hospital != null)
                  Text('Hospital: ${doctor.hospital}'),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: AccessLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level == AccessLevel.read ? 'Read Only' : 'Full Access'),
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
                    hintText: 'Describe your symptoms or reason for consultation...',
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
