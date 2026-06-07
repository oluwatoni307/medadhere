// ===
// FILE:             password_reset_screen.dart
// PATH:             lib/features/auth/screens/password_reset_screen.dart
// DOMAIN:           features
// LAYER:            screen
// RESPONSIBLE FOR:  Password reset screen — Phase A (request) and Phase B
//                   (success) handled via AnimatedSwitcher, wired to auth state.
// RECEIVES:         onBack: void Function() -> navigates to /login
//                   AuthNotifier state via ref.watch
// RETURNS:          void
// CONNECTS TO:      lib/core/theme/app_colors.dart
//                   lib/core/theme/app_typography.dart
//                   lib/core/theme/app_spacing.dart
//                   lib/core/theme/app_radius.dart
//                   lib/core/theme/app_motion.dart
//                   lib/features/auth/state/auth_notifier_provider.dart
// MUST NEVER:       import services directly, manually route post-success,
//                   or hardcode values.
// ===

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// design tokens
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';

// internal state
import '../../../shared/models/app_user.dart';
import '../state/auth_notifier_provider.dart';

// ─── widget ───────────────────────────────────────────────────────────────────

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key, required this.onBack});

  final void Function() onBack;

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen>
    with SingleTickerProviderStateMixin {
  // Logic Injection
  final _emailController = TextEditingController();

  bool _successVisible = false;
  bool _localErrorDismissed = false;
  String _submittedEmail = ''; // Captured on submit for Phase B interpolation

  // Animation Architecture
  late final AnimationController _entranceController;
  late final Animation<double> _greetingOpacity;
  late final Animation<double> _greetingTranslateY;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.durationReveal,
    );

    _greetingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: AppMotion.curveStandard,
      ),
    );

    _greetingTranslateY = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: AppMotion.curveStandard,
      ),
    );

    _emailController.addListener(_onInputChanged);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (_localErrorDismissed == false) {
      setState(() => _localErrorDismissed = true);
    } else {
      setState(() {}); // Re-evaluate CTA enabled condition
    }
  }

  //
  // --- actions ---
  //

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    // Basic format validation + non-empty
    return email.isNotEmpty &&
        RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
        ).hasMatch(email);
  }

  Future<void> _onSubmit() async {
    if (!_isEmailValid) return;

    setState(() {
      _localErrorDismissed = false;
      _successVisible = false;
      _submittedEmail = _emailController.text.trim();
    });

    await ref.read(authProvider.notifier).sendPasswordReset(_submittedEmail);

    if (!mounted) return;

    final hasError = ref.read(authProvider).hasError;
    if (!hasError) {
      setState(() => _successVisible = true);
    }
  }

  //
  // --- build ---
  //

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    final resolvedError = _resolveError(authState);
    final displayError = _localErrorDismissed ? null : resolvedError;

    return Scaffold(
      backgroundColor: AppColors.colorSurface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.viewportMarginHorizontal,
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.durationReveal,
              switchInCurve: AppMotion.curveStandard,
              switchOutCurve: AppMotion.curveTransition,
              child: _successVisible
                  ? _buildPhaseB(typography, isLoading)
                  : _buildPhaseA(typography, isLoading, displayError),
            ),
          ),
        ),
      ),
    );
  }

  //
  // --- private widgets (Phase A) ---
  //

  Widget _buildPhaseA(AppTypography typography, bool isLoading, String? error) {
    return Column(
      key: const ValueKey('PhaseA'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.space16),
        _buildBackButton(typography),
        const SizedBox(height: AppSpacing.space24),
        AnimatedBuilder(
          animation: _entranceController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _greetingTranslateY.value),
              child: Opacity(opacity: _greetingOpacity.value, child: child),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACCOUNT ACCESS',
                style: typography.textInsightCardEyebrow.copyWith(
                  color: AppColors.colorTextTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'Reset your password',
                style: typography.textHeading1.copyWith(
                  color: AppColors.colorTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Enter the email address for your MedAdhere account. We will send you a link to reset your password.',
                style: typography.textBody.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space32),
        Semantics(
          label: 'Enter your email address',
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofocus: false,
            onSubmitted: (_) => _onSubmit(),
            style: typography.textBody.copyWith(
              color: AppColors.colorTextPrimary,
            ),
            decoration: _inputDecoration(typography, 'Email address'),
          ),
        ),
        const SizedBox(height: AppSpacing.space32),
        _buildPhaseASubmitButton(typography, isLoading),
        _buildErrorBlock(typography, error),
        const SizedBox(height: AppSpacing.space24),
        Center(
          child: TextButton(
            onPressed: widget.onBack,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.touchTargetMin),
            ),
            child: Text(
              'Back to sign in',
              style: typography.textBody.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space40),
      ],
    );
  }

  Widget _buildBackButton(AppTypography typography) {
    return Semantics(
      label: 'Go back to sign in',
      child: Container(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.touchTargetMin,
          minHeight: AppSpacing.touchTargetMin,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          color: AppColors.colorTextPrimary,
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: widget.onBack,
        ),
      ),
    );
  }

  Widget _buildPhaseASubmitButton(AppTypography typography, bool isLoading) {
    final isEnabled = _isEmailValid;

    return Semantics(
      label: isLoading
          ? 'Sending password reset link, please wait'
          : isEnabled
          ? 'Send password reset link'
          : 'Enter your email to send a reset link',
      child: IgnorePointer(
        ignoring: !isEnabled || isLoading,
        child: AnimatedContainer(
          duration: AppMotion.durationFast,
          curve: AppMotion.curveStandard,
          height: AppSpacing.buttonHeightPrimary,
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.colorPrimary : AppColors.colorDisabled,
            borderRadius: AppRadius.button,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.button,
              onTap: _onSubmit,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.colorOnPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'Send reset link',
                        style: typography.textBody.copyWith(
                          color: isEnabled
                              ? AppColors.colorOnPrimary
                              : AppColors.colorSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBlock(AppTypography typography, String? error) {
    final hasError = error != null;

    return Semantics(
      label: hasError ? 'Error: $error' : '',
      child: AnimatedSize(
        duration: AppMotion.durationReveal,
        curve: AppMotion.curveStandard,
        alignment: Alignment.topCenter,
        child: AnimatedOpacity(
          opacity: hasError ? 1.0 : 0.0,
          duration: AppMotion.durationFast,
          child: hasError
              ? Container(
                  margin: const EdgeInsets.only(top: AppSpacing.space16),
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  decoration: BoxDecoration(
                    color: AppColors.colorStateEmberSurface,
                    border: Border.all(
                      color: AppColors.colorStateEmber,
                      width: 1.0,
                    ),
                    borderRadius: AppRadius.card,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.colorStateEmber,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Text(
                          error,
                          style: typography.textBodySmall.copyWith(
                            color: AppColors.colorStateEmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ),
    );
  }

  //
  // --- private widgets (Phase B) ---
  //

  Widget _buildPhaseB(AppTypography typography, bool isLoading) {
    return Column(
      key: const ValueKey('PhaseB'),
      crossAxisAlignment:
          CrossAxisAlignment.center, // Flips to center per brief
      children: [
        const SizedBox(height: AppSpacing.space40), // Spaced from SafeArea top
        Semantics(
          label: 'Success — reset link sent',
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.colorStateConsistentSurface,
              border: Border.all(
                color: AppColors.colorStateConsistent,
                width: 1.0,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check,
                color: AppColors.colorStateConsistent,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space24),
        Text(
          'Check your inbox',
          style: typography.textHeading1.copyWith(
            color: AppColors.colorTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space12),
        Text(
          'We sent a password reset link to $_submittedEmail. It should arrive within a few minutes.',
          style: typography.textBody.copyWith(
            color: AppColors.colorTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space40),
        Semantics(
          label: 'Return to sign in',
          child: SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeightPrimary,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorPrimary,
                foregroundColor: AppColors.colorOnPrimary,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
                elevation: 0,
              ),
              onPressed: widget.onBack,
              child: Text(
                'Back to sign in',
                style: typography.textBody.copyWith(
                  color: AppColors.colorOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space16),
        Semantics(
          label: 'Resend password reset email',
          child: TextButton(
            onPressed: isLoading ? null : _onSubmit,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.touchTargetMin),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.colorStateConsistent,
                      ),
                    ),
                  )
                : Text(
                    "Didn't receive it? Send again",
                    style: typography.textBody.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  //
  // --- private helpers ---
  //

  InputDecoration _inputDecoration(AppTypography typography, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: typography.textBody.copyWith(
        color: AppColors.colorTextTertiary,
      ),
      filled: true,
      fillColor: AppColors.colorCard,
      contentPadding: const EdgeInsets.all(AppSpacing.space16),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.card,
        borderSide: const BorderSide(color: AppColors.colorBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.card,
        borderSide: const BorderSide(color: AppColors.colorPrimary, width: 1.5),
      ),
    );
  }

  String? _resolveError(AsyncValue<AppUser?> state) {
    return state.whenOrNull(
      error: (e, _) =>
          e is FirebaseAuthException ? e.message : 'An error occurred',
    );
  }
}
