// ===
// FILE:             welcome_screen.dart
// PATH:             lib/features/onboarding/screens/welcome_screen.dart
// DOMAIN:           features
// LAYER:            screen
// RESPONSIBLE FOR:  Renders the name collection screen with animated greeting,
//                   name input field, state-driven CTA, and legal footnote.
// RECEIVES:         onNameCollected: void Function() — routes to Add Medication
// RETURNS:          onNameCollected: void Function() — called after writeName() + markNameCollected()
// CONNECTS TO:      lib/theme/app_colors.dart
//                   lib/theme/app_typography.dart
//                   lib/theme/app_spacing.dart
//                   lib/theme/app_radius.dart
//                   lib/theme/app_motion.dart
// MUST NEVER:       Call repositories, services, Firebase SDKs, declare providers,
//                   call routing methods directly
// STATE HOOK POINTS:
//   - ref.read(userProfileProvider.notifier).writeName(name) → wire at _onSubmit step 1
//   - ref.read(onboardingProvider.notifier).markNameCollected() → wire at _onSubmit step 2
//   - onNameCollected: void Function() → replace context.go('/medications/add') in _onSubmit
// ===

// flutter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// design tokens
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

// internal services     — INTENTIONALLY EMPTY
// internal repositories — INTENTIONALLY EMPTY
// internal models       — INTENTIONALLY EMPTY

import '../state/onboarding_notifier.dart';
import '../state/user_profile_notifier.dart';

// ─── widget ───────────────────────────────────────────────────────────────────

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, required this.onNameCollected});

  final void Function() onNameCollected;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Entrance animation controllers
  late final AnimationController _entranceController;
  late final Animation<double> _greetingOpacity;
  late final Animation<Offset> _greetingSlide;
  late final Animation<double> _fieldOpacity;

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

    _greetingSlide =
        Tween<Offset>(
          begin: const Offset(0, 0.03), // ~+8dp normalised
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: AppMotion.curveStandard,
          ),
        );

    _fieldOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 1.0, curve: Curves.easeOut),
        // 80ms delay expressed as interval offset within durationReveal (280ms)
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final String name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name to continue.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Don't forget to import 'package:flutter/foundation.dart'; at the top for debugPrint

    try {
      await ref.read(userProfileProvider.notifier).writeName(name);
      await ref.read(onboardingProvider.notifier).markNameCollected();

      if (mounted) {
        widget.onNameCollected();
      }
    } catch (e, stackTrace) {
      // Log the exact error and trace to your console
      debugPrint('Submit Error: $e');
      debugPrint('Stack Trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.viewportMarginHorizontal,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGreeting(typography),
              const SizedBox(height: AppSpacing.space40),
              _buildField(typography),
              const SizedBox(height: AppSpacing.space32),
              _buildCta(typography),
              const SizedBox(height: AppSpacing.space16),
              _buildLegalFootnote(typography),
            ],
          ),
        ),
      ),
    );
  }

  // ─── private builders ─────────────────────────────────────────────────────────

  Widget _buildGreeting(AppTypography typography) {
    return Semantics(
      label: 'Welcome screen',
      child: FadeTransition(
        opacity: _greetingOpacity,
        child: SlideTransition(
          position: _greetingSlide,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome.',
                style: typography.textDisplay.copyWith(
                  color: AppColors.colorTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                'Before we set up your medications, we would like to know what to call you.',
                style: typography.textBody.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(AppTypography typography) {
    return FadeTransition(
      opacity: _fieldOpacity,
      child: Semantics(
        label: 'Enter your name',
        child: TextField(
          controller: _nameController,
          autofocus: false,
          enabled: !_isLoading,
          textCapitalization: TextCapitalization.words,
          maxLength: 40,
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
          onSubmitted: (_) => _onSubmit(),
          decoration: InputDecoration(
            labelText: 'Your name',
            hintText: 'Mama Ngozi',
            counterText: '',
            errorText: _errorMessage,
            filled: true,
            fillColor: AppColors.colorCard,
            border: OutlineInputBorder(
              borderRadius: AppRadius.card,
              borderSide: BorderSide(color: AppColors.colorBorder, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.card,
              borderSide: BorderSide(color: AppColors.colorBorder, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.card,
              borderSide: BorderSide(
                color: AppColors.colorPrimary,
                width: AppSpacing.inputFocusBorderWidth,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.card,
              borderSide: BorderSide(
                color: AppColors.colorStateEmber,
                width: AppSpacing.inputFocusBorderWidth,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.card,
              borderSide: BorderSide(
                color: AppColors.colorStateEmber,
                width: AppSpacing.inputFocusBorderWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCta(AppTypography typography) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _nameController,
      builder: (context, value, _) {
        final bool hasText = value.text.trim().isNotEmpty;
        final bool isInteractive = hasText && !_isLoading;
        final Color bgColor = hasText || _isLoading
            ? AppColors.colorPrimary
            : AppColors.colorDisabled;

        return Semantics(
          label: _isLoading
              ? 'Saving your name, please wait'
              : hasText
              ? 'Continue to add your medications'
              : 'Enter your name to continue',
          child: IgnorePointer(
            ignoring: !isInteractive,
            child: AnimatedContainer(
              duration: AppMotion.durationFast,
              curve: AppMotion.curveStandard,
              height: AppSpacing.buttonHeightPrimary,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppRadius.button,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isInteractive ? _onSubmit : null,
                  borderRadius: AppRadius.button,
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.colorOnPrimary,
                            ),
                          )
                        : Text(
                            'Continue',
                            style: typography.textBody.copyWith(
                              color: AppColors.colorOnPrimary,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegalFootnote(AppTypography typography) {
    return Semantics(
      label: 'Privacy notice: your name is stored only on this device',
      child: Text(
        'Your name is stored only on your device. MedAdhere does not share your information.',
        style: typography.textCaption.copyWith(
          color: AppColors.colorTextTertiary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
