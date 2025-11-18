import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/practice_test_model.dart';
import 'quiz_results_screen.dart';

class QuizScreen extends StatefulWidget {
  final PracticeTestModel practiceTest;

  const QuizScreen({super.key, required this.practiceTest});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  Map<int, int?> _selectedAnswers = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final questions = widget.practiceTest.questions;
    final currentQuestion = questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(title: Text(widget.practiceTest.title), elevation: 0),
      body: Column(
        children: [
          // Progress Bar
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppTheme.darkGray,
                      ),
                    ),
                    Text(
                      '${((_currentQuestionIndex + 1) / questions.length * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / questions.length,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.lightBlue,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // Question Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Number Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Question ${_currentQuestionIndex + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Question Text
                  Text(
                    currentQuestion.question,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.black,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Answer Options
                  ...List.generate(currentQuestion.options.length, (index) {
                    final isSelected =
                        _selectedAnswers[_currentQuestionIndex] == index;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: _buildOptionCard(
                        currentQuestion.options[index],
                        index,
                        isSelected,
                        isDark,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark
                                ? AppTheme.darkPrimary
                                : AppTheme.primaryBlue,
                          ),
                        ),
                        child: Text(
                          'Previous',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkPrimary
                                : AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentQuestionIndex == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentQuestionIndex < questions.length - 1) {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        } else {
                          // Complete quiz
                          _completeQuiz();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                      child: Text(
                        _currentQuestionIndex < questions.length - 1
                            ? 'Next'
                            : 'Complete Quiz',
                        style: const TextStyle(
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
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    String option,
    int index,
    bool isSelected,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAnswers[_currentQuestionIndex] = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                : (isDark ? AppTheme.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryBlue
                  : (isDark ? AppTheme.darkCard : AppTheme.lightGray)
                        .withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : (isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : AppTheme.mediumGray)
                              .withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isDark ? Colors.white : AppTheme.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completeQuiz() {
    final questions = widget.practiceTest.questions;
    int correctAnswers = 0;

    for (int i = 0; i < questions.length; i++) {
      if (_selectedAnswers[i] == questions[i].correctAnswerIndex) {
        correctAnswers++;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultsScreen(
          practiceTest: widget.practiceTest,
          selectedAnswers: _selectedAnswers,
          score: correctAnswers,
          totalQuestions: questions.length,
        ),
      ),
    );
  }
}
