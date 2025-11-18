import 'question_model.dart';

class PracticeTestModel {
  final String id;
  final String title;
  final String eventName;
  final String description;
  final List<QuestionModel> questions;
  final int timeLimitMinutes; // Optional time limit

  PracticeTestModel({
    required this.id,
    required this.title,
    required this.eventName,
    required this.description,
    required this.questions,
    this.timeLimitMinutes = 60,
  });

  int get totalQuestions => questions.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'eventName': eventName,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'timeLimitMinutes': timeLimitMinutes,
    };
  }

  factory PracticeTestModel.fromMap(Map<String, dynamic> map) {
    return PracticeTestModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      eventName: map['eventName'] ?? '',
      description: map['description'] ?? '',
      questions:
          (map['questions'] as List<dynamic>?)
              ?.map((q) => QuestionModel.fromMap(q as Map<String, dynamic>))
              .toList() ??
          [],
      timeLimitMinutes: map['timeLimitMinutes'] ?? 60,
    );
  }
}
