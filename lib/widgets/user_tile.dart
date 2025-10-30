import 'package:flutter/material.dart';
import 'dart:convert';

import '../models/app_user.dart';

class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user, required this.onEdit, required this.onDelete});

  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.avatarUrl == null
              ? null
              : (user.avatarUrl!.startsWith('http')
                  ? NetworkImage(user.avatarUrl!)
                  : ((){
                      try {
                        final bytes = base64Decode(user.avatarUrl!);
                        return MemoryImage(bytes);
                      } catch (_) { return null; }
                    })()),
          child: user.avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(user.username),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete), color: Theme.of(context).colorScheme.error),
          ],
        ),
      ),
    );
  }
}


