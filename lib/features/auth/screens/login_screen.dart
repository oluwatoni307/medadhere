// ===
// FILE:             login_screen.dart
// PATH:             lib/features/auth/screens/login_screen.dart
// DOMAIN:           features
// LAYER:            screen
// RESPONSIBLE FOR:  Renders the login form, handles local field state,
//                   input validation, and loading/error visualization.
// RECEIVES:         onForgotPassword: void Function() -> navigates to /password-reset
//                   onRegister: void Function()       -> navigates to /register
//                   onBack: void Function()           -> navigates to /entry
//                   AuthNotifier state via ref.watch
// RETURNS:          void
// CONNECTS TO:      lib/core/theme/app_colors.dart
//                   lib/core/theme/app_typography.dart
//                   lib/core/theme/app_spacing.dart
//                   lib/core/theme/app_radius.dart
//                   lib/core/theme/app_motion.dart
//                   lib/features/auth/state/auth_notifier_provider.dart
// ===

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    required this.onForgotPassword,
    required this.onRegister,
    required this.onBack,
  });

  final void Function() onForgotPassword;
  final void Function() onRegister;
  final void Function() onBack;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _localErrorDismissed = false; // Masks error if user starts typing again

  // Animation Architecture
  late final AnimationController _entranceController;
  late final Animation<double> _greetingOpacity;
  late final Animation<double> _greetingTranslateY;
  late final Animation<double> _fieldsOpacity;

  @override
  void initState() {
    super.initState();

    // 280ms durationReveal + 60ms staggered delay = 340ms total
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );

    // Greeting: translateY +8dp -> 0, opacity 0.0 -> 1.0. (0ms - 280ms)
    _greetingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.82, curve: AppMotion.curveStandard),
      ),
    );

    _greetingTranslateY = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.82, curve: AppMotion.curveStandard),
      ),
    );

    // Fields entrance: delay 60ms. (60ms - 340ms)
    _fieldsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.18, 1.0, curve: AppMotion.curveStandard),
      ),
    );

    // Rebuild UI to evaluate CTA enabled/disabled state & clear errors
    _emailController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (_localErrorDismissed == false) {
      setState(() => _localErrorDismissed = true);
    } else {
      setState(() {}); // Just rebuilds to evaluate CTA condition
    }
  }

  //
  // --- actions ---
  //

  Future<void> _onSubmit() async {
    if (!_areFieldsFilled) return;

    // Reset local error mask on new submission
    setState(() => _localErrorDismissed = false);

    await ref
        .read(authProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
  }

  bool get _areFieldsFilled =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  //
  // --- build ---
  //

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    // Resolve error message, applying local masking if user has typed
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.space16),
                _buildBackButton(),
                const SizedBox(height: AppSpacing.space24),
                _buildGreeting(typography),
                const SizedBox(height: AppSpacing.space32),
                _buildForm(typography, isLoading, displayError),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //
  // --- private widgets ---
  //

  Widget _buildBackButton() {
    return Semantics(
      label: 'Go back to welcome screen',
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

  Widget _buildGreeting(AppTypography typography) {
    return AnimatedBuilder(
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
            'WELCOME BACK',
            style: typography.textInsightCardEyebrow.copyWith(
              color: AppColors.colorTextTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Sign in to MedAdhere',
            style: typography.textHeading1.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Good to have you back.',
            style: typography.textBody.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AppTypography typography, bool isLoading, String? error) {
    return FadeTransition(
      opacity: _fieldsOpacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Enter your email address',
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofocus: false,
              style: typography.textBody.copyWith(
                color: AppColors.colorTextPrimary,
              ),
              decoration: _inputDecoration(typography, 'Email address'),
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          Semantics(
            label: 'Enter your password',
            child: TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              textInputAction: TextInputAction.done,
              autofocus: false,
              onSubmitted: (_) => _onSubmit(),
              style: typography.textBody.copyWith(
                color: AppColors.colorTextPrimary,
              ),
              decoration: _inputDecoration(typography, 'Password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.colorTextSecondary,
                    size: 24,
                  ),
                  tooltip: _passwordVisible ? 'Hide password' : 'Show password',
                  onPressed: () {
                    setState(() => _passwordVisible = !_passwordVisible);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.touchTargetMin),
              ),
              child: Text(
                'Forgot?',
                style: typography.textBodySmall.copyWith(
                  color: AppColors.colorStateConsistent,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space32),
          _buildSubmitButton(typography, isLoading),
          _buildErrorBlock(typography, error),
          const SizedBox(height: AppSpacing.space24),
          _buildRegisterLink(typography),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppTypography typography, bool isLoading) {
    final isEnabled = _areFieldsFilled;

    return Semantics(
      label: isLoading
          ? 'Signing in, please wait'
          : isEnabled
          ? 'Sign in to your account'
          : 'Enter your email and password to sign in',
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
                        'Sign in',
                        style: typography.textBody.copyWith(
                          color: isEnabled
                              ? AppColors.colorOnPrimary
                              : AppColors
                                    .colorSurface, // warm parchment text on warm grey disabled bg
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
      label: hasError ? 'Sign in error: $error' : '',
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

  Widget _buildRegisterLink(AppTypography typography) {
    return Center(
      child: GestureDetector(
        onTap: widget.onRegister,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space8), // Touch target bump
          child: RichText(
            text: TextSpan(
              text: "Don't have an account? ",
              style: typography.textBodySmall.copyWith(
                color: AppColors.colorTextSecondary,
              ),
              children: [
                TextSpan(
                  text: 'Create one',
                  style: typography.textBodySmall.copyWith(
                    color: AppColors.colorStateConsistent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
