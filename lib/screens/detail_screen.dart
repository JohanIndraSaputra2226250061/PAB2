import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rupa_nusa/models/culture.dart';
import 'package:rupa_nusa/models/comment.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  Future<void> _toggleLike(Culture culture) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cultureRef = FirebaseFirestore.instance.collection('cultures').doc(culture.id);
    final hasLiked = culture.likes[user.uid] ?? false;

    if (hasLiked) {
      // Unlike
      await cultureRef.update({
        'likes.${user.uid}': FieldValue.delete(),
        'likeCount': FieldValue.increment(-1),
      });
      // Hapus dari favorites jika ada
      final favoriteQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .where('cultureId', isEqualTo: culture.id)
          .get();
      for (var doc in favoriteQuery.docs) {
        await doc.reference.delete();
      }
    } else {
      // Like
      await cultureRef.update({
        'likes.${user.uid}': true,
        'likeCount': FieldValue.increment(1),
      });
      // Tambah ke favorites
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .add({
        'cultureId': culture.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _addComment(Culture culture, String commentText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final username = userDoc.exists ? (userDoc.data()!['username'] ?? 'Anonim') : 'Anonim';

    await FirebaseFirestore.instance
        .collection('cultures')
        .doc(culture.id)
        .collection('comments')
        .add({
      'userId': user.uid,
      'username': username,
      'comment': commentText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final Culture culture = ModalRoute.of(context)!.settings.arguments as Culture;
    final user = FirebaseAuth.instance.currentUser;
    final hasLiked = user != null && (culture.likes[user.uid] ?? false);

    final TextEditingController commentController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(culture.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              culture.imageUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 250,
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    culture.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        culture.category,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_pin,
                        size: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        culture.location,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          hasLiked ? Icons.favorite : Icons.favorite_border,
                          color: hasLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: user == null
                            ? null
                            : () => _toggleLike(culture),
                      ),
                      Text('${culture.likeCount} Likes'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    culture.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Komentar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cultures')
                        .doc(culture.id)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text('Terjadi kesalahan: ${snapshot.error}');
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('Belum ada komentar.');
                      }

                      final comments = snapshot.data!.docs.map((doc) => Comment.fromFirestore(doc)).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      comment.timestamp.toDate().toString(),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.comment),
                                const Divider(),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (user != null) ...[
                    const Text(
                      'Tambah Komentar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar Anda...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (commentController.text.isNotEmpty) {
                          _addComment(culture, commentController.text);
                          commentController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Kirim'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}