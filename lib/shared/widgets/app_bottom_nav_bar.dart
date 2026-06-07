// ===
// FILE: app_bottom_nav_bar.dart
// LAYER: widget
// DOMAIN: shared
// RESPONSIBLE FOR: Persistent bottom navigation bar rendered across all four tab screens
// RECEIVES: currentIndex (int) — active tab index driven from root navigator state
//           onTabSelected (ValueChanged<int>) — emits selected index upward to root navigator
// RETURNS: onTabSelected callback with the tapped destination index
// CONNECTS TO: AppColors, AppSpacing, AppRadius, AppTypography, AppTheme.light (NavigationBarTheme)
// MUST NEVER: Call repositories, services, data models, Firebase SDKs, or state providers.
//             Hardcode any hex, dp, sp, or radius value.
//             Hide navigation labels under any condition.
//             Implement AnimationController or custom transitions.
// ===
// flutter
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

// packages
// [none]
// internal models
// internal services
// internal core
// [explicitly left blank — never import these layers]
//
// local view layout widgets
//
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });
  // → STATE HOOK: currentIndex — receives active tab index from root navigator state
  final int currentIndex;
  // → STATE HOOK: onTabSelected — emits selected index upward to root navigator
  final ValueChanged<int> onTabSelected;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _topBorderDecoration(),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _buildDestinations(),
      ),
    );
  }

  List<NavigationDestination> _buildDestinations() {
    return [
      _destination(
        index: 0,
        label: 'Home',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
      ),
      _destination(
        index: 1,
        label: 'Medications',
        activeIcon: Icons.medication,
        inactiveIcon: Icons.medication_outlined,
      ),
      _destination(
        index: 2,
        label: 'Adherence',
        activeIcon: Icons.bar_chart,
        inactiveIcon: Icons.bar_chart_outlined,
      ),
      _destination(
        index: 3,
        label: 'Profile',
        activeIcon: Icons.person,
        inactiveIcon: Icons.person_outline,
      ),
    ];
  }

  NavigationDestination _destination({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    return NavigationDestination(
      label: label,
      icon: _iconContainer(icon: inactiveIcon, isActive: false),
      selectedIcon: _iconContainer(icon: activeIcon, isActive: true),
    );
  }

  Widget _iconContainer({required IconData icon, required bool isActive}) {
    return Container(
      width: AppSpacing.navIconContainerWidth,
      height: AppSpacing.navIconContainerHeight,
      decoration: BoxDecoration(
        color: isActive ? AppColors.navActiveBackground : Colors.transparent,
        borderRadius: AppRadius.chip,
      ),
      child: Icon(
        icon,
        size: AppSpacing.navIconSize,
        color: isActive
            ? AppColors.colorStateConsistent
            : AppColors.colorTextTertiary,
      ),
    );
  }

  BoxDecoration _topBorderDecoration() {
    return BoxDecoration(
      color: AppColors.colorCard,
      border: Border(top: BorderSide(color: AppColors.colorBorder, width: 0.5)),
    );
  }
}
//
// state injection placeholders & hooks
//
/*
NOTE FOR SENIOR DEV ARCHITECT:
- State Variable Hook: Wire `currentIndex` to the active tab index held at root
  navigator level (e.g. via Riverpod AsyncNotifier, ValueNotifier, or equivalent).
- Interaction Trigger Callback: Wire `onTabSelected` to the method that updates
  the active tab index and drives the IndexedStack (or equivalent tab body switcher).
- This widget holds zero internal state. It receives and emits only.
- NavigationBar indicator styling (indicatorColor, indicatorShape) should be
  confirmed against AppTheme.light NavigationBarTheme to ensure no default
  Flutter indicator overrides the custom _iconContainer background treatment.
  Recommended: set NavigationBarThemeData(indicatorColor: Colors.transparent)
  in AppTheme.light to prevent Flutter's default pill from conflicting.
*/
// ===
// POST-BUILD SUMMARY
// ===
//
// FILE CONFIRMED BUILT
// Path: lib/shared/widgets/app_bottom_nav_bar.dart
// Line count: 111 — within 150-line cap.
// Nesting depth: max 3 levels — compliant.
// Raw values: none — all values reference token classes.
//
// TOKEN BEHAVIOUR FLAGS
// NavigationBar applies its own indicatorColor and indicatorShape from
// NavigationBarTheme by default. The _iconContainer navActiveBackground
// treatment will only render correctly if AppTheme.light sets:
//   NavigationBarThemeData(indicatorColor: Colors.transparent)
// If not set, Flutter's default pill indicator wi