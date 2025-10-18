import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalysisScreen extends StatefulWidget {
  final String entryId;

  const AnalysisScreen({
    super.key,
    required this.entryId,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Map<String, dynamic>? _analysisData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load real data from Firestore using widget.entryId
      final doc = await FirebaseFirestore.instance
          .collection('symptom_entries')
          .doc(widget.entryId)
          .get();

      if (!doc.exists) {
        throw Exception('Entry not found');
      }

      final data = doc.data()!;
      
      setState(() {
        _analysisData = {
          'symptoms': data['symptoms'] ?? [],
          'results': data['analysis']['results'] ?? [],
          'recommendation': data['analysis']['recommendation'] ?? 'No recommendation available',
          'treatments': data['analysis']['treatments'] ?? [],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[600]!,
              Colors.blue[400]!,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 0.7],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        'Analyzing Your Symptoms',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loading your analysis...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red[400]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[600],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Analysis Failed',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'An unexpected error occurred',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadAnalysis,
                    child: const Text('Retry Analysis'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    final analysisData = _analysisData!;
    final symptoms = analysisData['symptoms'] as List;
    final results = analysisData['results'] as List;
    final treatments = analysisData['treatments'] as List;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[600]!,
              Colors.blue[400]!,
              Colors.white,
            ],
            stops: const [0.0, 0.2, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Analysis Results',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.history, color: Colors.white),
                        onPressed: () => context.go('/history'),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Symptoms Summary Card
                      _ModernCard(
                        icon: Icons.medical_information,
                        title: 'Your Symptoms',
                        iconColor: Colors.blue,
                        child: Column(
                          children: symptoms.map<Widget>((symptom) {
                            return _SymptomRow(
                              name: symptom['name'],
                              severity: symptom['severity'],
                              duration: symptom['duration'],
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Analysis Results Card
                      _ModernCard(
                        icon: Icons.analytics_outlined,
                        title: 'Possible Conditions',
                        iconColor: Colors.purple,
                        child: Column(
                          children: results.map<Widget>((result) {
                            return _ModernConditionCard(
                              name: result['name'] ?? result['condition'] ?? 'Unknown Condition',
                              probability: ((result['probability'] ?? result['score'] ?? 0.0) as num).toInt(),
                              matchedSymptoms: List<String>.from(result['matchedSymptoms'] ?? []),
                              description: result['description'] ?? '',
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Recommendation Card
                      _ModernCard(
                        icon: Icons.lightbulb_outline,
                        title: 'AI Recommendation',
                        iconColor: Colors.orange,
                        child: Text(
                          analysisData['recommendation'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Treatment Suggestions Card
                      _ModernCard(
                        icon: Icons.healing,
                        title: 'Treatment Suggestions',
                        iconColor: Colors.green,
                        child: Column(
                          children: treatments.map<Widget>((treatment) {
                            return _TreatmentItem(treatment: treatment);
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Disclaimer Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange[600],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Important Disclaimer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[800],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This AI analysis is for informational purposes only and should not replace professional medical advice. Please consult with a healthcare provider for proper diagnosis and treatment.',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Widget child;

  const _ModernCard({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconColor.withValues(alpha: 0.8), iconColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SymptomRow extends StatelessWidget {
  final String name;
  final int severity;
  final String duration;

  const _SymptomRow({
    required this.name,
    required this.severity,
    required this.duration,
  });

  Color _getSeverityColor(int severity) {
    if (severity >= 8) return Colors.red;
    if (severity >= 6) return Colors.orange;
    if (severity >= 4) return Colors.yellow[700]!;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getSeverityColor(severity),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$severity/10',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            duration,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernConditionCard extends StatelessWidget {
  final String name;
  final int probability;
  final List<String> matchedSymptoms;
  final String description;

  const _ModernConditionCard({
    required this.name,
    required this.probability,
    required this.matchedSymptoms,
    required this.description,
  });

  Color _getProbabilityColor(int probability) {
    if (probability >= 70) return Colors.red;
    if (probability >= 50) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getProbabilityColor(probability),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$probability%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: probability / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: _getProbabilityColor(probability),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          if (matchedSymptoms.isNotEmpty) ...[
            Text(
              'Matched symptoms: ${matchedSymptoms.join(', ')}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TreatmentItem extends StatelessWidget {
  final String treatment;

  const _TreatmentItem({required this.treatment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              treatment,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
