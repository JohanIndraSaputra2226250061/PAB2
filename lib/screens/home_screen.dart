import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rupa_nusa/models/culture.dart';
import 'detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RupaNusa')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('cultures').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final cultures = snapshot.data!.docs.map((doc) => Culture.fromFirestore(doc)).toList();
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: cultures.length,
            itemBuilder: (context, index) {
              final culture = cultures[index];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/detail', arguments: culture),
                child: Card(
                  child: Column(
                    children: [
                      Image.network(culture.imageUrl, height: 100, fit: BoxFit.cover),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(culture.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorit'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/favorites');
          if (index == 2) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }
}