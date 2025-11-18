import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/test_result_model.dart';

class TestResultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save test result
  Future<void> saveTestResult(TestResultModel result) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('test_results').add(result.toFirestore());
  }

  // Get user's test results
  Stream<List<TestResultModel>> getUserTestResults(String userId) {
    return _firestore
        .collection('test_results')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TestResultModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get user's results for a specific test
  Future<List<TestResultModel>> getUserResultsForTest(
    String userId,
    String testId,
  ) async {
    final snapshot = await _firestore
        .collection('test_results')
        .where('userId', isEqualTo: userId)
        .where('testId', isEqualTo: testId)
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TestResultModel.fromFirestore(doc))
        .toList();
  }

  // Get user's latest result for a specific test
  Future<TestResultModel?> getLatestResultForTest(
    String userId,
    String testId,
  ) async {
    final snapshot = await _firestore
        .collection('test_results')
        .where('userId', isEqualTo: userId)
        .where('testId', isEqualTo: testId)
        .orderBy('completedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return TestResultModel.fromFirestore(snapshot.docs.first);
  }

  // Get user's statistics
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    final snapshot = await _firestore
        .collection('test_results')
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) {
      return {
        'totalTests': 0,
        'averageScore': 0.0,
        'totalQuestions': 0,
        'totalCorrect': 0,
        'bestScore': 0.0,
        'testsByEvent': <String, int>{},
      };
    }

    final results = snapshot.docs
        .map((doc) => TestResultModel.fromFirestore(doc))
        .toList();

    int totalTests = results.length;
    double totalPercentage = 0.0;
    int totalQuestions = 0;
    int totalCorrect = 0;
    double bestScore = 0.0;
    Map<String, int> testsByEvent = {};

    for (var result in results) {
      totalPercentage += result.percentage;
      totalQuestions += result.totalQuestions;
      totalCorrect += result.score;
      if (result.percentage > bestScore) {
        bestScore = result.percentage;
      }
      testsByEvent[result.eventName] =
          (testsByEvent[result.eventName] ?? 0) + 1;
    }

    return {
      'totalTests': totalTests,
      'averageScore': totalPercentage / totalTests,
      'totalQuestions': totalQuestions,
      'totalCorrect': totalCorrect,
      'bestScore': bestScore,
      'testsByEvent': testsByEvent,
    };
  }

  // Get user's results by event
  Stream<List<TestResultModel>> getUserResultsByEvent(
    String userId,
    String eventName,
  ) {
    return _firestore
        .collection('test_results')
        .where('userId', isEqualTo: userId)
        .where('eventName', isEqualTo: eventName)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TestResultModel.fromFirestore(doc))
              .toList(),
        );
  }
}
