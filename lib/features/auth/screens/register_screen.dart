// ===
// FILE:             register_screen.dart
// PATH:             lib/features/auth/screens/register_screen.dart
// DOMAIN:           features
// LAYER:            screen
// RESPONSIBLE FOR:  Register screen — email, password, confirm password inputs,
//                   client-side strength validation, error and loading states.
// RECEIVES:         onBack: void Function()  -> navigates to /entry
//                   onLogin: void Function() -> navigates to /login
//                   AuthNotifier state via ref.watch
// RETURNS:          void
// CONNECTS TO:      lib/core/theme/app_colors.dart
//                   lib/core/theme/app_typography.dart
//                   lib/core/theme/app_spacing.dart
//                   lib/core/theme/app_radius.dart
//                   lib/core/theme/app_motion.dart
//                   lib/features/auth/state/auth_notifier_provider.dart
// MUST NEVER:       import services directly, pass confirmPassword to notifier,
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

// ─── enums & helpers ──────────────────────────────────────────────────────────

enum _StrengthTier { none, weak, fair, good, strong }

// ─── widget ───────────────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onBack,
    required this.onLogin,
  });

  final void Function() onBack;
  final void Function() onLogin;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // Logic Injection
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _termsAccepted = false;
  bool _mismatchVisible = false;

  _StrengthTier _strength = _StrengthTier.none;
  bool _localErrorDismissed = false;

  // Animation Architecture
  late final AnimationController _entranceController;
  late final Animation<double> _greetingOpacity;
  late final Animation<double> _greetingTranslateY;
  late final Animation<double> _fieldsOpacity;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340), // reveal + 60ms stagger
    );

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

    _fieldsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.18, 1.0, curve: AppMotion.curveStandard),
      ),
    );

    _emailController.addListener(_evaluateForm);
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _evaluateForm() {
    if (_localErrorDismissed == false) {
      setState(() => _localErrorDismissed = true);
    } else {
      setState(() {});
    }
  }

  void _onPasswordChanged() {
    final pw = _passwordController.text;
    _StrengthTier tier = _StrengthTier.none;

    if (pw.isNotEmpty) {
      if (pw.length < 6) {
        tier = _StrengthTier.weak;
      } else if (pw.length < 8) {
        tier = _StrengthTier.fair;
      } else {
        final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(pw);
        final hasNumbers = RegExp(r'[0-9]').hasMatch(pw);
        final hasSpecial = RegExp(r'[!@#\$&*~]').hasMatch(pw);

        if (pw.length >= 10 && hasLetters && hasNumbers && hasSpecial) {
          tier = _StrengthTier.strong;
        } else if (hasLetters && hasNumbers) {
          tier = _StrengthTier.good;
        } else {
          tier = _StrengthTier.fair;
        }
      }
    }

    setState(() {
      _strength = tier;
      // Note: intentionally NOT evaluating mismatch here per the brief
    });
    _evaluateForm();
  }

  void _onConfirmPasswordChanged() {
    final confirm = _confirmPasswordController.text;
    final pw = _passwordController.text;

    // Evaluated exclusively on confirm keystrokes
    setState(() {
      _mismatchVisible = confirm.isNotEmpty && confirm != pw;
    });
    _evaluateForm();
  }

  //
  // --- actions ---
  //

  Future<void> _onSubmit() async {
    if (!_isFormValid) return;

    setState(() => _localErrorDismissed = false);

    await ref
        .read(authProvider.notifier)
        .register(
          email: _emailController.text.trim(),
          password: _passwordController.text
              .trim(), // Confirm never passed to notifier
        );
  }

  bool get _isFormValid =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty &&
      _passwordController.text == _confirmPasswordController.text &&
      _termsAccepted;

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
            'GETTING STARTED',
            style: typography.textInsightCardEyebrow.copyWith(
              color: AppColors.colorTextTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Create your account',
            style: typography.textHeading1.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'This takes about one minute.',
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
              textInputAction: TextInputAction.next,
              autofocus: false,
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

          _buildStrengthIndicator(typography),
          const SizedBox(height: AppSpacing.space8),

          Semantics(
            label: 'Confirm your password',
            child: TextField(
              controller: _confirmPasswordController,
              obscureText: !_confirmPasswordVisible,
              textInputAction: TextInputAction.done,
              autofocus: false,
              onSubmitted: (_) => _onSubmit(),
              style: typography.textBody.copyWith(
                color: AppColors.colorTextPrimary,
              ),
              decoration: _inputDecoration(typography, 'Confirm password')
                  .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.colorTextSecondary,
                        size: 24,
                      ),
                      tooltip: _confirmPasswordVisible
                          ? 'Hide password'
                          : 'Show password',
                      onPressed: () {
                        setState(
                          () => _confirmPasswordVisible =
                              !_confirmPasswordVisible,
                        );
                      },
                    ),
                  ),
            ),
          ),

          _buildMismatchWarning(typography),
          const SizedBox(height: AppSpacing.space32),

          _buildTermsCheckbox(typography),
          const SizedBox(height: AppSpacing.space24),

          _buildSubmitButton(typography, isLoading),
          _buildErrorBlock(typography, error),
          const SizedBox(height: AppSpacing.space24),
          _buildLoginLink(typography),
          const SizedBox(height: AppSpacing.space40), // Extra scroll padding
        ],
      ),
    );
  }

  Widget _buildStrengthIndicator(AppTypography typography) {
    final bool isVisible = _strength != _StrengthTier.none;

    double percent = 0.0;
    Color color = AppColors.colorSurfaceMuted;
    String label = '';

    switch (_strength) {
      case _StrengthTier.none:
        break;
      case _StrengthTier.weak:
        percent = 0.25;
        color = AppColors.colorStateDusk;
        label = 'Weak';
        break;
      case _StrengthTier.fair:
        percent = 0.50;
        color = AppColors.colorAccent;
        label = 'Fair';
        break;
      case _StrengthTier.good:
        percent = 0.75;
        color = AppColors.colorStateConsistent;
        label = 'Good';
        break;
      case _StrengthTier.strong:
        percent = 1.0;
        color = AppColors.colorStateConsistent;
        label = 'Strong';
        break;
    }

    return AnimatedSize(
      duration: AppMotion.durationFast,
      curve: AppMotion.curveStandard,
      alignment: Alignment.topCenter,
      child: isVisible
          ? Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.space8,
                bottom: AppSpacing.space4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.colorSurfaceMuted,
                        borderRadius: AppRadius.pill,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedContainer(
                              duration: AppMotion.durationFast,
                              curve: AppMotion.curveStandard,
                              width: constraints.maxWidth * percent,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: AppRadius.pill,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  SizedBox(
                    width: 45, // Keep text from jittering layout
                    child: Text(
                      label,
                      style: typography.textCaption.copyWith(
                        color: AppColors.colorTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }

  Widget _buildMismatchWarning(AppTypography typography) {
    return AnimatedSize(
      duration: AppMotion.durationFast,
      curve: AppMotion.curveStandard,
      alignment: Alignment.topCenter,
      child: _mismatchVisible
          ? Container(
              margin: const EdgeInsets.only(top: AppSpacing.space8),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space12,
                vertical: AppSpacing.space8,
              ),
              decoration: BoxDecoration(
                color: AppColors.colorStateDuskSurface,
                // ✅ CORRECT: Using the double token inside Radius.circular()
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(AppRadius.radiusMD),
                  bottomRight: Radius.circular(AppRadius.radiusMD),
                  topLeft: Radius.zero,
                  bottomLeft: Radius.zero,
                ),
                border: const Border(
                  left: BorderSide(
                    color: AppColors.colorStateDusk,
                    width: 5.0, // Insight border off-grid exception
                  ),
                ),
              ),
              child: Text(
                "These passwords don't match yet. Keep going.",
                style: typography.textBodySmall.copyWith(
                  color: AppColors.colorStateDusk,
                ),
              ),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }

  Widget _buildTermsCheckbox(AppTypography typography) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _termsAccepted = !_termsAccepted);
          _evaluateForm();
        },
        borderRadius: AppRadius.card,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _termsAccepted,
                  onChanged: (val) {
                    setState(() => _termsAccepted = val ?? false);
                    _evaluateForm();
                  },
                  activeColor: AppColors.colorPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      4,
                    ), // inner tight radius
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Text(
                  'I agree to the Terms and Privacy Policy',
                  style: typography.textBodySmall.copyWith(
                    color: AppColors.colorTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AppTypography typography, bool isLoading) {
    final isEnabled = _isFormValid;

    return Semantics(
      label: isLoading
          ? 'Creating account, please wait'
          : isEnabled
          ? 'Create account'
          : 'Complete all fields and accept terms to create account',
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
                        'Create account',
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
      label: hasError ? 'Registration error: $error' : '',
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

  Widget _buildLoginLink(AppTypography typography) {
    return Center(
      child: GestureDetector(
        onTap: widget.onLogin,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space8),
          child: RichText(
            text: TextSpan(
              text: 'Already have an account? ',
              style: typography.textBodySmall.copyWith(
                color: AppColors.colorTextSecondary,
              ),
              children: [
                TextSpan(
                  text: 'Sign in',
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
