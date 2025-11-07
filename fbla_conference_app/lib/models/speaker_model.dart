import 'package:cloud_firestore/cloud_firestore.dart';

class SpeakerModel {
  final String id;
  final String name;
  final String title;
  final String bio;
  final String? photoUrl;
  final String? company;
  final List<String> socialLinks;
  final List<String> sessionIds;

  SpeakerModel({
    required this.id,
    required this.name,
    required this.title,
    required this.bio,
    this.photoUrl,
    this.company,
    required this.socialLinks,
    required this.sessionIds,
  });

  factory SpeakerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpeakerModel(
      id: doc.id,
      name: data['name'] ?? '',
      title: data['title'] ?? '',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'],
      company: data['company'],
      socialLinks: List<String>.from(data['socialLinks'] ?? []),
      sessionIds: List<String>.from(data['sessionIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'title': title,
      'bio': bio,
      'photoUrl': photoUrl,
      'company': company,
      'socialLinks': socialLinks,
      'sessionIds': sessionIds,
    };
  }
}
