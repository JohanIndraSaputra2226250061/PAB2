import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rupa_nusa/models/user.dart';
import './setting_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Silakan masuk untuk melihat profil'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final appUser = AppUser.fromFirestore(snapshot.data!);
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                      const SizedBox(height: 20),
                      Text('Nama Pengguna: ${appUser.username}'),
                      Text('Email: ${appUser.email}'),
                      Text('Telepon: ${appUser.phone}'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}