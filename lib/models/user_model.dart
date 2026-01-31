import 'package:cloud_firestore/cloud_firestore.dart';

// User model class representing a registered user in the app
class UserModel {
  final String id;
  final String fullName;
  final String username;
  final String phone;
  final String email;

  // URL to user's profile photo (nullable)
  final String? photoUrl;

  // Firebase Cloud Messaging token for push notifications
  final String? fcmToken;

  // Account creation timestamp
  final DateTime createdAt;

  /// Constructor
  UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.phone,
    required this.email,
    this.photoUrl,
    this.fcmToken,
    required this.createdAt,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      username: data['username'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create UserModel from Map (useful for local operations)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      fcmToken: map['fcmToken'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'username': username,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? fullName,
    String? username,
    String? phone,
    String? email,
    String? photoUrl,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get first name from full name
  String get firstName => fullName.split(' ').first;

  /// Get initials for avatar placeholder
  String get initials {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  @override
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, username: $username)';
  }
}
