import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import '../database/database.dart';
import '../marks/mark_geometry.dart';
import '../marks/outline.dart';
import '../utils/format_utils.dart';

/// The caption bar's text: `name · grade · wall`, the grade left out for an
/// ungraded problem.
String shareCaption({
  required String  name,
  required String? grade,
  required String  wall,
}) =>
    [name.trim(), ?grade, wall.trim()].join(' · ');

/// The photos a problem's share images show: those carrying any of its
/// [marks], in the layout's order.
List<WallPhoto> photosToShare(List<WallPhoto> photos, Iterable<Mark> marks) {
  final used = {for (final m in marks) m.photoId};
  return [for (final p in photos) if (used.contains(p.id)) p];
}

/// One share image's file name: the problem, plus the photo's title when
/// there are several, kept to safe characters.
String shareImageName(String problem, String photoTitle, {required bool several}) =>
    several
        ? '${fileSafe(problem)}-${fileSafe(photoTitle)}.jpg'
        : '${fileSafe(problem)}.jpg';

/// The caption bar's height for an image [width] pixels wide: readable when
/// the image is shown shrunk to a phone screen.
double captionBarHeight(int width) =>
    (width * 0.07).roundToDouble().clamp(48, 220);

/// A rendered share image, as straight (unpremultiplied) RGBA pixels.
class RenderedImage {
  final Uint8List rgba;
  final int       width;
  final int       height;
  const RenderedImage(this.rgba, this.width, this.height);
}

/// [photo] (the stored JPEG) at its own pixel size with [marks] drawn on as
/// the app draws them, a halo under each ring, and below it a caption bar
/// with [caption] and a legend of the roles on it. Needs the Flutter engine
/// (`dart:ui`): in a widget test, run it inside `runAsync`.
Future<RenderedImage> renderShareImage({
  required Uint8List  photo,
  required List<Mark> marks,
  required String     caption,
}) async {
  final codec = await ui.instantiateImageCodec(photo);
  final image = (await codec.getNextFrame()).image;
  final size  = Size(image.width.toDouble(), image.height.toDouble());
  final bar   = captionBarHeight(image.width);

  final recorder = ui.PictureRecorder();
  final canvas   = Canvas(recorder);
  canvas.drawImage(image, Offset.zero, Paint());

  // Strokes scaled to the photo, so they read when it is shown shrunk.
  final stroke = math.max(4.0, size.width * 0.003);
  for (final m in marks) {
    strokeMark(canvas,
        markPath(m.cx, m.cy, m.r, decodeOutline(m.outline), size),
        roleColors[m.role]!, stroke);
  }

  _drawCaptionBar(canvas, Rect.fromLTWH(0, size.height, size.width, bar),
      caption, {for (final m in marks) m.role});

  final out = await recorder.endRecording()
      .toImage(image.width, (size.height + bar).round());
  final rgba = (await out.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
  image.dispose();
  out.dispose();
  return RenderedImage(rgba.buffer.asUint8List(), out.width, out.height);
}

void _drawCaptionBar(Canvas canvas, Rect bar, String caption, Set<Role> roles) {
  canvas.drawRect(bar, Paint()..color = const Color(0xFF121212));
  final pad  = bar.height * 0.3;
  final ring = bar.height * 0.12;

  // The legend, right-aligned: a ring and a word per role on the image.
  final legend = [
    for (final r in Role.values)
      if (roles.contains(r))
        (r, _text(roleLabel(r), bar.height * 0.26, const Color(0xFFBDBDBD))),
  ];
  var x = bar.right - pad;
  for (final (role, label) in legend.reversed) {
    x -= label.width;
    label.paint(canvas, Offset(x, bar.center.dy - label.height / 2));
    x -= ring * 1.6;
    canvas.drawCircle(Offset(x, bar.center.dy), ring, Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = ring * 0.45
      ..color       = roleColors[role]!);
    x -= ring * 2.6;
  }

  final text = _text(caption, bar.height * 0.36, const Color(0xFFFFFFFF),
      maxWidth: math.max(0, x - bar.left - pad));
  text.paint(canvas, Offset(bar.left + pad, bar.center.dy - text.height / 2));
}

TextPainter _text(String text, double size, Color color,
    {double maxWidth = double.infinity}) =>
    TextPainter(
      text: TextSpan(text: text, style: TextStyle(
          fontSize: size, color: color, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

/// [image] as a JPEG. Pure, for an isolate: a 2560 px image takes a while.
/// Full-resolution colour (4:4:4), so thin coloured rings stay their colour.
Uint8List encodeShareJpeg(RenderedImage image) => img.encodeJpg(
    img.Image.fromBytes(
      width:       image.width,
      height:      image.height,
      bytes:       image.rgba.buffer,
      bytesOffset: image.rgba.offsetInBytes,
      numChannels: 4,
    ),
    quality: 90);

/// [encodeShareJpeg] off the UI thread. Overridden in widget tests, where an
/// isolate never finishes under fake time.
final shareEncoderProvider = Provider<Future<Uint8List> Function(RenderedImage)>(
    (ref) => (image) => compute(encodeShareJpeg, image));
