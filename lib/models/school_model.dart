import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolModel {
  final String id;
  final String name;
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? logoUrl;
  final String? bannerUrl;
  final List<String> adminIds; // UIDs of school admins
  final List<String> memberIds; // UIDs of students
  final String inviteCode; // Unique code for students to join
  final DateTime createdAt;
  final Map<String, String> socialMediaLinks; // platform: url
  final String? calendarUrl;
  final bool isActive;
  final Map<String, dynamic>? settings;

  SchoolModel({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
    this.logoUrl,
    this.bannerUrl,
    required this.adminIds,
    required this.memberIds,
    required this.inviteCode,
    required this.createdAt,
    required this.socialMediaLinks,
    this.calendarUrl,
    this.isActive = true,
    this.settings,
  });

  factory SchoolModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      city: data['city'],
      state: data['state'],
      zipCode: data['zipCode'],
      logoUrl: data['logoUrl'],
      bannerUrl: data['bannerUrl'],
      adminIds: List<String>.from(data['adminIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      inviteCode: data['inviteCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      socialMediaLinks: Map<String, String>.from(data['socialMediaLinks'] ?? {}),
      calendarUrl: data['calendarUrl'],
      isActive: data['isActive'] ?? true,
      settings: data['settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'socialMediaLinks': socialMediaLinks,
      'calendarUrl': calendarUrl,
      'isActive': isActive,
      'settings': settings,
    };
  }

  bool isAdmin(String userId) => adminIds.contains(userId);
  bool isMember(String userId) => memberIds.contains(userId);

  String get fullAddress {
    final parts = [address];
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (zipCode != null) parts.add(zipCode!);
    return parts.join(', ');
  }

  SchoolModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? logoUrl,
    String? bannerUrl,
    List<String>? adminIds,
    List<String>? memberIds,
    String? inviteCode,
    DateTime? createdAt,
    Map<String, String>? socialMediaLinks,
    String? calendarUrl,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      calendarUrl: calendarUrl ?? this.calendarUrl,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }
}
