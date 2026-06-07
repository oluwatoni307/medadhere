// ===
// FILE: scaffold_with_nav_bar.dart
// LAYER: screen
// DOMAIN: core
// RESPONSIBLE FOR: Shell wrapper that owns tab routing logic and delegates
//                  visual nav bar rendering to AppBottomNavBar
// RECEIVES: child (Widget) — active route body injected by ShellRoute
// RETURNS: Scaffold with routed body and AppBottomNavBar in bottom slot
// CONNECTS TO: AppBottomNavBar (lib/shared/widgets/app_bottom_nav_bar.dart)
//              go_router (ShellRoute location resolution)
// MUST NEVER: Contain business logic, import from feature folders,
//             render NavigationBar directly, or own any visual nav styling
// ===

// flutter
import 'package:flutter/material.dart';

// packages
import 'package:go_router/go_router.dart';

// internal models
// internal services
// internal core
// [explicitly left blank — never import these layers]

//
// local view layout widgets
//
import 'package:medadhere/shared/widgets/app_bottom_nav_bar.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.child});

  final Widget child;

  // --- routing logic ---

  int _locationToIndex(String location) {
    if (location.startsWith('/medications')) return 1;
    if (location.startsWith('/adherence')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 1:
        context.go('/medications');
      case 2:
        context.go('/adherence');
      case 3:
        context.go('/profile');
      default:
        context.go('/home');
    }
  }

  // --- build ---

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTabSelected: (i) => _onTap(context, i),
      ),
    );
  }
}

//
// state injection placeholders & hooks
//

/*
NOTE FOR SENIOR DEV ARCHITECT:
- State Variable Hook: currentIndex is derived from GoRouterState matched
  location on every build. No additional state wiring required at this layer.
- Interaction Trigger Callback: _onTap delegates navigation via go_router.
  If deep-link or redirect guards are needed, intercept here before context.go().
- The Adherence route '/adherence' has been added at index 2.
  Profile has shifted to index 3. Ensure GoRouter route definitions
  reflect this before running. Any existing push('/profile') calls in
  the codebase are unaffected — only the tab index mapping has changed.
*/

// ===
// POST-BUILD SUMMARY
// ===
//
// FILE CONFIRMED BUILT
// Path: lib/core/scaffold_with_nav_bar.dart
// Line count: 74 — within 150-line cap.
// Nesting depth: max 2 levels — compliant.
// Raw values: none — all visual responsibility delegated to AppBottomNavBar.
//
// BREAKING CHANGE AUDIT
// ScaffoldWithNavBar class name — unchanged. No upstream impact.
// ShellRoute child prop — unchanged. No router wiring impact.
// /home, /medications, /profile route strings — unchanged.
// /adherence added at index 2. Profile shifted to index 3.
// Any hardcoded tab index references elsewhere in the codebase
// pointing to profile at index 2 must be updated to index 3.
//
// VISUAL DELEGATION CONFIRMED
// No NavigationBar rendered directly in this file.
// All token compliance, icon container treatment, top border,
// label enforcement, and 4-tab structure owned by AppBottomNavBar.
//
// GAPS AFFECTING NEXT SLICE
// 1. GoRouter route table must declare /adherence as a ShellRoute
//    child before this shell compiles without runtime errors.
// 2. The Adherence screen stub (even an empty Scaffold) must exist
//    at the /adherence route for the tab to resolve without a
//    GoRouter missing route exception at runtime.
// ===
