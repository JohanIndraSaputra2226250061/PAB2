import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String email;
  final String username;
  final String phone;

  AppUser({
    required this.email,
    required this.username,
    required this.phone,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      email: data['email'] ?? '',
      username: data['username'] ?? 'Pengguna',
      phone: data['phone'] ?? '',
    );
  }
}