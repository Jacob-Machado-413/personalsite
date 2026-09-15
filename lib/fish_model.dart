import 'package:flutter/material.dart';
import 'boid.dart';

class FishModel extends Boid {
  final Color color;
  final double size;

  final String? destinationRoute;
  final String? hoverTooltip;
  bool isHovered = false;

  double phase = 0.0;

  final double minSpeed;

  FishModel({
    required double x,
    required double y,
    required double dx,
    required double dy,
    required this.color,
    required this.size,
    required super.maxSpeed,
    required super.maxForce,
    required this.minSpeed,
    double maxTurnPerFrame = 0.08,
    this.destinationRoute,
    this.hoverTooltip,
  }) : super(
         position: Offset(x, y),
         velocity: Offset(dx, dy),
         maxTurnRate: maxTurnPerFrame,
       );

  bool get isInteractive => destinationRoute != null;

  double get x => position.dx;
  set x(double value) => position = Offset(value, position.dy);

  double get y => position.dy;
  set y(double value) => position = Offset(position.dx, value);

  double get dx => velocity.dx;
  set dx(double value) => velocity = Offset(value, velocity.dy);

  double get dy => velocity.dy;
  set dy(double value) => velocity = Offset(velocity.dx, value);

  void update(double dt, Size bounds) {
    if (isHovered) return;

    integrate(dt);

    final double currentSpeed = speed;
    if (currentSpeed < minSpeed) {
      velocity = currentSpeed == 0
          ? Offset(minSpeed, 0)
          : velocity * (minSpeed / currentSpeed);
    }

    phase += currentSpeed * dt * 0.1;

    double px = position.dx;
    double py = position.dy;
    double vy = velocity.dy;

    if (px < -size * 2 && velocity.dx < 0) {
      px = bounds.width + size;
    } else if (px > bounds.width + size && velocity.dx > 0) {
      px = -size;
    }

    if (py <= 0) {
      py = 0;
      vy = vy.abs();
    } else if (py >= bounds.height - size) {
      py = bounds.height - size;
      vy = -vy.abs();
    }

    position = Offset(px, py);
    if (vy != velocity.dy) velocity = Offset(velocity.dx, vy);
  }
}
