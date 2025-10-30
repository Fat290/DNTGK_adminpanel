import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
  });

  final String id;
  final String username;
  final String email;
  // Stores base64 string of avatar in the existing field name for compatibility
  final String? avatarUrl;

  factory AppUser.fromJson(Map<String, dynamic> json, String id) {
    return AppUser(
      id: id,
      username: json['username'] as String? ?? (json['name'] as String? ?? ''),
      email: json['email'] as String? ?? '',
  
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  AppUser copyWith({
    String? username,
    String? email,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}


