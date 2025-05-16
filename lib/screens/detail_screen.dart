import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rupa_nusa/models/culture.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final culture = ModalRoute.of(context)!.settings.arguments as Culture;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(culture.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(culture.imageUrl, height: 200, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(culture.description),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('cultures').doc(culture.id).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final data = snapshot.data!.data() as Map;
                    final likes = data['likes'] ?? 0;
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('cultures').doc(culture.id).update({
                              'likes': likes + 1,
                            });
                            if (user != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('favorites')
                                  .doc(culture.id)
                                  .set({'cultureId': culture.id});
                            }
                          },
                        ),
                        Text('$likes Suka'),
                      ],
                    );
                  },
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('cultures').doc(culture.id).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final data = snapshot.data!.data() as Map;
                    final comments = List<String>.from(data['comments'] ?? []);
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.comment),
                          onPressed: () {
                            final commentController = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Tambah Komentar'),
                                content: TextField(controller: commentController),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      if (commentController.text.isNotEmpty) {
                                        comments.add(commentController.text);
                                        await FirebaseFirestore.instance
                                            .collection('cultures')
                                            .doc(culture.id)
                                            .update({'comments': comments});
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text('Kirim'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Text('${comments.length} Komentar'),
                      ],
                    );
                  },
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Komentar'),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('cultures').doc(culture.id).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final data = snapshot.data!.data() as Map;
                final comments = List<String>.from(data['comments'] ?? []);
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(comments[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}