import 'package:firebase_auth/firebase_auth.dart'; // <-- Add this import
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp if needed

class AppUser {
  final String uid;
  final String email;
  final String role; // 'admin' or 'student'
  final String? name;
  final String? profileImage;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.profileImage,
    this.createdAt,
  });

  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      role: 'student', // Default role
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      name: data['name'],
      profileImage: data['profileImage'],
      // Handles Firestore Timestamp or null
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] is DateTime ? data['createdAt'] : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'profileImage': profileImage,
      // Store as Firestore Timestamp if not null for compatibility
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
