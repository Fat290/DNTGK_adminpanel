import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_user.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserEditScreen extends ConsumerStatefulWidget {
  const UserEditScreen({super.key, this.existing});
  final AppUser? existing;

  @override
  ConsumerState<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends ConsumerState<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Uint8List? _avatarBytes;
  String? _avatarBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _nameController.text = ex.username;
      _emailController.text = ex.email;
      _avatarBase64 = ex.avatarUrl;
      // Prefill password from Firestore if present
      FirebaseFirestore.instance.collection('users').doc(ex.id).get().then((doc){
        final data = doc.data();
        final pwd = data != null ? (data['password'] as String?) : null;
        if (pwd != null) {
          _passwordController.text = pwd;
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final username = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (!emailReg.hasMatch(email)) {
      CustomSnackbar.show(context, 'Email không hợp lệ',type: SnackType.error);
      setState(() => _saving = false);
      return;
    }

    final isCreate = widget.existing == null;
    final taken = await ref.read(firebaseServiceProvider).isUsernameTaken(username, excludeUserId: widget.existing?.id);
    if (taken) {
      CustomSnackbar.show(context, 'Username đã tồn tại',type: SnackType.error);
      setState(() => _saving = false);
      return;
    }
    final emailTaken = await ref.read(firebaseServiceProvider).isEmailTaken(email,excludeEmailId: widget.existing?.id);
    if (emailTaken) {
      CustomSnackbar.show(context, 'Email đã tồn tại',type: SnackType.error);
      setState(() => _saving = false);
      return;
    }
    try {
      if (isCreate) {
        await ref.read(firebaseServiceProvider).createUser({
          'username': username,
          'email': email,
          'avatarUrl': _avatarBase64,
          'password': _passwordController.text.trim(),
        });
        CustomSnackbar.show(context, 'Tạo user thành công', type: SnackType.success);
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        setState(() {
          _avatarBytes = null;
          _avatarBase64 = null;
        });
      } else {
        final updateData = <String, dynamic>{
          'username': username,
          'email': email,
        };
        final newPassword = _passwordController.text.trim();
        if (newPassword.isNotEmpty) {
          updateData['password'] = newPassword;
        }
        if (_avatarBase64 != null) {
          updateData['avatarUrl'] = _avatarBase64;
        }
        await ref.read(usersControllerProvider.notifier).updateUser(widget.existing!.id, updateData);
        CustomSnackbar.show(context, 'Cập nhật user thành công', type: SnackType.success);
      }
    } catch (e) {
      CustomSnackbar.show(context, 'Lỗi: ${e.toString()}');
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.existing == null ? 'Thêm người dùng' : 'Chỉnh sửa người dùng',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Card(
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: borderColor, width: 0.8),
                ),
                elevation: isDark ? 0 : 4,
                shadowColor: Colors.black12,
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              if (bytes.lengthInBytes > 900 * 1024) {
                                CustomSnackbar.show(context, 'Ảnh quá lớn (>900KB). Vui lòng chọn ảnh nhỏ hơn.', type: SnackType.error);
                                return;
                              }
                              setState(() {
                                _avatarBytes = bytes;
                                _avatarBase64 = base64Encode(bytes);
                              });
                            }
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                backgroundImage: _avatarBytes != null
                                    ? MemoryImage(_avatarBytes!)
                                    : (widget.existing?.avatarUrl != null
                                        ? (widget.existing!.avatarUrl!.startsWith('http')
                                            ? NetworkImage(widget.existing!.avatarUrl!)
                                            : ((){
                                                try {
                                                  final bytes = base64Decode(widget.existing!.avatarUrl!);
                                                  return MemoryImage(bytes);
                                                } catch (_) { return null; }
                                              })())
                                        : null),
                                child: (_avatarBytes == null &&
                                    (widget.existing?.avatarUrl == null || widget.existing!.avatarUrl!.isEmpty))
                                    ? Icon(Icons.person_outline,
                                    size: 48, color: Colors.grey[400])
                                    : null,
                              ),
                              Positioned(
                                bottom: 2,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                  isDark ? Colors.blueAccent : Colors.blue,
                                  child: const Icon(Icons.edit,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
              
                        const SizedBox(height: 20),
              
                        // Username
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: const Icon(Icons.person_outline),
                            labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
                            filled: true,
                            fillColor:
                            isDark ? Colors.grey[850] : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                              BorderSide(color: Colors.blueAccent, width: 1.5),
                            ),
                          ),
                          validator: (v) =>
                          v == null || v.isEmpty ? 'Nhập username' : null,
                        ),
              
                        const SizedBox(height: 16),
              
                        // Email
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
                            filled: true,
                            fillColor:
                            isDark ? Colors.grey[850] : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                              BorderSide(color: Colors.blueAccent, width: 1.5),
                            ),
                          ),
                          validator: (v) =>
                          v == null || v.isEmpty ? 'Nhập email' : null,
                        ),
              

                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            style: TextStyle(color: textColor),
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline),
                              labelStyle:
                              TextStyle(color: textColor.withOpacity(0.8)),
                              filled: true,
                              fillColor:
                              isDark ? Colors.grey[850] : Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: Colors.blueAccent, width: 1.5),
                              ),
                            ),
                            validator: (v) => v!.length < 6
                                ? 'Mật khẩu phải ít nhất 6 ký tự'
                                : null,
                          ),

              
                        const SizedBox(height: 28),
              
                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Icon(Icons.save_outlined,
                                color: Colors.white),
                            label: Text(
                              _saving
                                  ? 'Đang lưu...'
                                  : widget.existing == null
                                  ? 'Tạo người dùng'
                                  : 'Lưu thay đổi',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              _saving ? Colors.grey : Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
