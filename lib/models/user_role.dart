enum UserRole {
  patient('patient'),
  doctor('doctor'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      case 'patient':
      default:
        return UserRole.patient;
    }
  }

  @override
  String toString() => value;

  bool get isDoctor => this == UserRole.doctor;
  bool get isPatient => this == UserRole.patient;
  bool get isAdmin => this == UserRole.admin;
}
