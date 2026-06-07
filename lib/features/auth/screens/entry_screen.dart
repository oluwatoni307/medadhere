// ===
// FILE:             entry_screen.dart
// PATH:             lib/features/auth/screens/entry_screen.dart
// DOMAIN:           features
// LAYER:            screen
// RESPONSIBLE FOR:  Renders the static app entry point with brand wordmark,
//                   tagline copy, and two auth CTAs.
// RECEIVES:         onRegister: void Function() — navigates to /register
//                   onLogin: void Function()    — navigates to /login
// RETURNS:          onRegister: void Function() — called on primary CTA tap
//                   onLogin: void Function()    — called on secondary CTA tap
// CONNECTS TO:      lib/theme/app_colors.dart
//                   lib/theme/app_typography.dart
//                   lib/theme/app_spacing.dart
//                   lib/theme/app_radius.dart
//                   lib/theme/app_motion.dart
// MUST NEVER:       Call repositories, services, Firebase SDKs, declare providers,
//                   call routing methods directly
// STATE HOOK POINTS: None. Static screen.
// ===

// flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// design tokens
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';

// internal services     — INTENTIONALLY EMPTY
// internal repositories — INTENTIONALLY EMPTY
// internal models       — INTENTIONALLY EMPTY

// ─── widget ───────────────────────────────────────────────────────────────────

class EntryScreen extends StatefulWidget {
  const EntryScreen({
    super.key,
    required this.onRegister,
    required this.onLogin,
  });

  final void Function() onRegister;
  final void Function() onLogin;

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _columnOpacity;

  // Moment 01 press scale state
  double _primaryScale = 1.0;
  double _secondaryScale = 1.0;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.durationReveal,
    );

    _columnOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: AppMotion.curveStandard,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _onPrimaryPressed() async {
    await HapticFeedback.mediumImpact();
    widget.onRegister();
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Scaffold(
      backgroundColor: AppColors.colorSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.viewportMarginHorizontal,
          ),
          child: FadeTransition(
            opacity: _columnOpacity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildWordmark(typography),
                const SizedBox(height: AppSpacing.space32),
                _buildTagline(typography),
                const SizedBox(height: AppSpacing.space40),
                _buildPrimaryCta(typography),
                const SizedBox(height: AppSpacing.space8),
                _buildSecondaryCta(typography),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── private builders ─────────────────────────────────────────────────────────

  Widget _buildWordmark(AppTypography typography) {
    return Semantics(
      label: 'MedAdhere — medication adherence app',
      child: SizedBox(
        width: 160,
        child: Image.asset(
          'assets/images/medadhere_wordmark.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _WordmarkFallback(typography: typography),
        ),
      ),
    );
  }

  Widget _buildTagline(AppTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Your medications.\nYour rhythm.',
          style: typography.textDisplay.copyWith(
            color: AppColors.colorTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space12),
        Text(
          'Stay consistent. See your progress. Feel the difference.',
          style: typography.textBody.copyWith(
            color: AppColors.colorTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrimaryCta(AppTypography typography) {
    return Semantics(
      label: 'Create a new account',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _primaryScale = 0.97),
        onTapUp: (_) {
          setState(() => _primaryScale = 1.0);
          _onPrimaryPressed();
        },
        onTapCancel: () => setState(() => _primaryScale = 1.0),
        child: AnimatedScale(
          scale: _primaryScale,
          duration: AppMotion.durationFast,
          curve: AppMotion.curveStandard,
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
              onPressed: _onPrimaryPressed,
              child: Text(
                'Create an account',
                style: typography.textBody.copyWith(
                  color: AppColors.colorOnPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryCta(AppTypography typography) {
    return Semantics(
      label: 'Sign in to an existing account',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _secondaryScale = 0.97),
        onTapUp: (_) {
          setState(() => _secondaryScale = 1.0);
          widget.onLogin();
        },
        onTapCancel: () => setState(() => _secondaryScale = 1.0),
        child: AnimatedScale(
          scale: _secondaryScale,
          duration: AppMotion.durationFast,
          curve: AppMotion.curveStandard,
          child: SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeightPrimary,
            child: TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
              ),
              onPressed: widget.onLogin,
              child: Text(
                'I already have an account',
                style: typography.textBody.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── private widgets ──────────────────────────────────────────────────────────

class _WordmarkFallback extends StatelessWidget {
  const _WordmarkFallback({required this.typography});

  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'MedAdhere',
          style: typography.textHeading1.copyWith(
            color: AppColors.colorPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Container(
          height: 2,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.colorAccent,
            borderRadius: AppRadius.pill,
          ),
        ),
      ],
    );
  }
}
