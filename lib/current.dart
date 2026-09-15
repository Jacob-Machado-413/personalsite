import 'dart:math';
import 'dart:ui';

/// The water everything drifts in: rightward on average, sheared so speed and
/// angle vary with position and time, so the school never moves as one block.
class Current {
  static const double base = 0.62;
  static const double shear = 0.34;
  static const double lift = 0.20;

  static const double bandHeight = 520.0;

  static const double swellLength = 880.0;

  static const double drift = 0.013; // radians per frame-unit

  static Offset at(double x, double y, double time) {
    final double phase = time * drift;
    return Offset(
      base + shear * sin(y / bandHeight * 2 * pi + phase),
      lift * sin(x / swellLength * 2 * pi - phase * 1.3),
    );
  }

  const Current._();
}
