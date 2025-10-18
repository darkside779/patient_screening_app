// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor_patient_access.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AccessControlService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Request access to a patient's data
  static Future<AccessResult> requestPatientAccess({
    required String doctorId,
    required String patientEmail,
    required AccessLevel accessLevel,
    String? message,
  }) async {
    try {
      // Find patient by email
      final patientQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: patientEmail.toLowerCase().trim())
          .where('role', isEqualTo: 'patient')
          .get();

      if (patientQuery.docs.isEmpty) {
        return AccessResult(
          success: false,
          message: 'No patient found with email: $patientEmail',
        );
      }

      final patientDoc = patientQuery.docs.first;
      final patientId = patientDoc.id;
      final patientData = patientDoc.data();

      // Check if access request already exists
      final existingAccess = await _firestore
          .collection('doctor_patient_access')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: patientId)
          .get();

      if (existingAccess.docs.isNotEmpty) {
        final access = DoctorPatientAccess.fromFirestore(existingAccess.docs.first);
        if (access.status.isActive) {
          return AccessResult(
            success: false,
            message: 'You already have active access to this patient',
          );
        }
        if (access.status.isPending) {
          return AccessResult(
            success: false,
            message: 'Access request is already pending approval',
          );
        }
      }

      // Get doctor information
      final doctorUser = await AuthService.getUserModel(doctorId);
      if (doctorUser == null) {
        return AccessResult(
          success: false,
          message: 'Doctor information not found',
        );
      }

      // Create access request
      final accessRequest = DoctorPatientAccess(
        id: '', // Will be set by Firestore
        doctorId: doctorId,
        patientId: patientId,
        accessLevel: accessLevel,
        grantedAt: DateTime.now(),
        grantedBy: patientId, // Will be updated when patient approves
        status: AccessStatus.pending,
        requestMessage: message,
        doctorName: 'Dr. ${doctorUser.name}',
        patientName: patientData['name'] ?? 'Unknown',
      );

      await _firestore
          .collection('doctor_patient_access')
          .add(accessRequest.toFirestore());

      return AccessResult(
        success: true,
        message: 'Access request sent successfully. Patient will be notified.',
      );
    } catch (e) {
      return AccessResult(
        success: false,
        message: 'Failed to send access request: $e',
      );
    }
  }

  // Grant access to a doctor (called by patient)
  static Future<AccessResult> grantAccess(String accessRequestId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return AccessResult(
          success: false,
          message: 'User not authenticated',
        );
      }

      await _firestore
          .collection('doctor_patient_access')
          .doc(accessRequestId)
          .update({
        'status': AccessStatus.approved.value,
        'grantedAt': FieldValue.serverTimestamp(),
        'grantedBy': user.uid,
      });

      return AccessResult(
        success: true,
        message: 'Access granted successfully',
      );
    } catch (e) {
      return AccessResult(
        success: false,
        message: 'Failed to grant access: $e',
      );
    }
  }

  // Revoke access (can be called by patient or admin)
  static Future<AccessResult> revokeAccess(String accessId) async {
    try {
      await _firestore
          .collection('doctor_patient_access')
          .doc(accessId)
          .update({
        'status': AccessStatus.revoked.value,
      });

      return AccessResult(
        success: true,
        message: 'Access revoked successfully',
      );
    } catch (e) {
      return AccessResult(
        success: false,
        message: 'Failed to revoke access: $e',
      );
    }
  }

  // Check if doctor has access to patient
  static Future<bool> hasAccess(String doctorId, String patientId) async {
    try {
      final accessQuery = await _firestore
          .collection('doctor_patient_access')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: AccessStatus.approved.value)
          .get();

      if (accessQuery.docs.isEmpty) return false;

      // Check if access is still valid (not expired)
      final access = DoctorPatientAccess.fromFirestore(accessQuery.docs.first);
      return access.isValid;
    } catch (e) {
      return false;
    }
  }

  // Get all patients accessible by a doctor
  static Future<List<DoctorPatientAccess>> getDoctorPatients(String doctorId) async {
    try {
      final accessQuery = await _firestore
          .collection('doctor_patient_access')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: AccessStatus.approved.value)
          .get();

      return accessQuery.docs
          .map((doc) => DoctorPatientAccess.fromFirestore(doc))
          .where((access) => access.isValid)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get pending access requests for a patient
  static Future<List<DoctorPatientAccess>> getPatientAccessRequests(String patientId) async {
    try {
      final requestsQuery = await _firestore
          .collection('doctor_patient_access')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: AccessStatus.pending.value)
          .get();

      return requestsQuery.docs
          .map((doc) => DoctorPatientAccess.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get all access records for a patient (for management)
  static Future<List<DoctorPatientAccess>> getPatientAccessHistory(String patientId) async {
    try {
      final accessQuery = await _firestore
          .collection('doctor_patient_access')
          .where('patientId', isEqualTo: patientId)
          .get();

      // Sort client-side to avoid composite index requirement
      final accessList = accessQuery.docs
          .map((doc) => DoctorPatientAccess.fromFirestore(doc))
          .toList();
      
      accessList.sort((a, b) => b.grantedAt.compareTo(a.grantedAt));
      
      return accessList;
    } catch (e) {
      return [];
    }
  }

  // Get pending access requests for a doctor
  static Future<List<DoctorPatientAccess>> getDoctorPendingRequests(String doctorId) async {
    try {
      final requestsQuery = await _firestore
          .collection('doctor_patient_access')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', isEqualTo: AccessStatus.pending.value)
          .get();

      return requestsQuery.docs
          .map((doc) => DoctorPatientAccess.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Search for patients by email (for doctors to request access)
  static Future<List<UserModel>> searchPatients(String emailQuery) async {
    try {
      if (emailQuery.trim().isEmpty) return [];

      final queryLower = emailQuery.toLowerCase().trim();

      // Get all patients and filter client-side for better matching
      final allPatientsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

      final matchingPatients = <UserModel>[];
      
      for (final doc in allPatientsQuery.docs) {
        final data = doc.data();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final name = (data['name'] ?? '').toString().toLowerCase();
        
        // Check if query matches email or name (case-insensitive, contains match)
        if (email.contains(queryLower) || name.contains(queryLower)) {
          matchingPatients.add(UserModel.fromFirestore(doc));
        }
      }

      return matchingPatients.take(10).toList(); // Limit to 10 results
    } catch (e) {
      print('Error searching patients: $e');
      return [];
    }
  }

  // Search for doctors by name or specialization (for patients to request access)
  static Future<List<UserModel>> searchDoctors(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final queryLower = query.toLowerCase().trim();

      // Get all verified doctors and filter client-side for better matching
      final allDoctorsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('verified', isEqualTo: true)
          .get();

      final matchingDoctors = <UserModel>[];
      
      for (final doc in allDoctorsQuery.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final specialization = (data['specialization'] ?? '').toString().toLowerCase();
        
        // Check if query matches name or specialization (case-insensitive, contains match)
        if (name.contains(queryLower) || specialization.contains(queryLower)) {
          matchingDoctors.add(UserModel.fromFirestore(doc));
        }
      }

      return matchingDoctors.take(10).toList(); // Limit to 10 results
    } catch (e) {
      print('Error searching doctors: $e');
      return [];
    }
  }

  // Request access from a doctor (patient requesting doctor to view their records)
  static Future<AccessResult> requestDoctorAccess({
    required String patientId,
    required String doctorId,
    required AccessLevel accessLevel,
    String? message,
  }) async {
    try {
      // Check if access request already exists
      final existingAccess = await _firestore
          .collection('doctor_patient_access')
          .where('doctorId', isEqualTo: doctorId)
          .where('patientId', isEqualTo: patientId)
          .get();

      if (existingAccess.docs.isNotEmpty) {
        final access = DoctorPatientAccess.fromFirestore(existingAccess.docs.first);
        if (access.status.isActive) {
          return AccessResult(
            success: false,
            message: 'This doctor already has access to your records',
          );
        }
        if (access.status.isPending) {
          return AccessResult(
            success: false,
            message: 'Access request is already pending approval',
          );
        }
      }

      // Get doctor and patient information
      final doctorUser = await AuthService.getUserModel(doctorId);
      final patientUser = await AuthService.getUserModel(patientId);
      
      if (doctorUser == null || patientUser == null) {
        return AccessResult(
          success: false,
          message: 'User information not found',
        );
      }

      // Create access request (patient requesting doctor to have access)
      final accessRequest = DoctorPatientAccess(
        id: '', // Will be set by Firestore
        doctorId: doctorId,
        patientId: patientId,
        accessLevel: accessLevel,
        grantedAt: DateTime.now(),
        grantedBy: patientId, // Patient is granting access
        status: AccessStatus.pending,
        requestMessage: message,
        doctorName: 'Dr. ${doctorUser.name}',
        patientName: patientUser.name,
      );

      await _firestore
          .collection('doctor_patient_access')
          .add(accessRequest.toFirestore());

      return AccessResult(
        success: true,
        message: 'Access request sent successfully. The doctor will be notified.',
      );
    } catch (e) {
      return AccessResult(
        success: false,
        message: 'Failed to send access request: $e',
      );
    }
  }

  // Get patient symptom entries (if doctor has access)
  static Future<List<Map<String, dynamic>>> getPatientSymptomEntries(
    String doctorId,
    String patientId,
  ) async {
    try {
      // First check if doctor has access
      final hasPatientAccess = await hasAccess(doctorId, patientId);
      if (!hasPatientAccess) {
        throw Exception('Access denied: No permission to view patient data');
      }

      // Get symptom entries
      final entriesQuery = await _firestore
          .collection('symptom_entries')
          .where('userId', isEqualTo: patientId)
          .get();

      return entriesQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get patient entries: $e');
    }
  }

  // Deny access request (called by patient)
  static Future<AccessResult> denyAccess(String accessRequestId) async {
    try {
      await _firestore
          .collection('doctor_patient_access')
          .doc(accessRequestId)
          .update({
        'status': AccessStatus.revoked.value,
      });

      return AccessResult(
        success: true,
        message: 'Access request denied',
      );
    } catch (e) {
      return AccessResult(
        success: false,
        message: 'Failed to deny access: $e',
      );
    }
  }

  // Get access statistics for dashboard
  static Future<Map<String, int>> getAccessStatistics(String userId, bool isDoctor) async {
    try {
      if (isDoctor) {
        final patients = await getDoctorPatients(userId);
        final pending = await getDoctorPendingRequests(userId);
        
        return {
          'totalPatients': patients.length,
          'pendingRequests': pending.length,
          'activeAccess': patients.where((p) => p.isValid).length,
        };
      } else {
        final accessHistory = await getPatientAccessHistory(userId);
        final pendingRequests = await getPatientAccessRequests(userId);
        
        return {
          'totalDoctors': accessHistory.where((a) => a.status.isActive).length,
          'pendingRequests': pendingRequests.length,
          'totalRequests': accessHistory.length,
        };
      }
    } catch (e) {
      return {
        'totalPatients': 0,
        'pendingRequests': 0,
        'activeAccess': 0,
      };
    }
  }
}

class AccessResult {
  final bool success;
  final String message;
  final DoctorPatientAccess? access;

  AccessResult({
    required this.success,
    required this.message,
    this.access,
  });
}
