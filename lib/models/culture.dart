import 'package:cloud_firestore/cloud_firestore.dart';

class Culture {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String location;
  final String locationUrl;
  final Map<String, bool> likes; 
  final int likeCount; 

  Culture({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.location,
    required this.locationUrl,
    this.likes = const {},
    this.likeCount = 0,
  });

  factory Culture.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Culture(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      locationUrl: data['locationUrl'] ?? '',
      likes: Map<String, bool>.from(data['likes'] ?? {}),
      likeCount: data['likeCount'] ?? 0,
    );
  }
}
