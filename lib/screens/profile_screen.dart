import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rupa_nusa/models/user.dart';
import 'edit_profile_screen.dart';
import 'setting_screen.dart';
import 'admin_posting_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle,
                size: 100,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              ),
              const SizedBox(height: 24),
              Text(
                'Silakan login untuk melihat profil',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
                strokeWidth: 3,
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'email': user.email ?? '',
              'username': user.displayName ?? 'Pengguna',
              'phone': '',
              'role': 'user',
              'profileImageUrl': '',
            }, SetOptions(merge: true));
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Membuat profil pengguna...',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
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
            );
          }

          final appUser = AppUser.fromFirestore(snapshot.data!);

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header with settings button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.settings_outlined,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            onPressed: () => Navigator.pushNamed(context, '/settings'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Profile Avatar
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[700]! : Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          image: appUser.profileImageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(appUser.profileImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: appUser.profileImageUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[900]! : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Username
                  Text(
                    appUser.username.isNotEmpty ? appUser.username : 'Pengguna',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  
                  // Role badge
                  if (appUser.role.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: appUser.role == 'admin' 
                            ? Colors.green.withOpacity(0.2) 
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appUser.role == 'admin' ? 'Admin' : 'User',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: appUser.role == 'admin' ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 30),
                  
                  // Profile Info Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      children: [
                        // Email
                        _buildProfileInfoItem(
                          context,
                          icon: Icons.email_outlined,
                          title: 'Email',
                          value: appUser.email.isNotEmpty ? appUser.email : 'Belum diatur',
                          isDarkMode: isDarkMode,
                        ),
                        
                        Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                        
                        // Phone
                        _buildProfileInfoItem(
                          context,
                          icon: Icons.phone_outlined,
                          title: 'Telepon',
                          value: appUser.phone.isNotEmpty ? appUser.phone : 'Belum diatur',
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Edit Profile Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/edit-profile',
                              arguments: appUser, // Tambahkan argumen di sini
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        
                        // Change Password Button
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/change-password'),
                            icon: const Icon(Icons.lock),
                            label: const Text('Ganti Password'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        
                        // Admin Posting Button (if admin)
                        if (appUser.role == 'admin') ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/admin-posting'),
                              icon: const Icon(Icons.admin_panel_settings),
                              label: const Text('Admin Posting'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 12),
                        
                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              // Show confirmation dialog
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Konfirmasi Logout'),
                                  content: const Text('Apakah Anda yakin ingin keluar?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (shouldLogout == true) {
                                await FirebaseAuth.instance.signOut();
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/',
                                  (Route<dynamic> route) => false,
                                );
                              }
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildProfileInfoItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}