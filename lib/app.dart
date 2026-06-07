// ============================================
// FILE: lib/app.dart
// LAYER: screen
// DOMAIN: core
// RESPONSIBLE FOR: Root widget — returns a blank MaterialApp for launch verification
// RECEIVES: Nothing — consumed directly by main.dart
// RETURNS: MaterialApp with blank scaffold
// CONNECTS TO: lib/main.dart
// MUST NEVER: Contain feature logic
// ============================================

// flutter
import 'package:flutter/material.dart';

// packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medadhere/core/theme/app_theme.dart';

import 'core/config/router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: AppTheme.light,
    );
  }
}
