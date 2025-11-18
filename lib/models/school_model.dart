import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolModel {
  final String id;
  final String name;
  final String abbreviation; // e.g., "THS" for "Thomas High School"
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String ownerId; // User who created the school
  final List<String> adminIds; // School admins
  final List<String> memberIds; // Students in the school
  final DateTime createdAt;
  final String? logoUrl;
  final String? description;
  final String joinCode; // 6-digit code for students to join
  final bool requireApproval; // Whether join requests need admin approval

  SchoolModel({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.ownerId,
    required this.adminIds,
    required this.memberIds,
    required this.createdAt,
    this.logoUrl,
    this.description,
    required this.joinCode,
    this.requireApproval = true,
  });

  factory SchoolModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolModel(
      id: doc.id,
      name: data['name'] ?? '',
      abbreviation: data['abbreviation'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      zipCode: data['zipCode'] ?? '',
      ownerId: data['ownerId'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      logoUrl: data['logoUrl'],
      description: data['description'],
      joinCode: data['joinCode'] ?? '',
      requireApproval: data['requireApproval'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'abbreviation': abbreviation,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'ownerId': ownerId,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'logoUrl': logoUrl,
      'description': description,
      'joinCode': joinCode,
      'requireApproval': requireApproval,
    };
  }

  bool isOwner(String userId) => ownerId == userId;
  bool isAdmin(String userId) => adminIds.contains(userId) || isOwner(userId);
  bool isMember(String userId) => memberIds.contains(userId);
}
