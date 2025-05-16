import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  String username;
  String phone;

  AppUser({
    required this.uid,
    required this.email,
    this.username = '',
    this.phone = '',
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      phone: data['phone'] ?? '',
    );
  }
}