import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/access_control_service.dart';
import '../models/doctor_patient_access.dart';

class PatientAccessManagementScreen extends StatefulWidget {
  const PatientAccessManagementScreen({super.key});

  @override
  State<PatientAccessManagementScreen> createState() => _PatientAccessManagementScreenState();
}

class _PatientAccessManagementScreenState extends State<PatientAccessManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DoctorPatientAccess> _pendingRequests = [];
  List<DoctorPatientAccess> _activeAccess = [];
  List<DoctorPatientAccess> _accessHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAccessData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAccessData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final allAccess = await AccessControlService.getPatientAccessHistory(user.uid);
      final pending = await AccessControlService.getPatientAccessRequests(user.uid);
      
      setState(() {
        _pendingRequests = pending;
        _activeAccess = allAccess.where((access) => access.status.isActive).toList();
        _accessHistory = allAccess;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load access data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveAccess(DoctorPatientAccess request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Access Request'),
        content: Text('Allow Dr. ${request.doctorName} to access your medical records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Deny'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await AccessControlService.grantAccess(request.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );

        if (result.success) {
          _loadAccessData(); // Refresh data
        }
      }
    }
  }

  Future<void> _denyAccess(DoctorPatientAccess request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny Access Request'),
        content: Text('Deny access request from Dr. ${request.doctorName}?'),
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
            child: const Text('Deny'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await AccessControlService.denyAccess(request.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );

        if (result.success) {
          _loadAccessData(); // Refresh data
        }
      }
    }
  }

  Future<void> _revokeAccess(DoctorPatientAccess access) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text('Revoke Dr. ${access.doctorName}\'s access to your medical records?'),
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
      final result = await AccessControlService.revokeAccess(access.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );

        if (result.success) {
          _loadAccessData(); // Refresh data
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
            colors: [Colors.indigo[600]!, Colors.indigo[400]!, Colors.white],
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
                          _buildPendingTab(),
                          _buildActiveTab(),
                          _buildHistoryTab(),
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
          const Expanded(
            child: Text(
              'Doctor Access',
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
          color: Colors.indigo[600],
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        tabs: [
          Tab(text: 'Pending (${_pendingRequests.length})'),
          Tab(text: 'Active (${_activeAccess.length})'),
          Tab(text: 'History'),
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
            'Loading access data...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        'No Pending Requests',
        'You don\'t have any pending doctor access requests.',
        Icons.pending_actions,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return _buildPendingRequestCard(request);
      },
    );
  }

  Widget _buildActiveTab() {
    if (_activeAccess.isEmpty) {
      return _buildEmptyState(
        'No Active Access',
        'No doctors currently have access to your records.',
        Icons.security,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _activeAccess.length,
      itemBuilder: (context, index) {
        final access = _activeAccess[index];
        return _buildActiveAccessCard(access);
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_accessHistory.isEmpty) {
      return _buildEmptyState(
        'No Access History',
        'No doctor access history available.',
        Icons.history,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _accessHistory.length,
      itemBuilder: (context, index) {
        final access = _accessHistory[index];
        return _buildHistoryCard(access);
      },
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

  Widget _buildPendingRequestCard(DoctorPatientAccess request) {
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
              CircleAvatar(
                backgroundColor: Colors.orange[100],
                child: Icon(Icons.pending_actions, color: Colors.orange[600]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.doctorName ?? 'Unknown Doctor',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Requesting ${request.accessLevel == AccessLevel.read ? "read-only" : "full"} access',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (request.requestMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.requestMessage!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _denyAccess(request),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Deny'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveAccess(request),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAccessCard(DoctorPatientAccess access) {
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
              CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Icon(Icons.check_circle, color: Colors.green[600]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      access.doctorName ?? 'Unknown Doctor',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Has ${access.accessLevel == AccessLevel.read ? "read-only" : "full"} access',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Since ${_formatDate(access.grantedAt)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _revokeAccess(access),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Revoke', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(DoctorPatientAccess access) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(access.status)[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(access.status),
              color: _getStatusColor(access.status)[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  access.doctorName ?? 'Unknown Doctor',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _getStatusLabel(access.status),
                  style: TextStyle(
                    color: _getStatusColor(access.status)[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDate(access.grantedAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
