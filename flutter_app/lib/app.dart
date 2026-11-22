import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/theme_provider.dart';
import 'screens/not_found_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/walls/wall_list_screen.dart';
import 'screens/walls/wall_screen.dart';
import 'theme/app_theme.dart';

/// Plain stack navigation with the wall list as the root. Routes nest, so the
/// back stack — and a web reload — follows the hierarchy.
GoRouter buildRouter() => GoRouter(
  errorBuilder: (_, _) => const NotFoundScreen(),
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const WallListScreen(),
      routes: [
        GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: 'walls/:wallId',
          builder: (_, state) =>
              WallScreen(wallId: state.pathParameters['wallId']!),
        ),
      ],
    ),
  ],
);

class SpraywallApp extends ConsumerStatefulWidget {
  const SpraywallApp({super.key});

  @override
  ConsumerState<SpraywallApp> createState() => _SpraywallAppState();
}

class _SpraywallAppState extends ConsumerState<SpraywallApp> {
  // One router per app instance, so each widget test starts at '/'.
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idx = ref.watch(themeIndexProvider);
    return MaterialApp.router(
      title:                      'Spraywall',
      theme:                      buildTheme(themeAccents[idx].color),
      routerConfig:               _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
