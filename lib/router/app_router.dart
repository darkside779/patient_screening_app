import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/symptom_entry_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/doctor_registration_screen.dart';
import '../screens/doctor_verification_screen.dart';
import '../screens/doctor_dashboard_screen.dart';
import '../screens/doctor_patient_search_screen.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/admin_registration_screen.dart';
import '../screens/doctor_patients_screen.dart';
import '../screens/doctor_patient_view_screen.dart';
import '../screens/doctor_notes_screen.dart';
import '../screens/doctor_access_requests_screen.dart';
import '../screens/doctor_activity_log_screen.dart';
import '../screens/patient_doctor_search_screen.dart';
import '../screens/patient_access_management_screen.dart';
import '../screens/patient_medical_notes_screen.dart';
import '../screens/debug_screen.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';

class AppRouter {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final user = _auth.currentUser;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;
      
      // Public routes that don't require authentication
      final publicRoutes = ['/login', '/register', '/doctor-registration', '/admin-registration'];
      final isPublicRoute = publicRoutes.contains(location);
      
      // Doctor-specific routes
      final doctorRoutes = ['/doctor-dashboard', '/doctor-verification', '/doctor-patient-search', '/doctor-patients', '/doctor-patient-view', '/doctor-notes', '/doctor-access-requests'];
      final isDoctorRoute = doctorRoutes.any((route) => location.startsWith(route));
      
      // If not logged in and not on public route, redirect to login
      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }
      
      // If logged in, check user role and redirect accordingly
      if (isLoggedIn) {
        try {
          // Check if user is admin first
          final isAdmin = await AdminService.isCurrentUserAdmin();
          
          if (isAdmin) {
            // Admin user logic
            if (isPublicRoute) {
              return '/admin'; // Redirect admin to admin panel
            }
            
            // Allow admin to access admin panel and related routes
            if (location == '/admin' || location.startsWith('/admin')) {
              return null; // Allow access
            }
            
            // Redirect admin away from patient/doctor routes to admin panel
            if (location == '/' || location.startsWith('/entry') || 
                location.startsWith('/history') || location.startsWith('/doctor')) {
              return '/admin';
            }
            
            return null; // Allow other admin routes
          }
          
          // Non-admin user logic
          final userRole = await AuthService.getUserRole(user.uid);
          
          // If on public route, redirect based on role
          if (isPublicRoute) {
            if (userRole.isDoctor) {
              // Check if doctor is verified
              final isVerified = await AuthService.isDoctorVerified(user.uid);
              return isVerified ? '/doctor-dashboard' : '/doctor-verification';
            } else {
              return '/'; // Patient home
            }
          }
          
          // Role-based route protection
          if (userRole.isDoctor) {
            // Check if doctor is verified
            final isVerified = await AuthService.isDoctorVerified(user.uid);
            
            if (!isVerified && location != '/doctor-verification') {
              return '/doctor-verification';
            }
            
            if (isVerified && location == '/doctor-verification') {
              return '/doctor-dashboard';
            }
            
            // If doctor tries to access patient routes, redirect to dashboard
            if (location == '/' || location.startsWith('/entry') || 
                location.startsWith('/history')) {
              return '/doctor-dashboard';
            }
          } else {
            // Patient trying to access doctor routes or admin routes
            if (isDoctorRoute || location.startsWith('/admin')) {
              return '/';
            }
          }
        } catch (e) {
          // If error getting user role, default to login
          return '/login';
        }
      }
      
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/entry',
        name: 'symptom_entry',
        builder: (context, state) => const SymptomEntryScreen(),
      ),
      GoRoute(
        path: '/analysis/:entryId',
        name: 'analysis',
        builder: (context, state) {
          final entryId = state.pathParameters['entryId']!;
          return AnalysisScreen(entryId: entryId);
        },
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // Doctor routes
      GoRoute(
        path: '/doctor-registration',
        name: 'doctor_registration',
        builder: (context, state) => const DoctorRegistrationScreen(),
      ),
      GoRoute(
        path: '/doctor-verification',
        name: 'doctor_verification',
        builder: (context, state) => const DoctorVerificationScreen(),
      ),
      GoRoute(
        path: '/doctor-dashboard',
        name: 'doctor_dashboard',
        builder: (context, state) => const DoctorDashboardScreen(),
      ),
      GoRoute(
        path: '/doctor-patient-search',
        name: 'doctor_patient_search',
        builder: (context, state) => const DoctorPatientSearchScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin_panel',
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: '/admin-registration',
        name: 'admin_registration',
        builder: (context, state) => const AdminRegistrationScreen(),
      ),
      GoRoute(
        path: '/doctor-patients',
        name: 'doctor_patients',
        builder: (context, state) => const DoctorPatientsScreen(),
      ),
      GoRoute(
        path: '/doctor-patient-view/:patientId',
        name: 'doctor_patient_view',
        builder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          return DoctorPatientViewScreen(patientId: patientId);
        },
      ),
      GoRoute(
        path: '/doctor-notes/:patientId',
        name: 'doctor_notes',
        builder: (context, state) {
          final patientId = state.pathParameters['patientId']!;
          return DoctorNotesScreen(patientId: patientId);
        },
      ),
      GoRoute(
        path: '/doctor-access-requests',
        name: 'doctor_access_requests',
        builder: (context, state) => const DoctorAccessRequestsScreen(),
      ),
      GoRoute(
        path: '/doctor-activity-log',
        name: 'doctor_activity_log',
        builder: (context, state) => const DoctorActivityLogScreen(),
      ),
      GoRoute(
        path: '/patient-doctor-search',
        name: 'patient_doctor_search',
        builder: (context, state) => const PatientDoctorSearchScreen(),
      ),
      GoRoute(
        path: '/patient-access-management',
        name: 'patient_access_management',
        builder: (context, state) => const PatientAccessManagementScreen(),
      ),
      GoRoute(
        path: '/patient-medical-notes',
        name: 'patient_medical_notes',
        builder: (context, state) => const PatientMedicalNotesScreen(),
      ),
      GoRoute(
        path: '/debug',
        name: 'debug',
        builder: (context, state) => const DebugScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.matchedLocation}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  // Helper method to refresh router when auth state changes
  static void refreshRouter() {
    router.refresh();
  }
}
