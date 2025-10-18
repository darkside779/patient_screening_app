import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../router/app_router.dart';
import '../models/user_role.dart';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  static Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      AppRouter.refreshRouter();
      
      return AuthResult(
        success: true,
        user: credential.user,
        message: 'Successfully signed in',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  // Register with email and password
  static Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create user document in Firestore with patient role
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'name': name,
          'role': UserRole.patient.value,
          'createdAt': FieldValue.serverTimestamp(),
        });

        AppRouter.refreshRouter();

        return AuthResult(
          success: true,
          user: credential.user,
          message: 'Account created successfully',
        );
      }

      return AuthResult(
        success: false,
        message: 'Failed to create account',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
    AppRouter.refreshRouter();
  }

  // Reset password
  static Future<AuthResult> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(
        success: true,
        message: 'Password reset email sent',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  // Register doctor with additional information
  static Future<AuthResult> registerDoctor({
    required String email,
    required String password,
    required String name,
    required String licenseNumber,
    required String specialization,
    String? hospital,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create doctor document in Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'name': name,
          'role': UserRole.doctor.value,
          'licenseNumber': licenseNumber,
          'specialization': specialization,
          'hospital': hospital,
          'verified': false, // Requires manual verification
          'createdAt': FieldValue.serverTimestamp(),
        });

        AppRouter.refreshRouter();

        return AuthResult(
          success: true,
          user: credential.user,
          message: 'Doctor account created successfully. Verification pending.',
        );
      }

      return AuthResult(
        success: false,
        message: 'Failed to create doctor account',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  // Get user role
  static Future<UserRole> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserRole.fromString(data['role'] ?? 'patient');
      }
      return UserRole.patient; // Default to patient if no role found
    } catch (e) {
      return UserRole.patient; // Default to patient on error
    }
  }

  // Get current user role
  static Future<UserRole?> getCurrentUserRole() async {
    final user = currentUser;
    if (user == null) return null;
    return await getUserRole(user.uid);
  }

  // Get user model
  static Future<UserModel?> getUserModel(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get current user model
  static Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;
    return await getUserModel(user.uid);
  }

  // Check if doctor is verified
  static Future<bool> isDoctorVerified(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['verified'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Update doctor verification status (admin function)
  static Future<AuthResult> updateDoctorVerification({
    required String doctorId,
    required bool verified,
  }) async {
    try {
      await _firestore.collection('users').doc(doctorId).update({
        'verified': verified,
        'verificationDate': verified ? FieldValue.serverTimestamp() : null,
      });

      return AuthResult(
        success: true,
        message: verified 
            ? 'Doctor verification approved' 
            : 'Doctor verification revoked',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to update verification status',
      );
    }
  }

  // Delete account and user data
  static Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult(
          success: false,
          message: 'No user logged in',
        );
      }

      // Get user role to determine what data to delete
      final userRole = await getUserRole(user.uid);
      
      // Delete user document
      await _firestore.collection('users').doc(user.uid).delete();
      
      if (userRole.isPatient) {
        // Delete all symptom entries for this patient
        final entries = await _firestore
            .collection('symptom_entries')
            .where('userId', isEqualTo: user.uid)
            .get();
        
        for (final doc in entries.docs) {
          await doc.reference.delete();
        }
        
        // Delete all doctor-patient access records for this patient
        final accessRecords = await _firestore
            .collection('doctor_patient_access')
            .where('patientId', isEqualTo: user.uid)
            .get();
        
        for (final doc in accessRecords.docs) {
          await doc.reference.delete();
        }
      } else if (userRole.isDoctor) {
        // Delete all doctor-patient access records for this doctor
        final accessRecords = await _firestore
            .collection('doctor_patient_access')
            .where('doctorId', isEqualTo: user.uid)
            .get();
        
        for (final doc in accessRecords.docs) {
          await doc.reference.delete();
        }
        
        // Delete all doctor notes for this doctor
        final notes = await _firestore
            .collection('doctor_notes')
            .where('doctorId', isEqualTo: user.uid)
            .get();
        
        for (final doc in notes.docs) {
          await doc.reference.delete();
        }
      }

      // Delete the user account
      await user.delete();
      
      AppRouter.refreshRouter();

      return AuthResult(
        success: true,
        message: 'Account deleted successfully',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  // Get user-friendly error messages
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password should be at least 6 characters';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'requires-recent-login':
        return 'Please log in again to perform this action';
      default:
        return 'Authentication failed. Please try again';
    }
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String message;

  AuthResult({
    required this.success,
    this.user,
    required this.message,
  });
}
