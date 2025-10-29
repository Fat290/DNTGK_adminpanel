import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  File? _imageFile;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _addUser() async {
    try {
      await _firestore.collection('users').add({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'image': _imageFile?.path ?? '', // chỉ lưu path local
      });

      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      setState(() => _imageFile = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm người dùng thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thêm: $e')),
      );
    }
  }

  Future<void> _deleteUser(String id) async {
    await _firestore.collection('users').doc(id).delete();
  }

  Future<void> _updateUser(
      String id,
      String username,
      String email,
      String password,
      String image,
      ) async {
    _usernameController.text = username;
    _emailController.text = email;
    _passwordController.text = password;
    _imageFile = null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cập nhật người dùng'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 10),
              _imageFile != null
                  ? Image.file(_imageFile!, height: 100)
                  : (image.isNotEmpty
                  ? Image.file(File(image), height: 100, errorBuilder: (_, __, ___) => const Icon(Icons.person))
                  : const Icon(Icons.person, size: 100, color: Colors.grey)),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Chọn ảnh mới'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('users').doc(id).update({
                'username': _usernameController.text.trim(),
                'email': _emailController.text.trim(),
                'password': _passwordController.text.trim(),
                'image': _imageFile?.path ?? image,
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Admin - Firestore CRUD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Form thêm user
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Thêm người dùng', style: Theme.of(context).textTheme.titleMedium),
                    TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
                    TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                    TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _imageFile != null
                            ? Image.file(_imageFile!, width: 80, height: 80, fit: BoxFit.cover)
                            : const Icon(Icons.image, size: 60, color: Colors.grey),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.upload),
                          label: const Text('Chọn ảnh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addUser,
                      child: const Text('Thêm người dùng'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Danh sách users
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi Firestore: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snapshot.data!.docs;
                  if (users.isEmpty) {
                    return const Center(child: Text('Chưa có người dùng nào'));
                  }
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final doc = users[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: data['image'] != ''
                              ? Image.file(
                            File(data['image']),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person),
                          )
                              : const Icon(Icons.person, size: 50),
                          title: Text(data['username'] ?? ''),
                          subtitle: Text(data['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _updateUser(
                                  doc.id,
                                  data['username'],
                                  data['email'],
                                  data['password'],
                                  data['image'],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteUser(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

