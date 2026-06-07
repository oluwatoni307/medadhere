// ===
// FILE:             intro_slides_screen.dart
// PATH:             lib/features/onboarding/screens/intro_slides_screen.dart
// DOMAIN:           features
// LAYER:            screen
// RESPONSIBLE FOR:  Renders the three-slide onboarding intro flow with illustration,
//                   copy block, page indicator, skip button, and primary CTA.
// RECEIVES:         onIntroComplete: void Function() — navigates to welcome_screen
//                   onSkip: void Function()          — navigates to welcome_screen
// RETURNS:          onIntroComplete: void Function() — called after markIntroSeen() on final CTA
//                   onSkip: void Function()          — called after markIntroSeen() on skip tap
// CONNECTS TO:      lib/theme/app_colors.dart
//                   lib/theme/app_typography.dart
//                   lib/theme/app_spacing.dart
//                   lib/theme/app_radius.dart
//                   lib/theme/app_motion.dart
// MUST NEVER:       Call repositories, services, Firebase SDKs, declare providers,
//                   call routing methods directly
// STATE HOOK POINTS:
//   - ref.watch(onboardingProvider): AsyncValue<OnboardingState> → drives loading/error on CTA
//   - onIntroComplete: void Function() → wire to _onActionTapped when _isLastPage == true
//   - onSkip: void Function()          → wire to _onActionTapped on skip tap
// ===

// flutter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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

// ─── slide data ───────────────────────────────────────────────────────────────

class IntroSlide {
  final String eyebrow;
  final String title;
  final String body;
  final String? illustrationAsset;

  const IntroSlide({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.illustrationAsset,
  });
}

const _slides = [
  IntroSlide(
    eyebrow: 'YOUR DAILY RHYTHM',
    title: 'Never lose track\nof a dose again',
    body:
        'MedAdhere keeps your medications organised so you always know what to take and when.',
    illustrationAsset: 'assets/illustrations/onboarding_reminder.png',
  ),
  IntroSlide(
    eyebrow: 'BUILD YOUR HABIT',
    title: 'Small steps,\nbig results',
    body: 'Create routines that quietly support your health every single day.',
    illustrationAsset: 'assets/illustrations/onboarding_log.png',
  ),
  IntroSlide(
    eyebrow: 'SEE YOUR PROGRESS',
    title: 'Watch your\nstreak grow',
    body:
        'Every dose logged is a win. MedAdhere shows you how far you have come.',
    illustrationAsset: 'assets/illustrations/onboarding_progress.png',
  ),
];

// ─── widget ───────────────────────────────────────────────────────────────────

class IntroSlidesScreen extends ConsumerStatefulWidget {
  const IntroSlidesScreen({
    super.key,
    required this.onIntroComplete,
    required this.onSkip,
  });

  final void Function() onIntroComplete;
  final void Function() onSkip;

  @override
  ConsumerState<IntroSlidesScreen> createState() => _IntroSlidesScreenState();
}

class _IntroSlidesScreenState extends ConsumerState<IntroSlidesScreen> {
  static const _pageCount = 3;

  final PageController _pageController = PageController();

  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pageCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onActionTapped(VoidCallback callback) async {
    await ref.read(onboardingProvider.notifier).markIntroSeen();

    if (!mounted) return;

    callback();
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSkipButton(typography),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    _buildSlidePage(context, index, typography),
              ),
            ),
            _buildBottomControls(context, typography),
          ],
        ),
      ),
    );
  }

  // ─── private builders ─────────────────────────────────────────────────────────

  Widget _buildSkipButton(AppTypography typography) {
    return Semantics(
      label: 'Skip onboarding and go to setup',
      child: AnimatedOpacity(
        opacity: _isLastPage ? 0.0 : 1.0,
        duration: AppMotion.durationFast,
        curve: AppMotion.curveStandard,
        child: IgnorePointer(
          ignoring: _isLastPage,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _onActionTapped(widget.onSkip),
              child: Text(
                'Skip',
                style: typography.textBody.copyWith(
                  color: AppColors.colorTextTertiary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlidePage(
    BuildContext context,
    int index,
    AppTypography typography,
  ) {
    final slide = _slides[index];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.viewportMarginHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIllustration(slide),
          const SizedBox(height: AppSpacing.space24),
          _buildCopyBlock(index, typography),
        ],
      ),
    );
  }

  Widget _buildIllustration(IntroSlide slide) {
    return Semantics(
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: slide.illustrationAsset != null
            ? Image.asset(
                slide.illustrationAsset!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: AppColors.colorSurface),
              )
            : const ColoredBox(color: AppColors.colorSurface),
      ),
    );
  }

  Widget _buildCopyBlock(int index, AppTypography typography) {
    final slide = _slides[index];

    return AnimatedSwitcher(
      duration: AppMotion.durationFast,
      switchInCurve: AppMotion.curveStandard,
      switchOutCurve: AppMotion.curveStandard,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey(index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slide.eyebrow,
              style: typography.textInsightCardEyebrow.copyWith(
                color: AppColors.colorTextTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              slide.title,
              style: typography.textHeading1.copyWith(
                color: AppColors.colorTextPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              slide.body,
              style: typography.textBody.copyWith(
                color: AppColors.colorTextSecondary,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, AppTypography typography) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.viewportMarginHorizontal,
        0,
        AppSpacing.viewportMarginHorizontal,
        AppSpacing.viewportMarginVertical,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Step ${_currentPage + 1} of 3',
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pageCount,
                effect: ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 2.5,
                  activeDotColor: AppColors.colorPrimary,
                  dotColor: AppColors.colorDisabled,
                  radius: AppRadius.radiusPill,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space24),
          _buildCta(typography),
        ],
      ),
    );
  }

  Widget _buildCta(AppTypography typography) {
    final isLast = _isLastPage;

    return Semantics(
      label: isLast
          ? 'Finish introduction and begin setup'
          : 'Go to next slide',
      child: SizedBox(
        height: AppSpacing.buttonHeightPrimary,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.colorPrimary,
            foregroundColor: AppColors.colorOnPrimary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
            elevation: 0,
          ),
          onPressed: () {
            if (isLast) {
              _onActionTapped(widget.onIntroComplete);
            } else {
              _pageController.nextPage(
                duration: AppMotion.durationFast,
                curve: AppMotion.curveStandard,
              );
            }
          },
          child: AnimatedSwitcher(
            duration: AppMotion.durationFast,
            child: Text(
              isLast ? "Let's begin" : 'Next',
              key: ValueKey(isLast),
              style: typography.textBody.copyWith(
                color: AppColors.colorOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
