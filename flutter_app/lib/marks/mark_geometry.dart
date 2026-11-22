import 'dart:math' as math;
import 'dart:ui';
import '../database/tables.dart' show Role;

// A mark is stored normalised: cx and cy are 0..1 of the photo's width and
// height, and r is a fraction of its **width**, so a circle stays round on a
// portrait photo. Widgets work in photo pixels, the coordinate space of the
// box inside the InteractiveViewer.

/// A new mark's radius on a photo with none placed yet: about a hand hold on
/// a whole-wall photo.
const kDefaultMarkR = 0.018;

/// Radius limits, as fractions of photo width: from a kicker foot chip on a
/// whole-wall photo to a big volume on a close-up.
const kMinMarkR = 0.003;
const kMaxMarkR = 0.15;

/// Unselected marks stay at least this easy to hit, in screen pixels.
const kMinHitScreenPx = 20.0;

/// The resize handle's size, in screen pixels.
const kHandleScreenPx = 26.0;

/// Role colours, from the prototype.
const roleColors = {
  Role.start:  Color(0xFF00E676),
  Role.hand:   Color(0xFF00B0FF),
  Role.foot:   Color(0xFFD500F9),
  Role.finish: Color(0xFFFF1744),
};

/// A role's name on screen and in a share image's legend.
String roleLabel(Role r) => switch (r) {
      Role.start  => 'Start',
      Role.hand   => 'Hand',
      Role.foot   => 'Foot',
      Role.finish => 'Finish',
    };

/// A mark's centre in photo pixels.
Offset centrePx(double cx, double cy, Size photo) =>
    Offset(cx * photo.width, cy * photo.height);

/// A mark's radius in photo pixels.
double radiusPx(double r, Size photo) => r * photo.width;

/// A point in photo pixels as normalised coordinates, kept on the photo.
(double, double) normalise(Offset px, Size photo) => (
      (px.dx / photo.width).clamp(0.0, 1.0),
      (px.dy / photo.height).clamp(0.0, 1.0),
    );

/// [r] kept within [kMinMarkR]..[kMaxMarkR].
double clampRadius(double r) => r.clamp(kMinMarkR, kMaxMarkR);

/// How far from its centre, in photo pixels, a mark of [rPx] takes a tap at
/// [zoom] (screen px per photo px): its circle, or [kMinHitScreenPx] on
/// screen, whichever is bigger.
double hitRadiusPx(double rPx, double zoom) =>
    math.max(rPx, kMinHitScreenPx / zoom);

/// Whether a tap at [point] (photo px) lands on a mark centred at [centre].
bool hitsMark(Offset point, Offset centre, double rPx, double zoom) =>
    (point - centre).distance <= hitRadiusPx(rPx, zoom);
