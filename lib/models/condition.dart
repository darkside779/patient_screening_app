import 'package:cloud_firestore/cloud_firestore.dart';

class Condition {
  final String id;
  final String name;
  final Map<String, double> symptomWeights; // symptomId -> weight
  final List<String> treatments;
  final List<String> references;

  Condition({
    required this.id,
    required this.name,
    required this.symptomWeights,
    this.treatments = const [],
    this.references = const [],
  });

  factory Condition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Condition(
      id: doc.id,
      name: data['name'] ?? '',
      symptomWeights: Map<String, double>.from(data['symptomWeights'] ?? {}),
      treatments: List<String>.from(data['treatments'] ?? []),
      references: List<String>.from(data['references'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'symptomWeights': symptomWeights,
      'treatments': treatments,
      'references': references,
    };
  }
}

class AnalysisResult {
  final String conditionId;
  final String name;
  final double score; // 0.0 to 1.0
  final List<String> matchedSymptoms;

  AnalysisResult({
    required this.conditionId,
    required this.name,
    required this.score,
    required this.matchedSymptoms,
  });

  factory AnalysisResult.fromMap(Map<String, dynamic> data) {
    return AnalysisResult(
      conditionId: data['conditionId'] ?? '',
      name: data['name'] ?? '',
      score: (data['score'] ?? 0.0).toDouble(),
      matchedSymptoms: List<String>.from(data['matchedSymptoms'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conditionId': conditionId,
      'name': name,
      'score': score,
      'matchedSymptoms': matchedSymptoms,
    };
  }
}

class Analysis {
  final DateTime generatedAt;
  final List<AnalysisResult> results;
  final String recommendation;

  Analysis({
    required this.generatedAt,
    required this.results,
    required this.recommendation,
  });

  factory Analysis.fromMap(Map<String, dynamic> data) {
    return Analysis(
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      results: (data['results'] as List)
          .map((r) => AnalysisResult.fromMap(r as Map<String, dynamic>))
          .toList(),
      recommendation: data['recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'generatedAt': Timestamp.fromDate(generatedAt),
      'results': results.map((r) => r.toMap()).toList(),
      'recommendation': recommendation,
    };
  }
}
