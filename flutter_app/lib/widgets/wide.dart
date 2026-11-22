import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// At or above this width a screen lays out for a wide window: the photo
/// strip as a left column, the palette or details as a right side bar.
/// Each screen measures its own space with a [LayoutBuilder], never the
/// platform, so a landscape phone counts and a narrow desktop window doesn't.
const wideWidth = 600.0;

/// Lists grow no wider than this, so a row reads at a glance.
const readableWidth = 720.0;

bool isWide(BoxConstraints c) => c.maxWidth >= wideWidth;

/// A list capped at [readableWidth] and centred. [builder] gets the side
/// insets to add to its scroll view's padding: the scroll view itself stays
/// window-wide, so the wheel and the scrollbar work anywhere across it.
class ReadableWidth extends StatelessWidget {
  final Widget Function(BuildContext context, EdgeInsets sides) builder;
  const ReadableWidth({super.key, required this.builder});

  static EdgeInsets sidesFor(double width) => EdgeInsets.symmetric(
      horizontal: math.max(0, (width - readableWidth) / 2));

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, c) => builder(context, sidesFor(c.maxWidth)));
}
