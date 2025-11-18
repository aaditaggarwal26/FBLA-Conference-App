import 'package:cloud_firestore/cloud_firestore.dart';

enum JoinRequestStatus { pending, approved, rejected }

class SchoolJoinRequestModel {
  final String id;
  final String schoolId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final DateTime requestedAt;
  final JoinRequestStatus status;
  final String? reviewedBy; // Admin who approved/rejected
  final DateTime? reviewedAt;
  final String? rejectionReason;

  SchoolJoinRequestModel({
    required this.id,
    required this.schoolId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    required this.requestedAt,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  factory SchoolJoinRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolJoinRequestModel(
      id: doc.id,
      schoolId: data['schoolId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      status: JoinRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => JoinRequestStatus.pending,
      ),
      reviewedBy: data['reviewedBy'],
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'schoolId': schoolId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhotoUrl': userPhotoUrl,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status.name,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  SchoolJoinRequestModel copyWith({
    JoinRequestStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return SchoolJoinRequestModel(
      id: id,
      schoolId: schoolId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhotoUrl: userPhotoUrl,
      requestedAt: requestedAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
