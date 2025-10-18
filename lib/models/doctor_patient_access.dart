import 'package:cloud_firestore/cloud_firestore.dart';

enum AccessLevel {
  read('read'),
  full('full');

  const AccessLevel(this.value);
  final String value;

  static AccessLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'full':
        return AccessLevel.full;
      case 'read':
      default:
        return AccessLevel.read;
    }
  }

  @override
  String toString() => value;
}

enum AccessStatus {
  pending('pending'),
  approved('approved'),
  revoked('revoked'),
  expired('expired');

  const AccessStatus(this.value);
  final String value;

  static AccessStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return AccessStatus.approved;
      case 'revoked':
        return AccessStatus.revoked;
      case 'expired':
        return AccessStatus.expired;
      case 'pending':
      default:
        return AccessStatus.pending;
    }
  }

  @override
  String toString() => value;

  bool get isActive => this == AccessStatus.approved;
  bool get isPending => this == AccessStatus.pending;
}

class DoctorPatientAccess {
  final String id;
  final String doctorId;
  final String patientId;
  final AccessLevel accessLevel;
  final DateTime grantedAt;
  final String grantedBy;
  final AccessStatus status;
  final DateTime? expiresAt;
  final String? requestMessage;
  final String? doctorName;
  final String? patientName;

  const DoctorPatientAccess({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.accessLevel,
    required this.grantedAt,
    required this.grantedBy,
    required this.status,
    this.expiresAt,
    this.requestMessage,
    this.doctorName,
    this.patientName,
  });

  // Factory constructor from Firestore document
  factory DoctorPatientAccess.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorPatientAccess(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      patientId: data['patientId'] ?? '',
      accessLevel: AccessLevel.fromString(data['accessLevel'] ?? 'read'),
      grantedAt: (data['grantedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      grantedBy: data['grantedBy'] ?? '',
      status: AccessStatus.fromString(data['status'] ?? 'pending'),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      requestMessage: data['requestMessage'],
      doctorName: data['doctorName'],
      patientName: data['patientName'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final data = {
      'doctorId': doctorId,
      'patientId': patientId,
      'accessLevel': accessLevel.value,
      'grantedAt': Timestamp.fromDate(grantedAt),
      'grantedBy': grantedBy,
      'status': status.value,
    };

    if (expiresAt != null) {
      data['expiresAt'] = Timestamp.fromDate(expiresAt!);
    }
    if (requestMessage != null) data['requestMessage'] = requestMessage!;
    if (doctorName != null) data['doctorName'] = doctorName!;
    if (patientName != null) data['patientName'] = patientName!;

    return data;
  }

  // Check if access is currently valid
  bool get isValid {
    if (!status.isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return false;
    }
    return true;
  }

  // Copy with method for updates
  DoctorPatientAccess copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    AccessLevel? accessLevel,
    DateTime? grantedAt,
    String? grantedBy,
    AccessStatus? status,
    DateTime? expiresAt,
    String? requestMessage,
    String? doctorName,
    String? patientName,
  }) {
    return DoctorPatientAccess(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      accessLevel: accessLevel ?? this.accessLevel,
      grantedAt: grantedAt ?? this.grantedAt,
      grantedBy: grantedBy ?? this.grantedBy,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      requestMessage: requestMessage ?? this.requestMessage,
      doctorName: doctorName ?? this.doctorName,
      patientName: patientName ?? this.patientName,
    );
  }

  @override
  String toString() {
    return 'DoctorPatientAccess(id: $id, doctorId: $doctorId, patientId: $patientId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoctorPatientAccess && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
