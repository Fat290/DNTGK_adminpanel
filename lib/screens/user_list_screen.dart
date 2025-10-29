import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../providers/user_provider.dart';
import '../widgets/user_tile.dart';
import 'user_edit_screen.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersControllerProvider);
    final query = ref.watch(userSearchQueryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm kiếm theo tên hoặc email',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (v) => ref.read(userSearchQueryProvider.notifier).set(v.toLowerCase()),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filtered = users.where((u) =>
                    u.username.toLowerCase().contains(query) || u.email.toLowerCase().contains(query)).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('Không có user'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return UserTile(
                      user: user,
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => UserEditScreen(existing: user)),
                      ),
                      onDelete: () async {
                        final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Xóa user?'),
                                content: Text('Bạn có chắc muốn xóa ${user.username}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
                                ],
                              ),
                            ) ??
                            false;
                        if (ok) {
                          await ref.read(usersControllerProvider.notifier).deleteUser(user.id);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}


