import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../not_found_screen.dart';

/// A wall's current layout. For now only its frame: photos and the problem
/// list arrive in later slices.
class WallScreen extends ConsumerWidget {
  final String wallId;
  const WallScreen({super.key, required this.wallId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wall   = ref.watch(wallProvider(wallId));
    final layout = ref.watch(currentLayoutProvider(wallId));

    if (wall.isLoading || layout.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final w = wall.value;
    final l = layout.value;
    if (w == null || l == null) return const NotFoundScreen();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(l.name ?? 'Since ${l.startedOn}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No wall photos yet', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
