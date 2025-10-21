import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  
  // Doctor-specific fields
  final String? licenseNumber;
  final String? specialization;
  final String? hospital;
  final bool? verified;
  final DateTime? verificationDate;
  final String? verificationStatus; // 'pending', 'verified', 'rejected'

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.licenseNumber,
    this.specialization,
    this.hospital,
    this.verified,
    this.verificationDate,
    this.verificationStatus,
  });

  // Factory constructor from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'patient'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      licenseNumber: data['licenseNumber'],
      specialization: data['specialization'],
      hospital: data['hospital'],
      verified: data['verified'],
      verificationDate: (data['verificationDate'] as Timestamp?)?.toDate(),
      verificationStatus: data['verificationStatus'] ?? 'pending',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final data = {
      'email': email,
      'name': name,
      'role': role.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    // Add doctor-specific fields if they exist
    if (licenseNumber != null) data['licenseNumber'] = licenseNumber!;
    if (specialization != null) data['specialization'] = specialization!;
    if (hospital != null) data['hospital'] = hospital!;
    if (verified != null) data['verified'] = verified!;
    if (verificationDate != null) {
      data['verificationDate'] = Timestamp.fromDate(verificationDate!);
    }
    if (verificationStatus != null) data['verificationStatus'] = verificationStatus!;

    return data;
  }

  // Copy with method for updates
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    String? licenseNumber,
    String? specialization,
    String? hospital,
    bool? verified,
    DateTime? verificationDate,
    String? verificationStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      specialization: specialization ?? this.specialization,
      hospital: hospital ?? this.hospital,
      verified: verified ?? this.verified,
      verificationDate: verificationDate ?? this.verificationDate,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
