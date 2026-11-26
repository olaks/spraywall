// Runs the hold tracer on the real wall photos in ../sample/ (never
// committed: they carry GPS) and draws what it traced, for judging a change
// to the tracer by eye:
//
//   flutter test tool/trace_eval_test.dart
//
// Each photo is scaled to the stored size (2560 px long edge) and tapped at
// fit zoom (radius 0.15) and zoomed in (0.08). It prints how many holds got
// an outline and how many bare-wall taps got none, and writes a contact sheet
// per photo and radius to build/trace_eval/: a crop around each tap, the tap
// a dot (blue on bare wall), the outline green, a magenta cross for none;
// and an _own sheet with each tap's outline alone, cropped to fit it.

// It reports by printing.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:spraywall/marks/hold_trace.dart';

const out = 'build/trace_eval';

// Taps in each photo's own pixels; the last ones are on bare wall.
const photos = {
  'sluppen': ('../sample/spray_sluppen.png', [
    (710, 480), (360, 820), (370, 540), (310, 120), (790, 680), (150, 590),
    (1200, 220), (960, 60), (874, 540), (260, 880), (1040, 530), (936, 910),
    (900, 340), (560, 220), (1100, 180), (300, 700), (520, 800),
    (100, 460), (1080, 780), (620, 1160), (430, 1330), (800, 1250),
    (1150, 300), (640, 400),
  ], [(1265, 700), (1280, 1150), (300, 1470), (1180, 1480)]),
  'plywood': ('../sample/IMG_20210522_093949634.jpg', [
    (1020, 200), (1560, 180), (820, 1088), (1440, 1220), (620, 392),
    (1960, 1688), (1820, 3460), (1500, 2172), (2740, 1180), (1188, 2880),
    (2092, 768), (220, 500), (1270, 1430), (1820, 2060),
  ], [(2400, 1800), (800, 3200), (1700, 900)]),
};

void main() {
  test('trace the sample photos', () {
    Directory(out).createSync(recursive: true);
    for (final MapEntry(key: name, value: (path, holds, bare)) in photos.entries) {
      if (!File(path).existsSync()) {
        print('$path: missing, skipped');
        continue;
      }
      final bytes = File(path).readAsBytesSync();
      var src = (path.endsWith('.png') ? img.decodePng(bytes) : img.decodeJpg(bytes))!;
      src = img.bakeOrientation(src).convert(numChannels: 4);
      final scale = 2560 / (src.width > src.height ? src.width : src.height);
      src = img.copyResize(src, width: (src.width * scale).round(),
          height: (src.height * scale).round(), interpolation: img.Interpolation.average);
      final px = PhotoPixels(src.width, src.height, src.getBytes(order: img.ChannelOrder.rgba));
      for (final radius in [0.15, 0.08]) {
        final canvas = img.Image.from(src).convert(numChannels: 3);
        var traced = 0, wallNull = 0, points = 0;
        final sw = Stopwatch()..start();
        final traces = <List<Offset>?>[];
        for (final (i, (x0, y0)) in [...holds, ...bare].indexed) {
          final x = (x0 * scale).round(), y = (y0 * scale).round();
          final o = traceHold(px, Offset(x / px.width, y / px.height), radius);
          traces.add(o);
          final onWall = i >= holds.length;
          img.fillCircle(canvas, x: x, y: y, radius: 8,
              color: onWall ? img.ColorRgb8(0, 0, 255) : img.ColorRgb8(0, 0, 0));
          if (o == null) {
            if (onWall) wallNull++;
            for (final d in [1, -1]) {
              img.drawLine(canvas, x1: x - 20, y1: y - 20 * d, x2: x + 20, y2: y + 20 * d,
                  color: img.ColorRgb8(255, 0, 255), thickness: 5);
            }
            continue;
          }
          if (!onWall) {
            traced++;
            points += o.length;
          }
          for (var k = 0; k < o.length; k++) {
            final a = o[k], b = o[(k + 1) % o.length];
            img.drawLine(canvas,
                x1: (a.dx * px.width).round(), y1: (a.dy * px.height).round(),
                x2: (b.dx * px.width).round(), y2: (b.dy * px.height).round(),
                color: img.ColorRgb8(0, 255, 0), thickness: 4);
          }
        }
        final ms = sw.elapsedMilliseconds / (holds.length + bare.length);
        print('$name r=$radius outlined $traced/${holds.length} holds, '
            'bare wall null $wallNull/${bare.length}, '
            '${(points / (traced == 0 ? 1 : traced)).toStringAsFixed(1)} points, '
            '${ms.toStringAsFixed(0)} ms/tap');
        // A contact sheet: each tap's surroundings, 6 across.
        final taps = [...holds, ...bare];
        const tile = 220, across = 6;
        final sheet = img.Image(width: tile * across,
            height: tile * ((taps.length + across - 1) ~/ across));
        final half = (radius * px.width * 0.6).round();
        for (final (i, (x0, y0)) in taps.indexed) {
          final x = (x0 * scale).round(), y = (y0 * scale).round();
          final crop = img.copyCrop(canvas, x: x - half, y: y - half,
              width: 2 * half, height: 2 * half);
          img.compositeImage(sheet, img.copyResize(crop, width: tile, height: tile),
              dstX: (i % across) * tile, dstY: (i ~/ across) * tile);
          img.drawString(sheet, '$i', font: img.arial24,
              x: (i % across) * tile + 4, y: (i ~/ across) * tile + 4,
              color: img.ColorRgb8(255, 255, 0));
        }
        File('$out/${name}_$radius.jpg')
            .writeAsBytesSync(img.encodeJpg(sheet));

        // Each tap alone: the clean photo cropped to its outline (with a
        // margin), only that outline drawn, so a leak into a neighbour shows.
        final own = img.Image(width: tile * across,
            height: tile * ((taps.length + across - 1) ~/ across));
        for (final (i, (x0, y0)) in taps.indexed) {
          final x = (x0 * scale).round(), y = (y0 * scale).round();
          final o = traces[i];
          var r = 60.0;
          for (final p in o ?? const <Offset>[]) {
            r = [r, (p.dx * px.width - x).abs(), (p.dy * px.height - y).abs()]
                .reduce((a, b) => a > b ? a : b);
          }
          final h = (r * 1.25).round();
          final crop = img.copyCrop(src, x: x - h, y: y - h,
              width: 2 * h, height: 2 * h).convert(numChannels: 3);
          if (o != null) {
            for (var k = 0; k < o.length; k++) {
              final a = o[k], b = o[(k + 1) % o.length];
              img.drawLine(crop,
                  x1: (a.dx * px.width).round() - x + h,
                  y1: (a.dy * px.height).round() - y + h,
                  x2: (b.dx * px.width).round() - x + h,
                  y2: (b.dy * px.height).round() - y + h,
                  color: img.ColorRgb8(0, 255, 0), thickness: (h / 60).ceil());
            }
          }
          img.fillCircle(crop, x: h, y: h, radius: (h / 30).ceil() + 2,
              color: img.ColorRgb8(0, 0, 0));
          img.compositeImage(own, img.copyResize(crop, width: tile, height: tile),
              dstX: (i % across) * tile, dstY: (i ~/ across) * tile);
          img.drawString(own, '$i', font: img.arial24,
              x: (i % across) * tile + 4, y: (i ~/ across) * tile + 4,
              color: img.ColorRgb8(255, 255, 0));
        }
        File('$out/${name}_${radius}_own.jpg')
            .writeAsBytesSync(img.encodeJpg(own));
      }
    }
  });
}
