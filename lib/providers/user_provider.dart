import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/firebase_service.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());

final usersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(firebaseServiceProvider).streamUsers();
});

class UserSearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final userSearchQueryProvider = NotifierProvider<UserSearchQueryController, String>(UserSearchQueryController.new);

class UsersController extends Notifier<AsyncValue<List<AppUser>>> {
  @override
  AsyncValue<List<AppUser>> build() {
    state = const AsyncValue.loading();
    ref.listen<AsyncValue<List<AppUser>>>(
      usersStreamProvider,
      (previous, next) {
        state = next;
      },
      fireImmediately: true,
    );
    return state;
  }

  Future<void> addUser(AppUser user) async {
    await ref.read(firebaseServiceProvider).createUser(user.toJson());
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await ref.read(firebaseServiceProvider).updateUser(id, data);
  }

  Future<void> deleteUser(String id) async {
    await ref.read(firebaseServiceProvider).deleteUser(id);
  }

}

final usersControllerProvider = NotifierProvider<UsersController, AsyncValue<List<AppUser>>>(UsersController.new);


