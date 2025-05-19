import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rupa_nusa/models/culture.dart';
import 'package:rupa_nusa/models/comment.dart';
import 'package:intl/intl.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isLiking = false; // Untuk mencegah spam klik

  Future<void> _toggleLike(Culture culture) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isLiking) return;

    setState(() {
      _isLiking = true;
    });

    final cultureRef = FirebaseFirestore.instance.collection('cultures').doc(culture.id);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final cultureSnapshot = await transaction.get(cultureRef);
        if (!cultureSnapshot.exists) {
          throw Exception('Culture tidak ditemukan');
        }

        final data = cultureSnapshot.data()!;
        final likes = Map<String, dynamic>.from(data['likes'] ?? {});
        final int currentLikeCount = data['likeCount'] ?? 0;
        final hasLiked = likes[user.uid] ?? false;

        if (hasLiked) {
          // Unlike
          likes.remove(user.uid);
          final newLikeCount = currentLikeCount - 1;
          if (newLikeCount < 0) {
            throw Exception('Like count cannot be negative');
          }
          transaction.update(cultureRef, {
            'likes': likes,
            'likeCount': newLikeCount,
          });

          // Hapus dari favorites jika ada
          final favoriteQuery = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .where('cultureId', isEqualTo: culture.id)
              .get();
          for (var doc in favoriteQuery.docs) {
            transaction.delete(doc.reference);
          }
        } else {
          // Like
          likes[user.uid] = true;
          transaction.update(cultureRef, {
            'likes': likes,
            'likeCount': currentLikeCount + 1,
          });

          // Tambah ke favorites
          final favoriteRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .doc();
          transaction.set(favoriteRef, {
            'cultureId': culture.id,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah like: $e')),
      );
    } finally {
      setState(() {
        _isLiking = false;
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
    final Culture cultureArg = ModalRoute.of(context)!.settings.arguments as Culture;
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('cultures').doc(cultureArg.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Terjadi kesalahan: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Budaya tidak ditemukan')),
          );
        }

        final cultureData = snapshot.data!.data() as Map<String, dynamic>;
        final culture = Culture(
          id: cultureArg.id,
          title: cultureData['title'] ?? '',
          description: cultureData['description'] ?? '',
          imageUrl: cultureData['imageUrl'] ?? '',
          category: cultureData['category'] ?? '',
          location: cultureData['location'] ?? '',
          locationUrl: cultureData['locationUrl'] ?? '',
          likes: Map<String, bool>.from(cultureData['likes'] ?? {}),
          likeCount: cultureData['likeCount'] ?? 0,
        );

        final hasLiked = user != null && (culture.likes[user.uid] ?? false);
        final TextEditingController commentController = TextEditingController();

        return Scaffold(
          appBar: AppBar(
            title: Text(culture.title),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                  ),
                  child: Image.network(
                    culture.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        culture.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category and Location
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.category,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  culture.category,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_pin,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  culture.location,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Like Button
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              hasLiked ? Icons.favorite : Icons.favorite_border,
                              color: hasLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: (user == null || _isLiking)
                                ? null
                                : () => _toggleLike(culture),
                          ),
                          Text(
                            '${culture.likeCount} Likes',
                            style: TextStyle(
                              color: hasLiked ? Colors.red : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Description Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Deskripsi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              culture.description,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Comments Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.comment_outlined, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'Komentar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('cultures')
                                  .doc(culture.id)
                                  .collection('comments')
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Card(
                                    color: Colors.red.shade50,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text('Terjadi kesalahan: ${snapshot.error}'),
                                    ),
                                  );
                                }

                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return const Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'Belum ada komentar. Jadilah yang pertama berkomentar!',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }

                                final comments = snapshot.data!.docs.map((doc) => Comment.fromFirestore(doc)).toList();

                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: comments.length,
                                  separatorBuilder: (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final comment = comments[index];
                                    String formattedDate = '';
                                    try {
                                      formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(comment.timestamp.toDate());
                                    } catch (e) {
                                      formattedDate = 'Waktu tidak tersedia';
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: Colors.grey.shade300,
                                                child: Text(
                                                  comment.username.isNotEmpty ? comment.username[0].toUpperCase() : 'A',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
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
                                                          formattedDate,
                                                          style: TextStyle(
                                                            color: Colors.grey.shade600,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      comment.comment,
                                                      style: const TextStyle(height: 1.3),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),

                            // Add Comment Section
                            if (user != null) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              const Text(
                                'Tambah Komentar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: commentController,
                                decoration: InputDecoration(
                                  hintText: 'Tulis komentar Anda...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.blue),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (commentController.text.isNotEmpty) {
                                      _addComment(culture, commentController.text);
                                      commentController.clear();
                                    }
                                  },
                                  icon: const Icon(Icons.send),
                                  label: const Text('Kirim Komentar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}