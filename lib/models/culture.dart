import 'package:cloud_firestore/cloud_firestore.dart';

class Culture {
  final String id;
  final String title;
  final String imageUrl;
  final String category;
  final String location;
  final String description;
  final Map<String, bool> likes;
  final int likeCount;

  Culture({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.location,
    required this.description,
    this.likes = const {},
    this.likeCount = 0,
  });

  factory Culture.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Culture(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      likes: data['likes'] != null ? Map<String, bool>.from(data['likes']) : {},
      likeCount: data['likeCount'] ?? 0,
    );
  }
}