import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_service.dart';

class SymptomEntryScreen extends StatefulWidget {
  const SymptomEntryScreen({super.key});

  @override
  State<SymptomEntryScreen> createState() => _SymptomEntryScreenState();
}

class _SymptomEntryScreenState extends State<SymptomEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _selectedSymptoms = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _availableSymptoms = [
    {'id': 'headache', 'name': 'Headache', 'category': 'Neurological'},
    {'id': 'fever', 'name': 'Fever', 'category': 'General'},
    {'id': 'cough', 'name': 'Cough', 'category': 'Respiratory'},
    {'id': 'fatigue', 'name': 'Fatigue', 'category': 'General'},
    {'id': 'nausea', 'name': 'Nausea', 'category': 'Gastrointestinal'},
    {'id': 'sore_throat', 'name': 'Sore Throat', 'category': 'Respiratory'},
    {'id': 'muscle_pain', 'name': 'Muscle Pain', 'category': 'Musculoskeletal'},
    {'id': 'dizziness', 'name': 'Dizziness', 'category': 'Neurological'},
  ];

  final List<String> _durationOptions = [
    'Less than 1 hour',
    '1-6 hours',
    '6-24 hours',
    '1-3 days',
    '3-7 days',
    '1-2 weeks',
    'More than 2 weeks',
  ];

  void _addSymptom(Map<String, dynamic> symptom) {
    setState(() {
      _selectedSymptoms.add({
        'id': symptom['id'],
        'name': symptom['name'],
        'severity': 5,
        'duration': '1-6 hours',
        'notes': '',
      });
    });
  }

  void _removeSymptom(String symptomId) {
    setState(() {
      _selectedSymptoms.removeWhere((s) => s['id'] == symptomId);
    });
  }

  void _updateSymptom(String symptomId, String key, dynamic value) {
    setState(() {
      final index = _selectedSymptoms.indexWhere((s) => s['id'] == symptomId);
      if (index != -1) {
        _selectedSymptoms[index][key] = value;
      }
    });
  }

  Future<void> _submitEntry() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one symptom'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get AI analysis first (with fallback)
      final analysis = await AIService.analyzeSymptoms(_selectedSymptoms);
      
      // Create entry data for Firestore
      final entryData = {
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'symptoms': _selectedSymptoms,
        'analysis': analysis,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      debugPrint('Saving to Firestore: ${entryData.toString()}');
      final docRef = await FirebaseFirestore.instance
          .collection('symptom_entries')
          .add(entryData);

      debugPrint('Saved to Firestore with ID: ${docRef.id}');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Navigate to analysis screen with real entry ID
        context.go('/analysis/${docRef.id}');
      }
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Form(
            key: _formKey,
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
                          'Record Symptoms',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Symptoms Selection Card
                        Container(
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
                                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.medical_information,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Select Your Symptoms',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Symptom Chips
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _availableSymptoms.map((symptom) {
                                  final isSelected = _selectedSymptoms
                                      .any((s) => s['id'] == symptom['id']);
                                  return _ModernSymptomChip(
                                    label: symptom['name'],
                                    isSelected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        _addSymptom(symptom);
                                      } else {
                                        _removeSymptom(symptom['id']);
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Selected Symptoms Details
                        if (_selectedSymptoms.isNotEmpty) ...[
                          Container(
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
                                          colors: [Colors.green[400]!, Colors.green[600]!],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.tune,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Symptom Details',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                ..._selectedSymptoms.map((symptom) => _ModernSymptomDetailCard(
                                      symptom: symptom,
                                      durationOptions: _durationOptions,
                                      onUpdate: _updateSymptom,
                                      onRemove: () => _removeSymptom(symptom['id']),
                                    )),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                
                // Modern Submit Button
                Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.blue[600]!,
                          Colors.blue[700]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Analyze Symptoms',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernSymptomChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _ModernSymptomChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected 
            ? LinearGradient(colors: [Colors.blue[400]!, Colors.blue[600]!])
            : null,
        color: isSelected ? null : Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSelected ? Colors.transparent : Colors.grey[300]!,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(!isSelected),
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernSymptomDetailCard extends StatelessWidget {
  final Map<String, dynamic> symptom;
  final List<String> durationOptions;
  final Function(String, String, dynamic) onUpdate;
  final VoidCallback onRemove;

  const _ModernSymptomDetailCard({
    required this.symptom,
    required this.durationOptions,
    required this.onUpdate,
    required this.onRemove,
  });

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  symptom['name'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red[400]),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Severity Slider
          Text(
            'Severity: ${symptom['severity']}/10',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue[400],
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Colors.blue[600],
              overlayColor: Colors.blue.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: symptom['severity'].toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: symptom['severity'].toString(),
              onChanged: (value) => onUpdate(symptom['id'], 'severity', value.round()),
            ),
          ),
          const SizedBox(height: 20),
          
          // Duration Dropdown
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: symptom['duration'],
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: durationOptions.map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text(duration),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onUpdate(symptom['id'], 'duration', value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Notes Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextFormField(
              initialValue: symptom['notes'],
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintText: 'Any additional details...',
              ),
              maxLines: 2,
              onChanged: (value) => onUpdate(symptom['id'], 'notes', value),
            ),
          ),
        ],
      ),
    );
  }
}
