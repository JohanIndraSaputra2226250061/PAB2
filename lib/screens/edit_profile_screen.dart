import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rupa_nusa/models/user.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser appUser;

  const EditProfileScreen({super.key, required this.appUser});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  File? _imageFile;
  Uint8List? _webImageBytes; 
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.appUser.username;
    _phoneController.text = widget.appUser.phone;
    _profileImageUrl = widget.appUser.profileImageUrl;
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Untuk platform web
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _webImageBytes = result.files.single.bytes;
            _imageFile = null; // Reset _imageFile untuk platform web
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Gagal memilih gambar: $e';
        });
      }
    } else {
      // Untuk platform mobile
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImageBytes = null; // Reset _webImageBytes untuk platform mobile
        });
      }
    }
  }

  Future<String?> _uploadImageToStorage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');

      if (kIsWeb) {
        if (_webImageBytes == null) return null;
        // Unggah gambar di web menggunakan bytes
        final uploadTask = await storageRef.putData(_webImageBytes!);
        return await uploadTask.ref.getDownloadURL();
      } else {
        if (_imageFile == null) return null;
        // Unggah gambar di mobile menggunakan file
        final uploadTask = await storageRef.putFile(_imageFile!);
        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengunggah gambar: $e';
      });
      return null;
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Pengguna tidak ditemukan';
        _isLoading = false;
      });
      return;
    }

    try {
      String? newImageUrl = _profileImageUrl;
      if (_imageFile != null || _webImageBytes != null) {
        newImageUrl = await _uploadImageToStorage();
        if (newImageUrl == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profileImageUrl': newImageUrl ?? '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memperbarui profil: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
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
                      image: kIsWeb && _webImageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_webImageBytes!),
                              fit: BoxFit.cover,
                            )
                          : _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(_profileImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                    ),
                    child: (_imageFile == null && _webImageBytes == null) &&
                            (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          )
                        : null,
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Nomor Telepon',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Simpan Perubahan',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}