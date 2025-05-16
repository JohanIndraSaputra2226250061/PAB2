import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rupa_nusa/models/culture.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: user == null
          ? const Center(child: Text('Silakan masuk untuk melihat favorit'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('favorites')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final favoriteDocs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: favoriteDocs.length,
                  itemBuilder: (context, index) {
                    final favorite = favoriteDocs[index];
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('cultures')
                          .doc(favorite['cultureId'])
                          .snapshots(),
                      builder: (context, cultureSnapshot) {
                        if (!cultureSnapshot.hasData) return const SizedBox();
                        final culture = Culture.fromFirestore(cultureSnapshot.data!);
                        return ListTile(
                          leading: Image.network(culture.imageUrl, width: 50, fit: BoxFit.cover),
                          title: Text(culture.title),
                          onTap: () => Navigator.pushNamed(context, '/detail', arguments: culture),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}