import 'dart:math';
import 'package:flutter/material.dart';

class FishModel {
  double x;
  double y;
  double dx;
  double dy;
  final double preferredDx;
  final double preferredY;
  final Color color;
  final double size;

  // Interaction variables
  final String? destinationRoute;
  final String? hoverTooltip;
  bool isHovered = false;

  // Animation state
  double phase = 0.0;

  bool get isInteractive => destinationRoute != null;

  FishModel({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.color,
    required this.size,
    this.destinationRoute,
    this.hoverTooltip,
  }) : preferredDx = dx,
       preferredY = y;

  void update(double dt, Size bounds, {Offset? mousePosition}) {
    if (isHovered) return;

    double baseSpeed = sqrt(dx * dx + dy * dy);
    // Advance the tail wag phase
    phase += baseSpeed * dt * 0.1;

    // Blue (non-interactive) fish gently swim away from the mouse cursor
    if (!isInteractive && mousePosition != null) {
      const double fleeRadius = 100.0;
      const double maxFleeForce = 0.12;
      double toMouseX = mousePosition.dx - x;
      double toMouseY = mousePosition.dy - y;
      double distToMouse = sqrt(toMouseX * toMouseX + toMouseY * toMouseY);
      if (distToMouse < fleeRadius && distToMouse > 0.001) {
        // Only flee vertically — preserve horizontal swimming direction
        double awayY = -toMouseY / distToMouse;
        // Quadratic falloff: barely perceptible at the edge, gentle near center
        double t = 1.0 - distToMouse / fleeRadius;
        double strength = t * t * maxFleeForce;
        // Fade flee force near top/bottom edges to prevent congregation
        const double edgeMargin = 40.0;
        double distToTop = y;
        double distToBottom = bounds.height - size - y;
        if (awayY < 0 && distToTop < edgeMargin) {
          strength *= distToTop / edgeMargin;
        } else if (awayY > 0 && distToBottom < edgeMargin) {
          strength *= distToBottom / edgeMargin;
        }
        dy += awayY * strength * dt;
      }
    }

    // Gently steer back toward the preferred horizontal direction
    // and nudge toward preferred Y (non-interactive fish only)
    if (!isInteractive) {
      const double velocityRestorationRate = 0.015;
      dx += (preferredDx - dx) * velocityRestorationRate * dt;

      // Nudge position directly toward preferred Y — avoids velocity accumulation
      const double positionRestorationRate = 0.002;
      y += (preferredY - y) * positionRestorationRate * dt;

      // Vertical damping: naturally decay dy to prevent runaway speeds.
      // Flee forces still add to dy temporarily (giving a natural tilt),
      // but damping brings it back to zero when the cursor is gone.
      dy *= (1.0 - 0.01 * dt);
    }

    // Pulse the forward movement speed to simulate thrust from the tail
    double thrustSpeed = baseSpeed * (1.0 + 0.4 * cos(phase * 2));

    // Calculate instantaneous angle matching the visual head movement
    double baseAngle = atan2(dy, dx);
    double instantAngle = baseAngle + sin(phase) * 0.2;

    x += cos(instantAngle) * thrustSpeed * dt;
    y += sin(instantAngle) * thrustSpeed * dt;

    // Wrap around horizontally
    if (x < -size * 2 && dx < 0) {
      x = bounds.width + size;
    } else if (x > bounds.width + size && dx > 0) {
      x = -size;
    }

    // Bounce vertically
    if (y <= 0) {
      y = 0;
      dy = -dy;
    } else if (y >= bounds.height - size) {
      y = bounds.height - size;
      dy = -dy;
    }
  }
}
