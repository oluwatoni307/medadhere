// ============================================
// FILE: profile_screen.dart
// PATH: lib/features/profile/screens/profile_screen.dart
// LAYER: screen
// DOMAIN: profile
// RESPONSIBLE FOR: Profile screen skeleton — displays user name and email, sign out wired to AuthNotifier.
// RECEIVES: Nothing
// RETURNS: Scaffold with name, email, sign out button — loading and error states handled
// CONNECTS TO: auth_notifier_provider.dart, app_user.dart
// MUST NEVER: Import Firebase directly, navigate manually on sign out, contain styling decisions
// ============================================

// flutter
import 'package:flutter/material.dart';

// packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

// internal
import '../../../features/auth/state/auth_notifier_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: authState.when(
        loading: () => const _ProfileSkeleton(),
        error: (e, _) => _ProfileError(
          message: e.toString(),
          onRetry: () => ref.invalidate(authProvider),
        ),
        data: (appUser) {
          if (appUser == null) return const SizedBox.shrink();

          final displayName =
              appUser.displayName ?? appUser.email.split('@').first;

          return _ProfileLoaded(
            displayName: displayName,
            email: appUser.email,
            onSignOut: () => ref.read(authProvider.notifier).signOut(),
          );
        },
      ),
    );
  }
}

// ─── loaded state ─────────────────────────────────────────

class _ProfileLoaded extends StatelessWidget {
  const _ProfileLoaded({
    required this.displayName,
    required this.email,
    required this.onSignOut,
  });

  final String displayName;
  final String email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(displayName),
          Text(email),
          TextButton(onPressed: onSignOut, child: const Text('Sign Out')),
        ],
      ),
    );
  }
}

// ─── loading skeleton ─────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SkeletonBox(width: 120, height: 16),
          SizedBox(height: 8),
          _SkeletonBox(width: 180, height: 14),
          SizedBox(height: 16),
          _SkeletonBox(width: 80, height: 36),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: height, color: Colors.grey.shade300);
  }
}

// ─── error state ──────────────────────────────────────────

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Something went wrong: $message'),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
