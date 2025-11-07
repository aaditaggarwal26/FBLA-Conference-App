import 'package:cloud_firestore/cloud_firestore.dart';

class PinModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String pinName;
  final String description;
  final List<String> imageUrls;
  final String wantInReturn; // What they want to trade for
  final bool isOpenToOffers; // If they're open to any offer
  final DateTime createdAt;
  final bool isAvailable;
  final Map<String, dynamic> contactInfo; // User-controlled visibility

  PinModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.pinName,
    required this.description,
    required this.imageUrls,
    required this.wantInReturn,
    this.isOpenToOffers = true,
    required this.createdAt,
    this.isAvailable = true,
    this.contactInfo = const {},
  });

  factory PinModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PinModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      pinName: data['pinName'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      wantInReturn: data['wantInReturn'] ?? '',
      isOpenToOffers: data['isOpenToOffers'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isAvailable: data['isAvailable'] ?? true,
      contactInfo: Map<String, dynamic>.from(data['contactInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'pinName': pinName,
      'description': description,
      'imageUrls': imageUrls,
      'wantInReturn': wantInReturn,
      'isOpenToOffers': isOpenToOffers,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAvailable': isAvailable,
      'contactInfo': contactInfo,
    };
  }
}
