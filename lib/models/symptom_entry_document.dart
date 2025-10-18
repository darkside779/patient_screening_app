import 'package:cloud_firestore/cloud_firestore.dart';
import 'symptom.dart';
import 'condition.dart';

class SymptomEntryDocument {
  final String id;
  final String userId;
  final List<SymptomEntry> symptoms;
  final Analysis analysis;
  final DateTime createdAt;
  final String? deviceInfo;
  final String? appVersion;

  SymptomEntryDocument({
    required this.id,
    required this.userId,
    required this.symptoms,
    required this.analysis,
    required this.createdAt,
    this.deviceInfo,
    this.appVersion,
  });

  factory SymptomEntryDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SymptomEntryDocument(
      id: doc.id,
      userId: data['userId'] ?? '',
      symptoms: (data['symptoms'] as List)
          .map((s) => SymptomEntry.fromMap(s as Map<String, dynamic>))
          .toList(),
      analysis: Analysis.fromMap(data['analysis'] as Map<String, dynamic>),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      deviceInfo: data['deviceInfo'],
      appVersion: data['appVersion'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'symptoms': symptoms.map((s) => s.toMap()).toList(),
      'analysis': analysis.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      if (appVersion != null) 'appVersion': appVersion,
    };
  }

  SymptomEntryDocument copyWith({
    String? id,
    String? userId,
    List<SymptomEntry>? symptoms,
    Analysis? analysis,
    DateTime? createdAt,
    String? deviceInfo,
    String? appVersion,
  }) {
    return SymptomEntryDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symptoms: symptoms ?? this.symptoms,
      analysis: analysis ?? this.analysis,
      createdAt: createdAt ?? this.createdAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
