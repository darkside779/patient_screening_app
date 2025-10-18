import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showWelcomeCard = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    // Hide welcome card after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showWelcomeCard = false;
        });
      }
    });
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AdminService.isCurrentUserAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[600]!,
              Colors.blue[400]!,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 0.6],
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Patient Screening',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Admin Panel Button (only for admins)
                    if (_isAdmin) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                          onPressed: () => context.go('/admin'),
                          tooltip: 'Admin Panel',
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.person, color: Colors.white),
                        onPressed: () => context.go('/profile'),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Welcome Card (Auto-hide after 5 seconds)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: _showWelcomeCard ? null : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _showWelcomeCard ? 1.0 : 0.0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    padding: const EdgeInsets.all(24.0),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange[400]!, Colors.orange[600]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.waving_hand,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back!',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                  ),
                                  Text(
                                    displayName,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.blue[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showWelcomeCard = false;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'How are you feeling today? Track your symptoms and get personalized health insights.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: _showWelcomeCard ? 32 : 16),
              
              // Quick Actions
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
                          children: [
                            _ModernActionCard(
                              icon: Icons.add_circle_outline,
                              title: 'New Entry',
                              subtitle: 'Record symptoms',
                              gradient: [Colors.blue[400]!, Colors.blue[600]!],
                              onTap: () => context.go('/entry'),
                            ),
                            _ModernActionCard(
                              icon: Icons.history,
                              title: 'History',
                              subtitle: 'View past entries',
                              gradient: [Colors.green[400]!, Colors.green[600]!],
                              onTap: () => context.go('/history'),
                            ),
                            _ModernActionCard(
                              icon: Icons.medical_information,
                              title: 'Medical Notes',
                              subtitle: 'Doctor notes',
                              gradient: [Colors.purple[400]!, Colors.purple[600]!],
                              onTap: () => context.push('/patient-medical-notes'),
                            ),
                            _ModernActionCard(
                              icon: Icons.medical_services,
                              title: 'Find Doctors',
                              subtitle: 'Request consultation',
                              gradient: [Colors.teal[400]!, Colors.teal[600]!],
                              onTap: () => context.push('/patient-doctor-search'),
                            ),
                            _ModernActionCard(
                              icon: Icons.settings_outlined,
                              title: 'Profile',
                              subtitle: 'Account settings',
                              gradient: [Colors.orange[400]!, Colors.orange[600]!],
                              onTap: () => context.go('/profile'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Disclaimer
              Container(
                margin: const EdgeInsets.all(20.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This app provides general health information and should not replace professional medical advice.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ModernActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
