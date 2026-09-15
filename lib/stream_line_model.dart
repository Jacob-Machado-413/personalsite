import 'package:flutter/material.dart';
import 'current.dart';

class StreamLineModel {
  double x;
  double y;
  final double length;
  final double thickness;
  final double speed;
  final double opacity;

  StreamLineModel({
    required this.x,
    required this.y,
    required this.length,
    required this.thickness,
    required this.speed,
    required this.opacity,
  });

  void update(double dt, Size bounds, double time) {
    final Offset flow = Current.at(x, y, time);
    x += flow.dx * speed * dt;
    y += flow.dy * speed * dt;
    if (x > bounds.width + length) {
      x = -length;
    } else if (x < -length * 2) {
      x = bounds.width + length;
    }
    if (bounds.height > 0) {
      y = y.clamp(0.0, bounds.height);
    }
  }
}
