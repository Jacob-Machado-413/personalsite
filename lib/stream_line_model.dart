import 'package:flutter/material.dart';

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

  void update(double dt, Size bounds) {
    x += speed * dt;
    if (x > bounds.width + length) {
      x = -length;
    }
  }
}
