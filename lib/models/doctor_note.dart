import 'package:cloud_firestore/cloud_firestore.dart';

enum NoteType {
  observation('observation'),
  recommendation('recommendation'),
  diagnosis('diagnosis'),
  followUp('follow_up');

  const NoteType(this.value);
  final String value;

  static NoteType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'recommendation':
        return NoteType.recommendation;
      case 'diagnosis':
        return NoteType.diagnosis;
      case 'follow_up':
        return NoteType.followUp;
      case 'observation':
      default:
        return NoteType.observation;
    }
  }

  @override
  String toString() => value;

  String get displayName {
    switch (this) {
      case NoteType.observation:
        return 'Observation';
      case NoteType.recommendation:
        return 'Recommendation';
      case NoteType.diagnosis:
        return 'Diagnosis';
      case NoteType.followUp:
        return 'Follow-up';
    }
  }
}

class DoctorNote {
  final String id;
  final String doctorId;
  final String patientId;
  final String? entryId; // linked to specific symptom entry
  final String note;
  final NoteType type;
  final DateTime createdAt;
  final bool isPrivate; // visible to patient or not
  final List<String> tags;
  final String? doctorName;

  const DoctorNote({
    required this.id,
    required this.doctorId,
    required this.patientId,
    this.entryId,
    required this.note,
    required this.type,
    required this.createdAt,
    required this.isPrivate,
    this.tags = const [],
    this.doctorName,
  });

  // Factory constructor from Firestore document
  factory DoctorNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorNote(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      patientId: data['patientId'] ?? '',
      entryId: data['entryId'],
      note: data['note'] ?? '',
      type: NoteType.fromString(data['type'] ?? 'observation'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPrivate: data['isPrivate'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      doctorName: data['doctorName'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final data = {
      'doctorId': doctorId,
      'patientId': patientId,
      'note': note,
      'type': type.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPrivate': isPrivate,
      'tags': tags,
    };

    if (entryId != null) data['entryId'] = entryId!;
    if (doctorName != null) data['doctorName'] = doctorName!;

    return data;
  }

  // Copy with method for updates
  DoctorNote copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    String? entryId,
    String? note,
    NoteType? type,
    DateTime? createdAt,
    bool? isPrivate,
    List<String>? tags,
    String? doctorName,
  }) {
    return DoctorNote(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      entryId: entryId ?? this.entryId,
      note: note ?? this.note,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      tags: tags ?? this.tags,
      doctorName: doctorName ?? this.doctorName,
    );
  }

  @override
  String toString() {
    return 'DoctorNote(id: $id, doctorId: $doctorId, patientId: $patientId, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoctorNote && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
