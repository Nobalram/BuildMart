import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a buyer's profile document stored at:
/// users/{uid}
class AppUser {
  final String uid;
  final String phoneNumber;
  final String name;
  final String? email;
  final String? photoUrl;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    this.email,
    this.photoUrl,
    required this.createdAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      phoneNumber: data['phoneNumber'] ?? '',
      name: data['name'] ?? '',
      email: data['email'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
