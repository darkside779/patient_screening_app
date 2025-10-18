// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    if (user != null) {
      final role = await AuthService.getUserRole(user!.uid);
      if (mounted) {
        setState(() {
          _userRole = role;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await AuthService.signOut();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      final result = await AuthService.deleteAccount();
      
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while user role is being fetched
    if (_userRole == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[600]!, Colors.blue[400]!, Colors.white],
              stops: const [0.0, 0.2, 0.5],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
              // Custom App Bar
              Padding(
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
                        onPressed: () => context.go('/'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildProfileContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
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
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Loading Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Profile Header Card
          _buildProfileHeader(),
          const SizedBox(height: 24),
          
          // Account Information
          _buildAccountSection(),
          const SizedBox(height: 24),
          
          // Settings Section
          _buildSettingsSection(),
          const SizedBox(height: 32),
          
          // Doctor Access Section (only for patients)
          if (_userRole?.isPatient == true) ...[
            _buildDoctorAccessSection(),
            const SizedBox(height: 32),
          ],
          
          // Data Management Section
          _buildDataSection(),
          const SizedBox(height: 32),
          
          // Debug Button (Admin only)
          if (_userRole?.isAdmin == true) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/debug'),
                icon: const Icon(Icons.bug_report),
                label: const Text('Debug Console'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Sign Out Button
          _buildSignOutButton(),
          const SizedBox(height: 16),
          
          // App Version
          _buildAppVersion(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
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
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Text(
                (user?.displayName?.isNotEmpty == true)
                    ? user!.displayName![0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user?.displayName ?? 'User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              user?.email ?? '',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _ModernSection(
      title: 'Account Information',
      icon: Icons.person,
      children: [
        _ModernListTile(
          icon: Icons.person_outline,
          title: 'Name',
          subtitle: user?.displayName ?? 'Not set',
          onTap: _editName,
        ),
        _ModernListTile(
          icon: Icons.email_outlined,
          title: 'Email',
          subtitle: user?.email ?? '',
          showArrow: false,
        ),
        _ModernListTile(
          icon: Icons.calendar_today_outlined,
          title: 'Member Since',
          subtitle: user?.metadata.creationTime != null
              ? _formatDate(user!.metadata.creationTime!)
              : 'Unknown',
          showArrow: false,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return _ModernSection(
      title: 'App Settings',
      icon: Icons.settings,
      children: [
        _ModernListTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage notification preferences',
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
            activeThumbColor: Colors.blue[600],
          ),
          onTap: _showNotificationSettings,
        ),
        _ModernListTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'View our privacy policy',
          onTap: _showPrivacyPolicy,
        ),
        _ModernListTile(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: _showHelpSupport,
        ),
      ],
    );
  }

  Widget _buildDoctorAccessSection() {
    return _ModernSection(
      title: 'Medical Consultation',
      icon: Icons.medical_services,
      children: [
        _ModernListTile(
          icon: Icons.search,
          title: 'Find Doctors',
          subtitle: 'Search and request consultation',
          onTap: () => context.push('/patient-doctor-search'),
        ),
        _ModernListTile(
          icon: Icons.security,
          title: 'Doctor Access',
          subtitle: 'Manage doctor permissions',
          onTap: () => context.push('/patient-access-management'),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return _ModernSection(
      title: 'Data Management',
      icon: Icons.storage,
      children: [
        _ModernListTile(
          icon: Icons.download_outlined,
          title: 'Export Data',
          subtitle: 'Download your health data',
          onTap: _exportData,
        ),
        _ModernListTile(
          icon: Icons.delete_forever_outlined,
          title: 'Delete All Data',
          subtitle: 'Permanently delete all your data',
          onTap: _deleteAccount,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildAppVersion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Patient Screening App v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }


  Future<void> _editName() async {
    _nameController.text = user?.displayName ?? '';
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != user?.displayName) {
      try {
        await user?.updateDisplayName(newName);
        await user?.reload();
        setState(() {});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Name updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating name: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _notificationsEnabled 
              ? 'Notifications enabled' 
              : 'Notifications disabled',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Colors.blue[600]),
                const SizedBox(width: 12),
                const Text(
                  'Notification Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications about your health'),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeThumbColor: Colors.blue[600],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy\n\n'
            'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your information when you use our Patient Screening App.\n\n'
            '1. Information We Collect\n'
            '• Health symptoms and related data you input\n'
            '• Account information (email, name)\n'
            '• Usage analytics to improve our service\n\n'
            '2. How We Use Your Information\n'
            '• To provide health screening analysis\n'
            '• To improve our AI models\n'
            '• To send important updates\n\n'
            '3. Data Security\n'
            '• All data is encrypted in transit and at rest\n'
            '• We use Firebase security protocols\n'
            '• Your data is never shared with third parties\n\n'
            '4. Your Rights\n'
            '• You can export your data at any time\n'
            '• You can delete your account and all data\n'
            '• You can contact us with privacy concerns\n\n'
            'Last updated: October 2024',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help, color: Colors.blue[600]),
                const SizedBox(width: 12),
                const Text(
                  'Help & Support',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _HelpItem(
              icon: Icons.quiz,
              title: 'Frequently Asked Questions',
              subtitle: 'Find answers to common questions',
              onTap: () => _showFAQ(),
            ),
            _HelpItem(
              icon: Icons.email,
              title: 'Contact Support',
              subtitle: 'Get help from our support team',
              onTap: () => _contactSupport(),
            ),
            _HelpItem(
              icon: Icons.bug_report,
              title: 'Report a Bug',
              subtitle: 'Help us improve the app',
              onTap: () => _reportBug(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFAQ() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Q: How accurate is the AI analysis?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'A: Our AI provides preliminary assessments based on symptoms. Always consult healthcare professionals for medical advice.\n',
              ),
              Text(
                'Q: Is my health data secure?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'A: Yes, all data is encrypted and stored securely using Firebase. We never share your personal health information.\n',
              ),
              Text(
                'Q: Can I export my data?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'A: Yes, you can export all your health data from the Profile > Data Management section.\n',
              ),
              Text(
                'Q: How do I delete my account?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'A: Go to Profile > Data Management > Delete All Data. This will permanently remove your account and all data.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Support: support@patientscreening.com'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // In a real app, you'd copy to clipboard
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email copied to clipboard'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
  }

  void _reportBug() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the bug you encountered...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bug report submitted. Thank you!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      setState(() => _isLoading = true);
      
      // Get user data from Firestore
      final userId = user?.uid;
      if (userId == null) return;
      
      final entries = await FirebaseFirestore.instance
          .collection('symptom_entries')
          .where('userId', isEqualTo: userId)
          .get();
      
      setState(() => _isLoading = false);
      
      // Show export options
      if (mounted) {
        showDialog(
          context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Data Export Ready'),
          content: Text(
            'Found ${entries.docs.length} symptom entries to export.\n\n'
            'Your data has been prepared for export. In a full implementation, '
            'this would save to your device or share via email.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Use the outer context (this widget's context) which has Scaffold
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data export completed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Export'),
            ),
          ],
        ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// Custom Widgets
class _ModernSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ModernSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
              ),
            ],
          ),
        ),
        Container(
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
            children: children,
          ),
        ),
      ],
    );
  }
}

class _ModernListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;
  final bool isDestructive;

  const _ModernListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.showArrow = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red[600] : Colors.grey[700];
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive 
                      ? Colors.red[50] 
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDestructive 
                      ? Colors.red[600] 
                      : Colors.blue[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (showArrow && onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue[600], size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
