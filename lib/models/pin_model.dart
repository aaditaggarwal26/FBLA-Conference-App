import 'package:cloud_firestore/cloud_firestore.dart';

class PinModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String pinName;
  final List<String> imageUrls;
  final String? wantInReturn;
  final bool isOpenToOffers;
  final bool isAvailableForTrade;
  final List<String> interestedUserIds;
  final DateTime createdAt;

  PinModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.pinName,
    this.imageUrls = const [],
    this.wantInReturn,
    this.isOpenToOffers = false,
    this.isAvailableForTrade = false,
    this.interestedUserIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Backwards compatibility
  String get name => pinName;
  String get ownerId => userId;
  String get ownerName => userName;

  factory PinModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PinModel(
      id: doc.id,
      userId: data['userId'] ?? data['ownerId'] ?? '',
      userName: data['userName'] ?? data['ownerName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      pinName: data['pinName'] ?? data['name'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      wantInReturn: data['wantInReturn'],
      isOpenToOffers: data['isOpenToOffers'] ?? false,
      isAvailableForTrade: data['isAvailableForTrade'] ?? false,
      interestedUserIds: List<String>.from(data['interestedUserIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'pinName': pinName,
      'imageUrls': imageUrls,
      'wantInReturn': wantInReturn,
      'isOpenToOffers': isOpenToOffers,
      'isAvailableForTrade': isAvailableForTrade,
      'interestedUserIds': interestedUserIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PinModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? pinName,
    List<String>? imageUrls,
    String? wantInReturn,
    bool? isOpenToOffers,
    bool? isAvailableForTrade,
    List<String>? interestedUserIds,
    DateTime? createdAt,
  }) {
    return PinModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      pinName: pinName ?? this.pinName,
      imageUrls: imageUrls ?? this.imageUrls,
      wantInReturn: wantInReturn ?? this.wantInReturn,
      isOpenToOffers: isOpenToOffers ?? this.isOpenToOffers,
      isAvailableForTrade: isAvailableForTrade ?? this.isAvailableForTrade,
      interestedUserIds: interestedUserIds ?? this.interestedUserIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
