import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rupa_nusa/models/culture.dart';
import 'package:rupa_nusa/models/comment.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isLiking = false; // Untuk mencegah spam klik
  final ScrollController _scrollController = ScrollController();

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

  void _shareContent(Culture culture) {
    Share.share(
      'Lihat "${culture.title}" dari kategori ${culture.category} di RupaNusa! Lokasi: ${culture.location}',
    );
  }

  void _scrollToComments() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Culture cultureArg = ModalRoute.of(context)!.settings.arguments as Culture;
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('cultures').doc(cultureArg.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60,
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Budaya tidak ditemukan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kembali'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () => _shareContent(culture),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _scrollToComments,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.comment),
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image with Gradient Overlay
                Stack(
                  children: [
                    // Image
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                      ),
                      child: Image.network(
                        culture.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 300,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                    // Gradient Overlay
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                    // Title and Category on Image
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              culture.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            culture.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats and Actions Row
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Like Button
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    hasLiked ? Icons.favorite : Icons.favorite_border,
                                    color: hasLiked ? Colors.red : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                    size: 28,
                                  ),
                                  onPressed: (user == null || _isLiking)
                                      ? null
                                      : () => _toggleLike(culture),
                                ),
                                Text(
                                  '${culture.likeCount}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: hasLiked ? Colors.red : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Suka',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            // Location
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.location_on,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    // Implementasi navigasi ke peta
                                  },
                                ),
                                Text(
                                  culture.location.split(',').first,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lokasi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            // Share
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.share,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                  onPressed: () => _shareContent(culture),
                                ),
                                Text(
                                  'Bagikan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Konten',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Tentang ${culture.title}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              culture.description,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: isDarkMode ? Colors.grey[300] : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Comments Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[850] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.comment_outlined,
                                        color: Colors.purple,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Diskusi',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('cultures')
                                      .doc(culture.id)
                                      .collection('comments')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    int commentCount = 0;
                                    if (snapshot.hasData) {
                                      commentCount = snapshot.data!.docs.length;
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$commentCount Komentar',
                                        style: const TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('cultures')
                                  .doc(culture.id)
                                  .collection('comments')
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(
                                        color: Colors.orange,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.red),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Terjadi kesalahan: ${snapshot.error}',
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 40,
                                          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Belum ada komentar',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Jadilah yang pertama berkomentar!',
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final comments = snapshot.data!.docs.map((doc) => Comment.fromFirestore(doc)).toList();

                                return Column(
                                  children: [
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: comments.length,
                                      separatorBuilder: (context, index) => Divider(
                                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                        height: 32,
                                      ),
                                      itemBuilder: (context, index) {
                                        final comment = comments[index];
                                        String formattedDate = '';
                                        try {
                                          formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(comment.timestamp.toDate());
                                        } catch (e) {
                                          formattedDate = 'Waktu tidak tersedia';
                                        }

                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: _getAvatarColor(comment.username),
                                              child: Text(
                                                comment.username.isNotEmpty ? comment.username[0].toUpperCase() : 'A',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 16,
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
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: isDarkMode ? Colors.white : Colors.black,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        formattedDate,
                                                        style: TextStyle(
                                                          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      comment.comment,
                                                      style: TextStyle(
                                                        height: 1.4,
                                                        color: isDarkMode ? Colors.grey[300] : Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),

                            // Add Comment Section
                            if (user != null) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.orange,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Tambahkan Komentar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: commentController,
                                decoration: InputDecoration(
                                  hintText: 'Tulis komentar Anda...',
                                  filled: true,
                                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.orange),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.send, color: Colors.orange),
                                    onPressed: () {
                                      if (commentController.text.isNotEmpty) {
                                        _addComment(culture, commentController.text);
                                        commentController.clear();
                                      }
                                    },
                                  ),
                                ),
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                maxLines: 3,
                                minLines: 1,
                              ),
                            ] else ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.orange),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Silakan login untuk menambahkan komentar',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(context, '/');
                                      },
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
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
  
  Color _getAvatarColor(String username) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.red,
    ];
    
    int hash = 0;
    for (var i = 0; i < username.length; i++) {
      hash = username.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    return colors[hash.abs() % colors.length];
  }
}
