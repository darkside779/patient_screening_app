import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _filteredEntries = [];
  String? _error;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _deleteEntry(String entryId) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Entry'),
          content: const Text(
            'Are you sure you want to delete this symptom entry? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Delete from Firestore
        await FirebaseFirestore.instance
            .collection('symptom_entries')
            .doc(entryId)
            .delete();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Reload data
          _loadHistoryData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadHistoryData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('Loading history for user: ${user.uid}');

      // Load symptom entries from Firestore
      // Note: Removed orderBy to avoid needing composite index
      final querySnapshot = await FirebaseFirestore.instance
          .collection('symptom_entries')
          .where('userId', isEqualTo: user.uid)
          .get();

      debugPrint('Found ${querySnapshot.docs.length} entries');

      final entries = <Map<String, dynamic>>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final symptoms = data['symptoms'] as List<dynamic>? ?? [];
        final analysis = data['analysis'] as Map<String, dynamic>? ?? {};
        final results = analysis['results'] as List<dynamic>? ?? [];

        // Get the top condition
        String topCondition = 'General Assessment';
        double topScore = 0.0;
        if (results.isNotEmpty) {
          final topResult = results.first as Map<String, dynamic>;
          topCondition =
              topResult['name'] ??
              topResult['condition'] ??
              'General Assessment';
          topScore =
              ((topResult['probability'] ?? topResult['score'] ?? 0.0) as num)
                  .toDouble();
          if (topScore > 1.0) {
            topScore = topScore / 100.0; // Convert percentage to decimal
          }
        }

        // Calculate average severity
        double avgSeverity = 5.0;
        if (symptoms.isNotEmpty) {
          final severities = symptoms
              .map((s) => (s['severity'] as num?)?.toDouble() ?? 5.0)
              .toList();
          avgSeverity = severities.reduce((a, b) => a + b) / severities.length;
        }

        entries.add({
          'id': doc.id,
          'date': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'symptoms': symptoms.map((s) => s['name'] as String).toList(),
          'topCondition': topCondition,
          'score': topScore,
          'severity': avgSeverity.round(),
          'rawData': data,
        });
      }

      // Sort entries by date (newest first) on client side
      entries.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      setState(() {
        _entries = entries;
        _filteredEntries = entries;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredEntries = _entries.where((entry) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final symptoms = List<String>.from(entry['symptoms']);
          final condition = entry['topCondition'] as String;
          final searchLower = _searchQuery.toLowerCase();
          
          final matchesSearch = symptoms.any((symptom) => 
              symptom.toLowerCase().contains(searchLower)) ||
              condition.toLowerCase().contains(searchLower);
          
          if (!matchesSearch) return false;
        }
        
        // Severity filter
        if (_selectedFilter != 'All') {
          final severity = entry['severity'] as int;
          switch (_selectedFilter) {
            case 'High Severity (7-10)':
              return severity >= 7;
            case 'Medium Severity (4-6)':
              return severity >= 4 && severity <= 6;
            case 'Low Severity (1-3)':
              return severity <= 3;
            case 'Recent (Last 7 days)':
              final date = entry['date'] as DateTime;
              return DateTime.now().difference(date).inDays <= 7;
            case 'This Month':
              final date = entry['date'] as DateTime;
              return DateTime.now().difference(date).inDays <= 30;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[600]!, Colors.blue[400]!, Colors.white],
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
                        'Symptom History',
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
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => context.go('/entry'),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                    ? _buildErrorState()
                    : _entries.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !_isLoading && _error == null
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[700]!],
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
              child: FloatingActionButton(
                onPressed: () => context.go('/entry'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Loading Your History',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching your symptom entries...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 20),
              Text(
                'Unable to Load History',
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _loadHistoryData,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(32),
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[100]!, Colors.blue[200]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.history, size: 64, color: Colors.blue[600]),
              ),
              const SizedBox(height: 24),
              Text(
                'No Entries Yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start tracking your symptoms to see your health history here. Your entries will be securely stored and easily accessible.',
                style: TextStyle(color: Colors.grey[600], height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[700]!],
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
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Record Your First Symptoms',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Summary Card
          _ModernSummaryCard(
            totalEntries: _entries.length,
            lastEntry: _entries.isNotEmpty ? _entries.first['date'] : null,
          ),

          const SizedBox(height: 24),

          // Search and Filter Section
          _buildSearchAndFilter(),

          const SizedBox(height: 16),

          // Results count
          if (_filteredEntries.length != _entries.length)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                'Showing ${_filteredEntries.length} of ${_entries.length} entries',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Entries List
          if (_filteredEntries.isEmpty && (_searchQuery.isNotEmpty || _selectedFilter != 'All'))
            _buildNoResultsState()
          else
            ..._filteredEntries.map(
              (entry) => _ModernHistoryCard(
                entry: entry,
                onTap: () => context.go('/analysis/${entry['id']}'),
                onDelete: () => _deleteEntry(entry['id']),
              ),
            ),

          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(4),
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
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search symptoms or conditions...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: _selectedFilter == 'All',
                onTap: () => _onFilterChanged('All'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'High Severity (7-10)',
                isSelected: _selectedFilter == 'High Severity (7-10)',
                onTap: () => _onFilterChanged('High Severity (7-10)'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Medium Severity (4-6)',
                isSelected: _selectedFilter == 'Medium Severity (4-6)',
                onTap: () => _onFilterChanged('Medium Severity (4-6)'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Low Severity (1-3)',
                isSelected: _selectedFilter == 'Low Severity (1-3)',
                onTap: () => _onFilterChanged('Low Severity (1-3)'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Recent (Last 7 days)',
                isSelected: _selectedFilter == 'Recent (Last 7 days)',
                onTap: () => _onFilterChanged('Recent (Last 7 days)'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'This Month',
                isSelected: _selectedFilter == 'This Month',
                onTap: () => _onFilterChanged('This Month'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(32),
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
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No entries match "$_searchQuery"'
                : 'No entries match the selected filter',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
              _onFilterChanged('All');
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ModernSummaryCard extends StatelessWidget {
  final int totalEntries;
  final DateTime? lastEntry;

  const _ModernSummaryCard({required this.totalEntries, this.lastEntry});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Entries',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalEntries',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          if (lastEntry != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Last Entry',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(lastEntry!),
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${difference}d ago';
    }
  }
}

class _ModernHistoryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ModernHistoryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final symptoms = List<String>.from(entry['symptoms']);
    final date = entry['date'] as DateTime;
    final score = entry['score'] as double;
    final severity = entry['severity'] as int;
    final topCondition = entry['topCondition'] as String;

    return Dismissible(
      key: Key(entry['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(date),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topCondition,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor(score),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(score * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(severity),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$severity/10',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Symptoms
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        symptoms.take(4).map((symptom) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              symptom,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList()..addAll(
                          symptoms.length > 4
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.blue[300]!,
                                      ),
                                    ),
                                    child: Text(
                                      '+${symptoms.length - 4} more',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.blue[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to view full analysis',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return Colors.red;
    if (score >= 0.4) return Colors.orange;
    return Colors.blue;
  }

  Color _getSeverityColor(int severity) {
    if (severity <= 3) return Colors.green;
    if (severity <= 6) return Colors.orange;
    return Colors.red;
  }
}
