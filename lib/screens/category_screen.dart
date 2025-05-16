import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ['Tarian Adat', 'Rumah Adat', 'Lagu Adat'];

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            title: Text(category),
            onTap: () {
              // Logika filter kategori bisa ditambahkan di sini
            },
          );
        },
      ),
    );
  }
}