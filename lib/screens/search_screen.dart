import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rupa_nusa/models/culture.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<String> searchHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: 'Cari...'),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                searchHistory.add(value);
              });
            }
          },
        ),
      ),
      body: Column(
        children: [
          if (searchHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Riwayat Pencarian'),
                  Wrap(
                    children: searchHistory
                        .map((query) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Chip(label: Text(query)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('cultures').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final cultures = snapshot.data!.docs
                    .map((doc) => Culture.fromFirestore(doc))
                    .where((culture) =>
                        culture.title.toLowerCase().contains(_searchController.text.toLowerCase()))
                    .toList();
                return ListView.builder(
                  itemCount: cultures.length,
                  itemBuilder: (context, index) {
                    final culture = cultures[index];
                    return ListTile(
                      leading: Image.network(culture.imageUrl, width: 50, fit: BoxFit.cover),
                      title: Text(culture.title),
                      onTap: () => Navigator.pushNamed(context, '/detail', arguments: culture),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}