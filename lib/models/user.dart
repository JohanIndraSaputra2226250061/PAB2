import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String email;
  final String username;
  final String phone;
  final String role;
  final String profileImageUrl; // Tambahkan field ini

  AppUser({
    required this.email,
    required this.username,
    required this.phone,
    required this.role,
    this.profileImageUrl = '',
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
    );
  }
}