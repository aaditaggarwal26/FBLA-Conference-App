import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../services/test_result_service.dart';
import '../../models/test_result_model.dart';

class TestStatisticsScreen extends StatefulWidget {
  const TestStatisticsScreen({super.key});

  @override
  State<TestStatisticsScreen> createState() => _TestStatisticsScreenState();
}

class _TestStatisticsScreenState extends State<TestStatisticsScreen> {
  final TestResultService _testResultService = TestResultService();
  Map<String, dynamic>? _statistics;
  List<TestResultModel> _recentResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('========== STATISTICS SCREEN ERROR ==========');
      print('Error: User not authenticated');
      print('=============================================');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please sign in to view your statistics'),
            backgroundColor: AppTheme.error,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      return;
    }

    try {
      final stats = await _testResultService.getUserStatistics(user.uid);
      final results = await _testResultService
          .getUserTestResults(user.uid)
          .first;

      setState(() {
        _statistics = stats;
        _recentResults = results.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Print full error to console for debugging
      print('========== STATISTICS SCREEN ERROR ==========');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: ${e.toString()}');
      if (e is Exception) {
        print('Exception: $e');
      }
      // Try to get the actual stack trace if available
      try {
        final stackTrace = (e as dynamic).stackTrace;
        if (stackTrace != null) {
          print('Stack Trace: $stackTrace');
        }
      } catch (_) {
        // If stack trace not available, print current
        print('Stack Trace: ${StackTrace.current}');
      }
      print('Full Error Details:');
      print(e);
      print('=============================================');

      if (mounted) {
        String errorMessage = 'Error loading statistics';

        // Provide more specific error messages
        if (e.toString().contains('permission-denied')) {
          errorMessage =
              'Permission denied. Please check your account permissions.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else if (e.toString().contains('unavailable')) {
          errorMessage = 'Service unavailable. Please try again later.';
        } else {
          errorMessage = 'Error loading statistics: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _loadStatistics();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(title: const Text('Test Statistics'), elevation: 0),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            )
          : _statistics == null || _statistics!['totalTests'] == 0
          ? _buildEmptyState(isDark)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Statistics
                  _buildSectionHeader('Overall Performance', isDark),
                  const SizedBox(height: 16),
                  _buildOverallStats(_statistics!, isDark),
                  const SizedBox(height: 32),

                  // Recent Results
                  _buildSectionHeader('Recent Tests', isDark),
                  const SizedBox(height: 16),
                  ..._recentResults.map(
                    (result) => _buildResultCard(result, isDark),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : AppTheme.mediumGray,
          ),
          const SizedBox(height: 16),
          Text(
            'No test results yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some practice tests to see your statistics',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.analytics_rounded,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.black,
          ),
        ),
      ],
    );
  }

  Widget _buildOverallStats(Map<String, dynamic> stats, bool isDark) {
    return Column(
      children: [
        // Main Stats Grid
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Tests',
                '${stats['totalTests']}',
                Icons.quiz_rounded,
                AppTheme.primaryBlue,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Average Score',
                '${(stats['averageScore'] as double).toStringAsFixed(1)}%',
                Icons.trending_up_rounded,
                AppTheme.success,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Best Score',
                '${(stats['bestScore'] as double).toStringAsFixed(1)}%',
                Icons.star_rounded,
                AppTheme.warning,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Questions',
                '${stats['totalQuestions']}',
                Icons.help_outline_rounded,
                AppTheme.secondaryBlue,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Accuracy
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? AppTheme.darkCard : AppTheme.lightGray)
                  .withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Accuracy',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value:
                          (stats['totalCorrect'] as int) /
                          (stats['totalQuestions'] as int),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppTheme.lightBlue,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.success,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${stats['totalCorrect']}/${stats['totalQuestions']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${((stats['totalCorrect'] as int) / (stats['totalQuestions'] as int) * 100).toStringAsFixed(1)}% correct',
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

        // Tests by Event
        if (stats['testsByEvent'] != null &&
            (stats['testsByEvent'] as Map).isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? AppTheme.darkCard : AppTheme.lightGray)
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tests by Event',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 12),
                ...(stats['testsByEvent'] as Map<String, dynamic>).entries
                    .take(5)
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppTheme.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${entry.value}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppTheme.darkCard : AppTheme.lightGray).withValues(
            alpha: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(TestResultModel result, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppTheme.darkCard : AppTheme.lightGray).withValues(
            alpha: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getScoreColor(result.percentage).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                result.percentage.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(result.percentage),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.testTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  result.eventName,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.score}/${result.totalQuestions}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.black,
                ),
              ),
              Text(
                _formatDate(result.completedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.mediumGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
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
}
