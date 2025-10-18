import 'package:cloud_firestore/cloud_firestore.dart';

class Symptom {
  final String id;
  final String name;
  final String category;
  final List<String> aliases;
  final String? icdCode;

  Symptom({
    required this.id,
    required this.name,
    required this.category,
    this.aliases = const [],
    this.icdCode,
  });

  factory Symptom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Symptom(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      aliases: List<String>.from(data['aliases'] ?? []),
      icdCode: data['icdCode'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'aliases': aliases,
      if (icdCode != null) 'icdCode': icdCode,
    };
  }
}

class SymptomEntry {
  final String symptomId;
  final String name;
  final int severity; // 1-10 scale
  final String duration;
  final String? notes;

  SymptomEntry({
    required this.symptomId,
    required this.name,
    required this.severity,
    required this.duration,
    this.notes,
  });

  factory SymptomEntry.fromMap(Map<String, dynamic> data) {
    return SymptomEntry(
      symptomId: data['symptomId'] ?? '',
      name: data['name'] ?? '',
      severity: data['severity'] ?? 1,
      duration: data['duration'] ?? '',
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'symptomId': symptomId,
      'name': name,
      'severity': severity,
      'duration': duration,
      if (notes != null) 'notes': notes,
    };
  }

  SymptomEntry copyWith({
    String? symptomId,
    String? name,
    int? severity,
    String? duration,
    String? notes,
  }) {
    return SymptomEntry(
      symptomId: symptomId ?? this.symptomId,
      name: name ?? this.name,
      severity: severity ?? this.severity,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
    );
  }
}
