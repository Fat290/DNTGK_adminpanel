import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersControllerProvider);
    final authAsync = ref.watch(authStateChangesProvider);
    return Scaffold(
      body: SafeArea(
        child: usersAsync.when(
          data: (users) => _DashboardBody(
            users: users,
            greetingName: authAsync.asData?.value?.displayName ??
                (authAsync.asData?.value?.email?.split('@').first ?? 'Admin'),
            photoUrl: authAsync.asData?.value?.photoURL,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.users, required this.greetingName, this.photoUrl});
  final List<AppUser> users;
  final String greetingName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    // No role/active anymore. Show total and createdAt trend.

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(greetingName: greetingName, photoUrl: photoUrl),
          const SizedBox(height: 16),
          _BigStatCard(
            label: 'Tổng user',
            value: users.length.toString(),
            icon: Icons.people,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

}

class _Header extends StatelessWidget {
  const _Header({required this.greetingName, this.photoUrl});
  final String greetingName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return
       Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WELCOME BACK', style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                  const SizedBox(height: 4),
                  Text("ADMIN", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            CircleAvatar(
              radius: 24,
              backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
          ],
        ),
      );

  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  const _BigStatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: onColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}


