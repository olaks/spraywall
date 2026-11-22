import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown for an unknown route or an id that no longer exists — a stale web
/// bookmark, or a wall deleted on another tab.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Not found', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to your walls'),
              ),
            ],
          ),
        ),
      );
}
