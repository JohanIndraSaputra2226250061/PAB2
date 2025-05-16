import 'package:cloud_firestore/cloud_firestore.dart';

class Culture {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  int likes;
  List<String> comments;

  Culture({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.likes = 0,
    this.comments = const [],
  });

  factory Culture.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Culture(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      likes: data['likes'] ?? 0,
      comments: List<String>.from(data['comments'] ?? []),
    );
  }
}