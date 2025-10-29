import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

class FirebaseService {
  FirebaseService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get usersCollection => _firestore.collection('users');

  Stream<List<AppUser>> streamUsers() {
    return usersCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AppUser.fromJson(doc.data(), doc.id))
          .toList(),
    );
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    await usersCollection.add(data);
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await usersCollection.doc(id).update(data);
  }

  Future<void> deleteUser(String id) async {
    await usersCollection.doc(id).delete();
  }

  Future<bool> isUsernameTaken(String username, {String? excludeUserId}) async {
    final q = await usersCollection.where('username', isEqualTo: username).limit(1).get();
    if (q.docs.isEmpty) return false;
    if (excludeUserId == null) return true;
    return q.docs.first.id != excludeUserId;
  }
  Future<bool> isEmailTaken(String email, {String? excludeEmailId}) async {
    final q = await usersCollection.where('email', isEqualTo: email).limit(1).get();
    if (q.docs.isEmpty) return false;
    if (excludeEmailId == null) return true;
    return q.docs.first.id != excludeEmailId;
  }
}


