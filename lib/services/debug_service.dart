// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String _output = '';
  
  static String get output => _output;
  static void clearOutput() => _output = '';
  
  static void _log(String message) {
    print(message);
    _output += '$message\n';
  }

  // Debug: List all users in database
  static Future<void> listAllUsers() async {
    try {
      _log('🔍 Checking all users in database...');
      
      final usersQuery = await _firestore.collection('users').get();
      
      if (usersQuery.docs.isEmpty) {
        _log('❌ No users found in database!');
        _log('💡 You need to register some users first');
        return;
      }
      
      _log('✅ Found ${usersQuery.docs.length} users:');
      
      for (final doc in usersQuery.docs) {
        final data = doc.data();
        _log('---');
        _log('ID: ${doc.id}');
        _log('Name: ${data['name'] ?? 'No name'}');
        _log('Email: ${data['email'] ?? 'No email'}');
        _log('Role: ${data['role'] ?? 'No role'}');
        if (data['role'] == 'doctor') {
          _log('Specialization: ${data['specialization'] ?? 'No specialization'}');
          _log('Verified: ${data['verified'] ?? false}');
        }
      }
      
    } catch (e) {
      _log('❌ Error listing users: $e');
    }
  }

  // Debug: Test patient search
  static Future<void> testPatientSearch(String query) async {
    try {
      _log('🔍 Testing patient search for: $query');
      
      final queryLower = query.toLowerCase().trim();

      // Get all patients
      final allPatientsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

      _log('Found ${allPatientsQuery.docs.length} total patients');

      if (allPatientsQuery.docs.isEmpty) {
        _log('❌ No patients found in database!');
        _log('💡 Create some test patients first');
        return;
      }

      final matchingPatients = <QueryDocumentSnapshot>[];
      
      for (final doc in allPatientsQuery.docs) {
        final data = doc.data();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final name = (data['name'] ?? '').toString().toLowerCase();
        
        _log('Checking: ${data['name']} (${data['email']})');
        _log('  Email contains "$queryLower": ${email.contains(queryLower)}');
        _log('  Name contains "$queryLower": ${name.contains(queryLower)}');
        
        // Check if query matches email or name (case-insensitive, contains match)
        if (email.contains(queryLower) || name.contains(queryLower)) {
          matchingPatients.add(doc);
          _log('  ✅ MATCH FOUND!');
        } else {
          _log('  ❌ No match');
        }
      }
      
      _log('');
      _log('🎯 FINAL RESULTS: Found ${matchingPatients.length} matching patients:');
      
      for (final doc in matchingPatients) {
        final data = doc.data() as Map<String, dynamic>;
        _log('✅ ${data['name'] ?? 'No name'} (${data['email'] ?? 'No email'})');
      }
      
    } catch (e) {
      _log('❌ Error searching patients: $e');
    }
  }

  // Debug: Test doctor search
  static Future<void> testDoctorSearch(String query) async {
    try {
      _log('🔍 Testing doctor search for: $query');
      
      final queryLower = query.toLowerCase().trim();

      // Get all verified doctors
      final allDoctorsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .where('verified', isEqualTo: true)
          .get();

      _log('Found ${allDoctorsQuery.docs.length} total verified doctors');

      final matchingDoctors = <QueryDocumentSnapshot>[];
      
      for (final doc in allDoctorsQuery.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final specialization = (data['specialization'] ?? '').toString().toLowerCase();
        
        _log('Checking: Dr. ${data['name']} - ${data['specialization']}');
        _log('  Name contains "$queryLower": ${name.contains(queryLower)}');
        _log('  Specialization contains "$queryLower": ${specialization.contains(queryLower)}');
        
        // Check if query matches name or specialization (case-insensitive, contains match)
        if (name.contains(queryLower) || specialization.contains(queryLower)) {
          matchingDoctors.add(doc);
          _log('  ✅ MATCH FOUND!');
        } else {
          _log('  ❌ No match');
        }
      }
      
      _log('');
      _log('🎯 FINAL RESULTS: Found ${matchingDoctors.length} matching doctors:');
      
      for (final doc in matchingDoctors) {
        final data = doc.data() as Map<String, dynamic>;
        _log('✅ Dr. ${data['name'] ?? 'No name'} - ${data['specialization'] ?? 'No specialization'} (${data['email'] ?? 'No email'})');
      }
      
    } catch (e) {
      _log('❌ Error searching doctors: $e');
    }
  }

  // Debug: Check current user authentication
  static Future<void> checkCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _log('❌ No user is currently logged in');
        return;
      }
      
      _log('✅ Current user:');
      _log('UID: ${user.uid}');
      _log('Email: ${user.email}');
      _log('Display Name: ${user.displayName}');
      
      // Get user document from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _log('Role: ${userData['role'] ?? 'No role'}');
        _log('Name: ${userData['name'] ?? 'No name'}');
        if (userData['role'] == 'doctor') {
          _log('Specialization: ${userData['specialization'] ?? 'No specialization'}');
          _log('Verified: ${userData['verified'] ?? false}');
        }
      } else {
        _log('❌ User document not found in Firestore');
      }
      
    } catch (e) {
      _log('❌ Error checking current user: $e');
    }
  }

  // Debug: Check symptom entries
  static Future<void> checkSymptomEntries() async {
    try {
      _log('🔍 Checking symptom entries in database...');
      
      final entriesQuery = await _firestore.collection('symptom_entries').get();
      
      if (entriesQuery.docs.isEmpty) {
        _log('❌ No symptom entries found in database!');
        _log('💡 Patients need to record some symptoms first');
        return;
      }
      
      _log('✅ Found ${entriesQuery.docs.length} symptom entries:');
      
      for (final doc in entriesQuery.docs) {
        final data = doc.data();
        _log('---');
        _log('Entry ID: ${doc.id}');
        _log('User ID: ${data['userId'] ?? 'No userId'}');
        _log('Date: ${data['createdAt'] ?? 'No date'}');
        _log('Symptoms: ${data['symptoms']?.length ?? 0} symptoms');
        if (data['symptoms'] != null && data['symptoms'].isNotEmpty) {
          for (final symptom in data['symptoms']) {
            _log('  - ${symptom['name']} (severity: ${symptom['severity']})');
          }
        }
      }
      
    } catch (e) {
      _log('❌ Error checking symptom entries: $e');
    }
  }

  // Fix current user's role if missing
  static Future<void> fixCurrentUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _log('❌ No user is currently logged in');
        return;
      }
      
      _log('🔧 Checking current user role...');
      
      // Get current user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        _log('❌ User document not found');
        return;
      }
      
      final data = userDoc.data()!;
      final role = data['role'];
      final email = data['email'] ?? 'No email';
      final name = data['name'] ?? 'No name';
      
      _log('Current user: $name ($email)');
      _log('Current role: ${role ?? 'No role'}');
      
      // Check if user has no role or empty role
      if (role == null || role.toString().trim().isEmpty) {
        _log('Setting role to patient...');
        
        // Update current user to have patient role
        await _firestore.collection('users').doc(user.uid).update({
          'role': 'patient',
        });
        
        _log('✅ Current user role set to patient');
      } else {
        _log('✅ User already has a role: $role');
      }
      
    } catch (e) {
      _log('❌ Error fixing current user role: $e');
    }
  }

  // Fix users without roles (admin only - for all users)
  static Future<void> fixAllUsersRoles() async {
    try {
      _log('🔧 Fixing all users without roles (admin function)...');
      
      // Get all users
      final allUsersQuery = await _firestore.collection('users').get();
      
      _log('Found ${allUsersQuery.docs.length} total users');
      
      int fixedCount = 0;
      
      for (final doc in allUsersQuery.docs) {
        final data = doc.data();
        final role = data['role'];
        final email = data['email'] ?? 'No email';
        final name = data['name'] ?? 'No name';
        
        // Check if user has no role or empty role
        if (role == null || role.toString().trim().isEmpty || role == 'No role') {
          _log('Fixing user: $name ($email) - Setting role to patient');
          
          // Update user to have patient role
          await _firestore.collection('users').doc(doc.id).update({
            'role': 'patient',
          });
          
          fixedCount++;
        } else {
          _log('User OK: $name ($email) - Role: $role');
        }
      }
      
      _log('');
      _log('✅ Fixed $fixedCount users without roles');
      
    } catch (e) {
      _log('❌ Error fixing users without roles: $e');
    }
  }

  // Test access control queries (to verify index fix)
  static Future<void> testAccessControlQueries() async {
    try {
      _log('🧪 Testing access control queries...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _log('❌ No user logged in');
        return;
      }
      
      _log('Testing patient access history query...');
      
      // This should work without composite index now
      final accessQuery = await _firestore
          .collection('doctor_patient_access')
          .where('patientId', isEqualTo: user.uid)
          .get();
      
      _log('✅ Query successful! Found ${accessQuery.docs.length} access records');
      
      for (final doc in accessQuery.docs) {
        final data = doc.data();
        _log('- Access: ${data['doctorId']} -> ${data['status']}');
      }
      
    } catch (e) {
      _log('❌ Error testing access control queries: $e');
    }
  }

  // Create test symptom entries
  static Future<void> createTestSymptomEntries() async {
    try {
      _log('🚀 Creating test symptom entries...');
      
      // Get a patient user ID (preferably one that exists)
      final usersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .limit(1)
          .get();
      
      if (usersQuery.docs.isEmpty) {
        _log('❌ No patient users found. Create users first.');
        return;
      }
      
      final patientId = usersQuery.docs.first.id;
      _log('Using patient ID: $patientId');
      
      // Create test symptom entry
      await _firestore.collection('symptom_entries').add({
        'userId': patientId,
        'createdAt': FieldValue.serverTimestamp(),
        'symptoms': [
          {
            'name': 'Headache',
            'severity': 7,
            'duration': 'Few hours',
            'notes': 'Persistent headache since morning'
          },
          {
            'name': 'Fever',
            'severity': 6,
            'duration': 'Since yesterday',
            'notes': 'Low grade fever'
          }
        ],
        'conditions': [
          {
            'name': 'Viral Infection',
            'probability': 0.75,
            'description': 'Common viral infection with fever and headache'
          }
        ],
        'urgency': 'moderate'
      });
      
      _log('✅ Test symptom entry created successfully!');
      
    } catch (e) {
      _log('❌ Error creating test symptom entries: $e');
    }
  }

  // Create some real test users for development
  static Future<void> createRealTestUsers() async {
    try {
      _log('🚀 Creating real test users...');
      
      // Create test patient
      await _firestore.collection('users').doc('patient_test_123').set({
        'name': 'John Patient',
        'email': 'patient@example.com',
        'role': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Create test patient with "user" in email for search testing
      await _firestore.collection('users').doc('patient_user_456').set({
        'name': 'User Patient',
        'email': 'user@example.com',
        'role': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Create another test patient
      await _firestore.collection('users').doc('patient_test_789').set({
        'name': 'Alice Smith',
        'email': 'alice.smith@example.com',
        'role': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Create test doctor
      await _firestore.collection('users').doc('doctor_test_123').set({
        'name': 'Sarah Doctor',
        'email': 'doctor@example.com',
        'role': 'doctor',
        'specialization': 'Cardiology',
        'hospital': 'Test Hospital',
        'licenseNumber': 'MD123456',
        'verified': true,
        'verificationDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Create another test doctor
      await _firestore.collection('users').doc('doctor_test_456').set({
        'name': 'Mike Dermatologist',
        'email': 'dermatologist@example.com',
        'role': 'doctor',
        'specialization': 'Dermatology',
        'hospital': 'Skin Care Center',
        'licenseNumber': 'MD789012',
        'verified': true,
        'verificationDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _log('✅ Test users created successfully!');
      
    } catch (e) {
      _log('❌ Error creating test users: $e');
    }
  }
}
