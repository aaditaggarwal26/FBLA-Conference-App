import 'package:cloud_firestore/cloud_firestore.dart';

class TestResultModel {
  final String id;
  final String userId;
  final String testId;
  final String testTitle;
  final String eventName;
  final int score;
  final int totalQuestions;
  final double percentage;
  final Map<int, int?> selectedAnswers; // questionIndex -> selectedAnswerIndex
  final DateTime completedAt;

  TestResultModel({
    required this.id,
    required this.userId,
    required this.testId,
    required this.testTitle,
    required this.eventName,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.selectedAnswers,
    required this.completedAt,
  });

  factory TestResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestResultModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      testId: data['testId'] ?? '',
      testTitle: data['testTitle'] ?? '',
      eventName: data['eventName'] ?? '',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      percentage: (data['percentage'] ?? 0.0).toDouble(),
      selectedAnswers: Map<int, int?>.from(
        (data['selectedAnswers'] as Map<String, dynamic>?)?.map(
              (key, value) =>
                  MapEntry(int.parse(key), value != null ? value as int : null),
            ) ??
            {},
      ),
      completedAt: (data['completedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'testId': testId,
      'testTitle': testTitle,
      'eventName': eventName,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
      'selectedAnswers': selectedAnswers.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }

  String get grade {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  bool get isPassing => percentage >= 60;
}
