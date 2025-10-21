import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Admin user IDs - you can add your admin email/ID here
  static const List<String> adminEmails = [
    'admin@patientscreening.com',
    'admin@admin.com', // Add your admin email here
    'test@test.com', // Add your test email here
    'admin@example.com', // Common test email
    'user@example.com', // Another test email
    // Add your actual email here to become admin
  ];

  // Create admin user (for initial setup)
  static Future<AdminResult> createAdminUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Check if email is in admin list
      if (!adminEmails.contains(email.toLowerCase())) {
        return AdminResult(
          success: false,
          message: 'Email not authorized for admin access',
        );
      }

      // Create Firebase Auth user
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create admin user document in Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'name': name,
          'role': 'admin',
          'isAdmin': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return AdminResult(
          success: true,
          message: 'Admin account created successfully',
        );
      }

      return AdminResult(
        success: false,
        message: 'Failed to create admin account',
      );
    } catch (e) {
      return AdminResult(
        success: false,
        message: 'Failed to create admin: $e',
      );
    }
  }

  // Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    return adminEmails.contains(user.email?.toLowerCase());
  }

  // Get all pending doctor verifications
  static Future<List<UserModel>> getPendingDoctors() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('verified', isEqualTo: false)
          .get();

      // Filter out rejected doctors (only show truly pending ones)
      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((doctor) => doctor.verificationStatus != 'rejected')
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get all verified doctors
  static Future<List<UserModel>> getVerifiedDoctors() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('verified', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get all rejected doctors
  static Future<List<UserModel>> getRejectedDoctors() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('verificationStatus', isEqualTo: 'rejected')
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Verify/Activate a doctor
  static Future<AdminResult> verifyDoctor(String doctorId) async {
    try {
      // Check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        return AdminResult(
          success: false,
          message: 'Access denied: Admin privileges required',
        );
      }

      // Update doctor verification status
      await _firestore.collection('users').doc(doctorId).update({
        'verified': true,
        'verificationStatus': 'verified',
        'verificationDate': FieldValue.serverTimestamp(),
      });

      return AdminResult(
        success: true,
        message: 'Doctor verified successfully',
      );
    } catch (e) {
      // Handle specific Firestore errors
      if (e.toString().contains('permission-denied')) {
        return AdminResult(
          success: false,
          message: 'Permission denied. Please check Firestore security rules.',
        );
      }
      
      return AdminResult(
        success: false,
        message: 'Failed to verify doctor: ${e.toString()}',
      );
    }
  }

  // Reject/Revoke doctor verification
  static Future<AdminResult> rejectDoctor(String doctorId) async {
    try {
      // Check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        return AdminResult(
          success: false,
          message: 'Access denied: Admin privileges required',
        );
      }

      await _firestore.collection('users').doc(doctorId).update({
        'verified': false,
        'verificationStatus': 'rejected',
        'verificationDate': null,
        'rejectionDate': FieldValue.serverTimestamp(),
      });

      return AdminResult(
        success: true,
        message: 'Doctor verification rejected',
      );
    } catch (e) {
      return AdminResult(
        success: false,
        message: 'Failed to reject doctor: $e',
      );
    }
  }

  // Delete doctor account (extreme case)
  static Future<AdminResult> deleteDoctorAccount(String doctorId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(doctorId).delete();
      
      // Delete all doctor-patient access records
      final accessRecords = await _firestore
          .collection('doctor_patient_access')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      for (final doc in accessRecords.docs) {
        await doc.reference.delete();
      }
      
      // Delete all doctor notes
      final notes = await _firestore
          .collection('doctor_notes')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      for (final doc in notes.docs) {
        await doc.reference.delete();
      }

      return AdminResult(
        success: true,
        message: 'Doctor account deleted successfully',
      );
    } catch (e) {
      return AdminResult(
        success: false,
        message: 'Failed to delete doctor account: $e',
      );
    }
  }

  // Get admin statistics
  static Future<Map<String, int>> getAdminStats() async {
    try {
      final pendingDoctors = await getPendingDoctors();
      final verifiedDoctors = await getVerifiedDoctors();
      
      // Get total patients
      final patientsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();
      
      // Get total access requests
      final accessRequestsQuery = await _firestore
          .collection('doctor_patient_access')
          .get();

      return {
        'pendingDoctors': pendingDoctors.length,
        'verifiedDoctors': verifiedDoctors.length,
        'totalPatients': patientsQuery.docs.length,
        'totalAccessRequests': accessRequestsQuery.docs.length,
      };
    } catch (e) {
      return {
        'pendingDoctors': 0,
        'verifiedDoctors': 0,
        'totalPatients': 0,
        'totalAccessRequests': 0,
      };
    }
  }

  // Quick verify doctor by email (for testing)
  static Future<AdminResult> quickVerifyDoctorByEmail(String email) async {
    try {
      // Check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        return AdminResult(
          success: false,
          message: 'Access denied: Admin privileges required',
        );
      }

      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .where('role', isEqualTo: 'doctor')
          .get();

      if (query.docs.isEmpty) {
        return AdminResult(
          success: false,
          message: 'No doctor found with email: $email',
        );
      }

      final doctorDoc = query.docs.first;
      await _firestore.collection('users').doc(doctorDoc.id).update({
        'verified': true,
        'verificationStatus': 'verified',
        'verificationDate': FieldValue.serverTimestamp(),
      });

      return AdminResult(
        success: true,
        message: 'Doctor $email verified successfully',
      );
    } catch (e) {
      // Handle specific Firestore errors
      if (e.toString().contains('permission-denied')) {
        return AdminResult(
          success: false,
          message: 'Permission denied. Please check Firestore security rules.',
        );
      }
      
      return AdminResult(
        success: false,
        message: 'Failed to verify doctor: ${e.toString()}',
      );
    }
  }
}

class AdminResult {
  final bool success;
  final String message;

  AdminResult({
    required this.success,
    required this.message,
  });
}
