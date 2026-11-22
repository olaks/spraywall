import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/zoomable_photo.dart';
import '../not_found_screen.dart';

/// One wall photo, full-screen, to pan and zoom around.
class PhotoViewerScreen extends ConsumerWidget {
  final String wallId;
  final String photoId;
  const PhotoViewerScreen({
    super.key,
    required this.wallId,
    required this.photoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(photoProvider(photoId));
    if (photo.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = photo.value;
    if (p == null) return const NotFoundScreen();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(p.label ?? 'Wall photo'),
      ),
      body: ZoomablePhoto(photo: p),
    );
  }
}
