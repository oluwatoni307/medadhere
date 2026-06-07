// ============================================
// FILE: router.dart
// LAYER: core
// DOMAIN: core
// RESPONSIBLE FOR: GoRouter instance with named routes, shell route wrapping
//                  tabbed screens, live AuthNotifier-driven redirect guard,
//                  and welcome screen error escape route (Debt #29 closed)
// ============================================

// packages
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// internal — models
import '../../features/adherence/screens/adherence_dashboard_screen.dart';
import '../../shared/models/medication.dart';
import '../../shared/models/app_user.dart';

// internal — state
import '../../features/auth/state/auth_notifier_provider.dart';
import '../../features/onboarding/state/onboarding_notifier.dart';
import '../../features/onboarding/state/user_profile_notifier.dart';

// internal — shared
import '../../shared/widgets/scaffold_with_nav_bar.dart';

// internal — screens
import '../../features/auth/screens/entry_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/password_reset_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/medications/screens/medication_list_screen.dart';
import '../../features/medications/screens/add_edit_medication_screen.dart';
import '../../features/medications/screens/medication_detail_screen.dart';
import '../../features/dose_logs/screens/log_dose_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/onboarding/screens/intro_slides_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';

//
// --- auth routes ---
//

const _authRoutes = ['/entry', '/login', '/register', '/password-reset'];

//
// --- multi-state listenable ---
//

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AppUser?>>(authProvider, (_, next) {
      if (next is AsyncLoading) return;
      notifyListeners();
    });

    _ref.listen(onboardingProvider, (_, next) {
      if (next is AsyncLoading) return;
      notifyListeners();
    });
  }

  final Ref _ref;
}

//
// --- router factory ---
//

GoRouter createRouter(Ref ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final onboardingState = ref.read(onboardingProvider);

      // Loading guard: hold position until core states resolve
      if (authState is AsyncLoading || onboardingState is AsyncLoading) {
        return null;
      }

      final isAuth = authState.value?.uid != null;
      final isIntroSeen = onboardingState.value?.isIntroSeen ?? false;
      final isNameCollected = onboardingState.value?.isNameCollected ?? false;

      final path = state.matchedLocation;
      final isGoingToAuth = _authRoutes.contains(path);
      final isGoingToIntro = path == '/intro';
      final isGoingToWelcome = path == '/welcome';

      // (1) Priority: First-time app open (Intro Slides)
      if (!isIntroSeen) {
        return isGoingToIntro ? null : '/intro';
      }

      // (2) Priority: Post-registration Name Collection
      // Escape route: if userProfileProvider is AsyncError, treat name as
      // collected and allow through to /home — prevents infinite /welcome loop
      // when upstream Firestore write is broken. Debt #29 closed.
      final profileState = ref.read(userProfileProvider);
      final isProfileError = profileState is AsyncError;

      if (isAuth && !isNameCollected && !isProfileError) {
        return isGoingToWelcome ? null : '/welcome';
      }

      // (3) Priority: Unauthenticated users attempting to access protected routes
      if (!isAuth && !isGoingToAuth) {
        return '/entry'; // Updated to point to the new EntryScreen
      }

      // UX Guardrail: Prevent authenticated, fully-onboarded users from
      // revisiting auth/onboarding gates
      if (isAuth &&
          isNameCollected &&
          (isGoingToAuth || isGoingToIntro || isGoingToWelcome)) {
        return '/home';
      }

      // (4) Otherwise: No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/entry',
        name: 'entry',
        builder: (context, state) => EntryScreen(
          onRegister: () => context.go('/register'),
          onLogin: () => context.go('/login'),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(
          onRegister: () => context.go('/register'),
          onForgotPassword: () => context.go('/password-reset'),
          onBack: () => context.go('/entry'),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => RegisterScreen(
          onLogin: () => context.go('/login'),
          onBack: () => context.go('/entry'),
        ),
      ),
      GoRoute(
        path: '/password-reset',
        name: 'passwordReset',
        builder: (context, state) =>
            PasswordResetScreen(onBack: () => context.go('/login')),
      ),
      GoRoute(
        path: '/intro',
        name: 'intro',
        builder: (context, state) => IntroSlidesScreen(
          onSkip: () => context.go('/welcome'),
          onIntroComplete: () => context.go('/welcome'),
        ),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) =>
            WelcomeScreen(onNameCollected: () => context.go('/home')),
      ),
      GoRoute(
        path: '/log-dose',
        name: 'logDose',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return LogDoseScreen(
            medicationId: params['medicationId'] as String,
            medicationName: params['medicationName'] as String,
            doseAmount: params['doseAmount'] as String,
            scheduleLabel: params['scheduleLabel'] as String,
            scheduleId: params['scheduleId'] as String,
            scheduledTimeMs: params['scheduledTimeMs'] as int,
            slotId: params['slotId'] as String, // ← added
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/adherence',
            name: 'adherence',
            builder: (context, state) => const AdherenceVisualizationScreen(),
          ),
          GoRoute(
            path: '/medications',
            name: 'medications',
            builder: (context, state) => const MedicationListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'addMedication',
                builder: (context, state) => AddEditMedicationScreen(
                  medication: state.extra as Medication?,
                  onSaved: () => context.pop(),
                  onCancelled: () => context.pop(),
                ),
              ),
              GoRoute(
                path: ':id',
                name: 'medicationDetail',
                builder: (context, state) => MedicationDetailScreen(
                  medicationId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'editMedication',
                    builder: (context, state) => AddEditMedicationScreen(
                      medication: state.extra as Medication?,
                      onSaved: () => context.pop(),
                      onCancelled: () => context.pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

//
// --- provider ---
//

final routerProvider = Provider<GoRouter>((ref) => createRouter(ref));
