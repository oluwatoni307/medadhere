// ============================================
// FILE: profile_screen.dart
// PATH: lib/features/profile/screens/profile_screen.dart
// LAYER: screen
// DOMAIN: profile
// RESPONSIBLE FOR: Profile screen — displays user name, email, active medication
//   count, and sign out. Medication count fetched via a scoped FutureProvider.
// RECEIVES: Nothing
// RETURNS: Scaffold with identity block, medication chip, detail rows, sign out
// CONNECTS TO: auth_notifier_provider.dart, app_user.dart,
//              medication_service_provider.dart
// MUST NEVER: Import Firebase directly, navigate manually on sign out,
//             call MedicationService directly from the widget tree,
//             contain styling decisions outside token references
// ============================================

// flutter
import 'package:flutter/material.dart';

// packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

// internal — auth
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/state/auth_notifier_provider.dart';
import '../../../shared/services/medication_service_provider.dart';

// ─── scoped provider ──────────────────────────────────────

final _activeMedicationCountProvider = FutureProvider.family<int, String>((
  ref,
  uid,
) async {
  final meds = await ref.read(medicationServiceProvider).getMedications(uid);
  return meds.length;
});

// ─── fallback constants ───────────────────────────────────

// Used whenever we can't safely derive a display name or initials from
// the authenticated user (e.g. displayName and email are both empty).
// Keeping these as named constants instead of inline literals makes the
// fallback intentional rather than an accidental empty string reaching
// widgets that assume non-empty text.
const String _kFallbackDisplayName = 'User';
const String _kFallbackInitials = '?';

// ─── screen ───────────────────────────────────────────────

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

          // appUser.displayName currently always resolves to null in
          // practice (it's sourced from Firebase Auth's native profile,
          // which this app never writes to — name changes are persisted
          // to Firestore instead). We still honor it if present in case
          // that ever changes upstream, but the real fallback path is
          // email — and email itself can be empty (see AuthService
          // ._mapToAppUser's `user.email ?? ''`), so we guard the final
          // result rather than trusting either source to be non-empty.
          final rawDisplayName =
              appUser.displayName ?? _localPartOf(appUser.email);
          final displayName = rawDisplayName.isEmpty
              ? _kFallbackDisplayName
              : rawDisplayName;

          final countAsync = ref.watch(
            _activeMedicationCountProvider(appUser.uid),
          );

          return _ProfileLoaded(
            displayName: displayName,
            email: appUser.email,
            medicationCount: countAsync,
            onSignOut: () => ref.read(authProvider.notifier).signOut(),
          );
        },
      ),
    );
  }

  // Safe local-part extraction — a malformed or empty email (no '@',
  // or empty string entirely) must never throw here.
  static String _localPartOf(String email) {
    if (email.isEmpty) return '';
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return email; // no '@' or leading '@': use as-is
    return email.substring(0, atIndex);
  }
}

// ─── loaded state ─────────────────────────────────────────

class _ProfileLoaded extends StatelessWidget {
  const _ProfileLoaded({
    required this.displayName,
    required this.email,
    required this.medicationCount,
    required this.onSignOut,
  });

  final String displayName;
  final String email;
  final AsyncValue<int> medicationCount;
  final VoidCallback onSignOut;

  // Hardened: previously threw RangeError on an empty string (parts.first[0]
  // with parts == ['']). Now every exit path returns a non-empty string,
  // and there is no path left that indexes into an empty String.
  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return _kFallbackInitials;

    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return _kFallbackInitials;

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Hardened: Theme.of(context).extension<AppTypography>() can return
    // null if this screen is ever rendered under a Theme that doesn't
    // register the AppTypography extension (a misconfigured test harness,
    // a route pushed outside the themed MaterialApp, etc). A force-unwrap
    // here would crash mid-build with no visible error in release mode —
    // the same failure shape that caused the blank-screen bug. Falling
    // back to Theme.of(context).textTheme keeps the screen rendering
    // (with slightly different typography) instead of disappearing.
    final typography = Theme.of(context).extension<AppTypography>();

    if (typography == null) {
      return _ProfileThemeFallback(displayName: displayName, email: email);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── identity block ──────────────────────────────
          Container(
            color: AppColors.colorCard,
            padding: const EdgeInsets.only(
              top: AppSpacing.space32,
              bottom: AppSpacing.space24,
              left: AppSpacing.space24,
              right: AppSpacing.space24,
            ),
            child: Column(
              children: [
                // avatar
                Container(
                  width: AppSpacing.space48 + AppSpacing.space20,
                  height: AppSpacing.space48 + AppSpacing.space20,
                  decoration: const BoxDecoration(
                    color: AppColors.colorPrimary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(displayName),
                    style: typography.textHeading1.copyWith(
                      color: AppColors.colorOnPrimary,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.space12),

                // name
                Text(
                  displayName,
                  style: typography.textHeading1.copyWith(
                    color: AppColors.colorTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.space4),

                // email
                Text(
                  email,
                  style: typography.textBodySmall.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.space16),

                // medication count chip
                _MedicationCountChip(
                  countAsync: medicationCount,
                  typography: typography,
                ),
              ],
            ),
          ),

          SizedBox(height: AppSpacing.space8),

          // ── detail rows ─────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
            decoration: BoxDecoration(
              color: AppColors.colorCard,
              borderRadius: AppRadius.card,
              border: Border.all(
                color: AppColors.colorBorder,
                width: AppSpacing.medicationCardBorderWidth,
              ),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Name',
                  value: displayName,
                  typography: typography,
                  hasDivider: true,
                ),
                _DetailRow(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  value: email,
                  typography: typography,
                  hasDivider: false,
                ),
              ],
            ),
          ),

          SizedBox(height: AppSpacing.space24),

          // ── sign out ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
            child: OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.colorStateEmber,
                side: const BorderSide(
                  color: AppColors.colorStateEmber,
                  width: AppSpacing.medicationCardBorderWidth,
                ),
                backgroundColor: AppColors.colorStateEmberSurface,
                minimumSize: const Size(
                  double.infinity,
                  AppSpacing.buttonHeightPrimary,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
                textStyle: typography.textBody.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          SizedBox(height: AppSpacing.space32),
        ],
      ),
    );
  }
}

// ─── theme-missing fallback ───────────────────────────────

// Minimal, dependency-free rendering used only if AppTypography is ever
// unavailable on the current Theme. Deliberately uses Theme.of(context)
// .textTheme (always present on any MaterialApp) instead of AppTypography
// tokens, so this widget can never fail the same way _ProfileLoaded could.
class _ProfileThemeFallback extends StatelessWidget {
  const _ProfileThemeFallback({required this.displayName, required this.email});

  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(displayName, style: textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(email, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ─── medication count chip ────────────────────────────────

class _MedicationCountChip extends StatelessWidget {
  const _MedicationCountChip({
    required this.countAsync,
    required this.typography,
  });

  final AsyncValue<int> countAsync;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return countAsync.when(
      loading: () => LoadingPulseAnimation(
        isLoading: true,
        child: Container(
          width: AppSpacing.space48 * 3,
          height: AppSpacing.space24,
          decoration: BoxDecoration(
            color: AppColors.colorSkeleton,
            borderRadius: AppRadius.pill,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (count) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.colorStateConsistentSurface,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: AppColors.colorStateConsistent,
            width: AppSpacing.medicationCardBorderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.medication_outlined,
              size: AppSpacing.iconSizeStandard,
              color: AppColors.colorStateConsistent,
            ),
            SizedBox(width: AppSpacing.space8),
            Text(
              '$count active medication${count == 1 ? '' : 's'}',
              style: typography.textLabel.copyWith(
                color: AppColors.colorStateConsistent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── detail row ───────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.typography,
    required this.hasDivider,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppTypography typography;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space16,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSpacing.iconSizeStandard,
                color: AppColors.colorTextTertiary,
              ),
              SizedBox(width: AppSpacing.space12),
              Text(
                label,
                style: typography.textBodySmall.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: typography.textBodySmall.copyWith(
                    color: AppColors.colorTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (hasDivider)
          const Divider(
            height: 1,
            thickness: AppSpacing.medicationCardBorderWidth,
            color: AppColors.colorBorder,
          ),
      ],
    );
  }
}

// ─── loading skeleton ─────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return LoadingPulseAnimation(
      isLoading: true,
      child: Column(
        children: [
          Container(
            color: AppColors.colorCard,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.space32,
              horizontal: AppSpacing.space24,
            ),
            child: Column(
              children: [
                _SkeletonBox(
                  width: AppSpacing.space48 + AppSpacing.space20,
                  height: AppSpacing.space48 + AppSpacing.space20,
                  borderRadius: BorderRadius.circular(
                    (AppSpacing.space48 + AppSpacing.space20) / 2,
                  ),
                ),
                SizedBox(height: AppSpacing.space12),
                _SkeletonBox(
                  width: AppSpacing.space48 * 2.5,
                  height: AppSpacing.space24,
                  borderRadius: AppRadius.badge,
                ),
                SizedBox(height: AppSpacing.space8),
                _SkeletonBox(
                  width: AppSpacing.space48 * 3,
                  height: AppSpacing.space16,
                  borderRadius: AppRadius.badge,
                ),
                SizedBox(height: AppSpacing.space16),
                _SkeletonBox(
                  width: AppSpacing.space48 * 3,
                  height: AppSpacing.space24,
                  borderRadius: AppRadius.pill,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.colorSkeleton,
        borderRadius: borderRadius,
      ),
    );
  }
}

// ─── error state ──────────────────────────────────────────

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>();
    final headingStyle =
        typography?.textHeading2 ?? Theme.of(context).textTheme.headlineSmall;
    final bodyStyle =
        typography?.textBodySmall ?? Theme.of(context).textTheme.bodySmall;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Something went wrong',
              style: headingStyle?.copyWith(color: AppColors.colorTextPrimary),
            ),
            SizedBox(height: AppSpacing.space8),
            Text(
              message,
              style: bodyStyle?.copyWith(color: AppColors.colorTextSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.space24),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
