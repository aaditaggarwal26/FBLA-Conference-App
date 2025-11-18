import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../data/practice_tests_data.dart';
import '../../models/practice_test_model.dart';
import '../../models/test_result_model.dart';
import '../../services/test_result_service.dart';
import 'quiz_screen.dart';
import 'test_statistics_screen.dart';

class PracticeTestsScreen extends StatefulWidget {
  const PracticeTestsScreen({super.key});

  @override
  State<PracticeTestsScreen> createState() => _PracticeTestsScreenState();
}

class _PracticeTestsScreenState extends State<PracticeTestsScreen> {
  final List<String> _objectiveTestEvents = [
    'Accounting',
    'Advanced Accounting',
    'Advertising',
    'Agribusiness',
    'Business Communication',
    'Business Law',
    'Computer Problem Solving',
    'Cybersecurity',
    'Data Science & AI',
    'Economics',
    'Healthcare Administration',
    'Human Resource Management',
    'Insurance & Risk Management',
    'Introduction to Business Communication',
    'Introduction to Business Concepts',
    'Introduction to Business Procedures',
    'Introduction to FBLA',
    'Introduction to Information Technology',
    'Introduction to Marketing Concepts',
    'Introduction to Parliamentary Procedure',
    'Introduction to Retail & Merchandising',
    'Introduction to Supply Chain Management',
    'Journalism',
    'Networking Infrastructures',
    'Organizational Leadership',
    'Personal Finance',
    'Project Management',
    'Public Administration & Management',
    'Real Estate',
    'Retail Management',
    'Securities & Investments',
  ];

  String? _selectedEvent;
  List<PracticeTestModel> _filteredTests = [];
  final TestResultService _testResultService = TestResultService();
  Map<String, TestResultModel?> _latestResults = {};

  @override
  void initState() {
    super.initState();
    _filteredTests = PracticeTestsData.getAllTests();
    _loadLatestResults();
  }

  Future<void> _loadLatestResults() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (var test in _filteredTests) {
      final result = await _testResultService.getLatestResultForTest(
        user.uid,
        test.id,
      );
      setState(() {
        _latestResults[test.id] = result;
      });
    }
  }

  void _filterByEvent(String? event) {
    setState(() {
      _selectedEvent = event;
      if (event == null) {
        _filteredTests = PracticeTestsData.getAllTests();
      } else {
        _filteredTests = PracticeTestsData.getTestsForEvent(event);
      }
    });
    _loadLatestResults();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        title: const Text('Practice Tests'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestStatisticsScreen(),
                ),
              );
            },
            tooltip: 'View Statistics',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.quiz_rounded,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Objective Test Events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppTheme.darkCard : AppTheme.lightGray,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedEvent,
                      isExpanded: true,
                      hint: Text(
                        'All Events',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppTheme.darkGray,
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Events'),
                        ),
                        ..._objectiveTestEvents.map((event) {
                          return DropdownMenuItem<String>(
                            value: event,
                            child: Text(event),
                          );
                        }),
                      ],
                      onChanged: _filterByEvent,
                      dropdownColor: isDark
                          ? AppTheme.darkSurface
                          : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tests List
          Expanded(
            child: _filteredTests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppTheme.mediumGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No practice tests found',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppTheme.darkGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTests.length,
                    itemBuilder: (context, index) {
                      final test = _filteredTests[index];
                      return _buildTestCard(test, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(PracticeTestModel test, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppTheme.darkCard : AppTheme.lightGray).withValues(
            alpha: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizScreen(practiceTest: test),
              ),
            );
            // Reload results when returning from quiz
            _loadLatestResults();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.quiz_rounded,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            test.eventName,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  test.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.help_outline_rounded,
                      '${test.totalQuestions} Questions',
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.access_time_rounded,
                      '${test.timeLimitMinutes} min',
                      isDark,
                    ),
                  ],
                ),
                // Previous Result
                if (_latestResults[test.id] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getResultColor(
                        _latestResults[test.id]!.percentage,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getResultColor(
                          _latestResults[test.id]!.percentage,
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: _getResultColor(
                            _latestResults[test.id]!.percentage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Last attempt: ${_latestResults[test.id]!.score}/${_latestResults[test.id]!.totalQuestions} (${_latestResults[test.id]!.percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getResultColor(
                                _latestResults[test.id]!.percentage,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(_latestResults[test.id]!.completedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getResultColor(double percentage) {
    if (percentage >= 80) return AppTheme.success;
    if (percentage >= 60) return AppTheme.warning;
    return AppTheme.error;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }

  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCard.withValues(alpha: 0.5)
            : AppTheme.lightBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppTheme.darkPrimary : AppTheme.primaryBlue,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.8)
                  : AppTheme.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}
