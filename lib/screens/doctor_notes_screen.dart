import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/access_control_service.dart';
import '../models/doctor_note.dart';

class DoctorNotesScreen extends StatefulWidget {
  final String patientId;
  
  const DoctorNotesScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<DoctorNotesScreen> createState() => _DoctorNotesScreenState();
}

class _DoctorNotesScreenState extends State<DoctorNotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  List<DoctorNote> _notes = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  NoteType _selectedType = NoteType.observation;
  bool _isPrivate = false;
  String? _patientName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Load notes for this patient from this doctor
      // Note: Removed orderBy to avoid composite index requirement
      final notesQuery = await FirebaseFirestore.instance
          .collection('doctor_notes')
          .where('doctorId', isEqualTo: user.uid)
          .where('patientId', isEqualTo: widget.patientId)
          .get();

      final notes = notesQuery.docs
          .map((doc) => DoctorNote.fromFirestore(doc))
          .toList();

      // Sort client-side by creation date (newest first)
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Get patient name from access records
      final patients = await AccessControlService.getDoctorPatients(user.uid);
      final patientAccess = patients.where((p) => p.patientId == widget.patientId).firstOrNull;
      
      setState(() {
        _notes = notes;
        _patientName = patientAccess?.patientName ?? 'Unknown Patient';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitNote() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a note'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final note = DoctorNote(
        id: '', // Will be set by Firestore
        doctorId: user.uid,
        patientId: widget.patientId,
        note: _noteController.text.trim(),
        type: _selectedType,
        createdAt: DateTime.now(),
        isPrivate: _isPrivate,
        tags: tags,
        doctorName: 'Dr. ${user.displayName ?? 'Doctor'}',
      );

      await FirebaseFirestore.instance
          .collection('doctor_notes')
          .add(note.toFirestore());

      // Clear form
      _noteController.clear();
      _tagsController.clear();
      setState(() {
        _selectedType = NoteType.observation;
        _isPrivate = false;
      });

      // Reload notes
      await _loadNotes();

      // Switch to notes tab
      _tabController.animateTo(1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
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
            colors: [Colors.purple[600]!, Colors.purple[400]!, Colors.white],
            stops: const [0.0, 0.2, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Tab Bar
              _buildTabBar(),
              
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAddNoteTab(),
                    _buildNotesListTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medical Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _patientName ?? 'Loading...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.purple[600],
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Add Note'),
          Tab(text: 'All Notes'),
        ],
      ),
    );
  }

  Widget _buildAddNoteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
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
                Icon(Icons.note_add, color: Colors.purple[600]),
                const SizedBox(width: 8),
                Text(
                  'Add Medical Note',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Note Type Selection
            const Text(
              'Note Type',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<NoteType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.purple[600]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: NoteType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getNoteTypeIcon(type), size: 18, color: Colors.purple[600]),
                      const SizedBox(width: 8),
                      Text(_getNoteTypeLabel(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            // Note Content
            const Text(
              'Note Content',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Enter your medical note, observations, or recommendations...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.purple[600]!),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            // Tags
            const Text(
              'Tags (Optional)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                hintText: 'Enter tags separated by commas (e.g., urgent, follow-up, medication)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.purple[600]!),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            // Privacy Setting
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Private Note',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Only you can see this note',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPrivate,
                    onChanged: (value) {
                      setState(() {
                        _isPrivate = value;
                      });
                    },
                    activeThumbColor: Colors.purple[600],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add Note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesListTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_notes.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(40),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.note_alt_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Notes Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'You haven\'t added any notes for this patient yet.',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.add),
                label: const Text('Add First Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(DoctorNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNoteTypeIcon(note.type),
                  size: 16,
                  color: Colors.purple[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getNoteTypeLabel(note.type),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatDateTime(note.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (note.isPrivate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Private',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            note.note,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: note.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getNoteTypeIcon(NoteType type) {
    switch (type) {
      case NoteType.observation:
        return Icons.visibility;
      case NoteType.diagnosis:
        return Icons.medical_services;
      case NoteType.recommendation:
        return Icons.lightbulb;
      case NoteType.followUp:
        return Icons.schedule;
    }
  }

  String _getNoteTypeLabel(NoteType type) {
    switch (type) {
      case NoteType.observation:
        return 'Observation';
      case NoteType.diagnosis:
        return 'Diagnosis';
      case NoteType.recommendation:
        return 'Recommendation';
      case NoteType.followUp:
        return 'Follow-up';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
