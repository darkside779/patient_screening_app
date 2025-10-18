import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/access_control_service.dart';
import '../models/doctor_patient_access.dart';

class DoctorActivityLogScreen extends StatefulWidget {
  const DoctorActivityLogScreen({super.key});

  @override
  State<DoctorActivityLogScreen> createState() => _DoctorActivityLogScreenState();
}

class _DoctorActivityLogScreenState extends State<DoctorActivityLogScreen> {
  List<DoctorPatientAccess> _allAccess = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivityLog();
  }

  Future<void> _loadActivityLog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get all access records (approved, pending, revoked)
      final patients = await AccessControlService.getDoctorPatients(user.uid);
      final pending = await AccessControlService.getDoctorPendingRequests(user.uid);
      
      // Combine and sort by date
      final allAccess = [...patients, ...pending];
      allAccess.sort((a, b) => b.grantedAt.compareTo(a.grantedAt));
      
      setState(() {
        _allAccess = allAccess;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load activity: $e'),
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
            colors: [Colors.green[600]!, Colors.green[400]!, Colors.white],
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
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildActivityList(),
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
              'Activity Log',
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
              '${_allAccess.length} activities',
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
            'Loading activity...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    if (_allAccess.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _allAccess.length,
      itemBuilder: (context, index) {
        final activity = _allAccess[index];
        return _buildActivityCard(activity);
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
              Icons.timeline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Activity Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your patient access activities will appear here.',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/doctor-patient-search'),
              icon: const Icon(Icons.search),
              label: const Text('Search Patients'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(DoctorPatientAccess activity) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(activity.status)[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(activity.status),
                  size: 16,
                  color: _getStatusColor(activity.status)[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getActivityTitle(activity.status),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      activity.patientName ?? 'Unknown Patient',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(activity.status)[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(activity.status)[200]!),
                ),
                child: Text(
                  _getStatusLabel(activity.status),
                  style: TextStyle(
                    color: _getStatusColor(activity.status)[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(activity.grantedAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.security, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                activity.accessLevel == AccessLevel.read ? 'Read Only' : 'Full Access',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          if (activity.requestMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                activity.requestMessage!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  MaterialColor _getStatusColor(AccessStatus status) {
    switch (status) {
      case AccessStatus.pending:
        return Colors.orange;
      case AccessStatus.approved:
        return Colors.green;
      case AccessStatus.revoked:
      case AccessStatus.expired:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(AccessStatus status) {
    switch (status) {
      case AccessStatus.pending:
        return Icons.pending_actions;
      case AccessStatus.approved:
        return Icons.check_circle;
      case AccessStatus.revoked:
        return Icons.cancel;
      case AccessStatus.expired:
        return Icons.access_time;
    }
  }

  String _getActivityTitle(AccessStatus status) {
    switch (status) {
      case AccessStatus.pending:
        return 'Access Request Sent';
      case AccessStatus.approved:
        return 'Access Granted';
      case AccessStatus.revoked:
        return 'Access Revoked';
      case AccessStatus.expired:
        return 'Access Expired';
    }
  }

  String _getStatusLabel(AccessStatus status) {
    switch (status) {
      case AccessStatus.pending:
        return 'Pending';
      case AccessStatus.approved:
        return 'Active';
      case AccessStatus.revoked:
        return 'Revoked';
      case AccessStatus.expired:
        return 'Expired';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
