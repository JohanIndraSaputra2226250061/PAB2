import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  Future<void> _signUp(BuildContext context, String email, String password, String username, String phone) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'username': username,
          'phone': phone,
        });
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal Daftar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final usernameController = TextEditingController();
    final phoneController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Nama Pengguna'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Telepon'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Kata Sandi'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _signUp(
                context,
                emailController.text,
                passwordController.text,
                usernameController.text,
                phoneController.text,
              ),
              child: const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}