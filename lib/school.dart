import 'dart:math';
import 'package:flutter/material.dart';
import 'boid.dart';
import 'current.dart';
import 'fish_model.dart';
import 'projects.dart';
import 'stream_line_model.dart';

class FlockTuning {
  static const double neighbourRadius = 95;
  static const double cohesionDeadzone = 40;
  static const double edgeMargin = 100;

  static const double avoidLateral = 0.75;

  const FlockTuning._();
}

class FlockProfile {
  const FlockProfile({
    required this.separation,
    required this.separationRadius,
    required this.alignment,
    required this.cohesion,
    required this.current,
    required this.edge,
    required this.avoid,
    required this.avoidRadius,
    required this.maxSpeed,
    required this.minSpeed,
    required this.maxForce,
    required this.maxTurn,
  });

  final double separation;
  final double separationRadius;
  final double alignment;
  final double cohesion;
  final double current;
  final double edge;
  final double avoid;
  final double avoidRadius;

  final double maxSpeed;
  final double minSpeed;
  final double maxForce;
  final double maxTurn;

  static const FlockProfile school = FlockProfile(
    separation: 1.9,
    separationRadius: 34,
    alignment: 1.0,
    cohesion: 0.9,
    current: 0.60,
    edge: 2.2,
    avoid: 8.0,
    avoidRadius: 300,
    maxSpeed: 0.95,
    minSpeed: 0.30,
    maxForce: 0.022,
    maxTurn: 0.08,
  );

  static const FlockProfile item = FlockProfile(
    separation: 1.9,
    separationRadius: 120,
    alignment: 1.0,
    cohesion: 0.9,
    current: 0.85,
    edge: 2.2,
    avoid: 0.0,
    avoidRadius: 0,
    maxSpeed: 2.20,
    minSpeed: 1.60,
    maxForce: 0.070,
    maxTurn: 0.14,
  );
}

class SchoolConfig {
  final int fishCount;
  final int streamLineCount;
  final Color fishColor;
  final double fishAlpha;
  final double fishSpeedMultiplier;
  final double minFishSize;
  final double maxFishSize;

  const SchoolConfig({
    this.fishCount = 30,
    this.streamLineCount = 12,
    this.fishColor = Colors.blueAccent,
    this.fishAlpha = 0.18,
    this.fishSpeedMultiplier = 1.2,
    this.minFishSize = 25,
    this.maxFishSize = 60,
  });
}

class School {
  School({
    this.config = const SchoolConfig(),
    this.destinations = const [],
    this.itemProfile = FlockProfile.item,
    this.schoolProfile = FlockProfile.school,
    int? seed,
  }) : _random = Random(seed);

  final SchoolConfig config;
  final List<FishDestination> destinations;
  final FlockProfile itemProfile;
  final FlockProfile schoolProfile;

  final List<FishModel> schoolFish = [];
  final List<FishModel> itemFish = [];
  final List<FishModel> allFish = [];
  final List<StreamLineModel> streamLines = [];

  static const Color itemFishColor = Colors.redAccent;

  final Random _random;
  Size? _lastSize;
  bool _populated = false;
  double _time = 0;

  void populate(Size size) {
    if (_populated || size.isEmpty) return;
    _populated = true;
    _lastSize = size;

    _addStreamLines(size);
    _addSchoolFish(size);
    _addItemFish(size);
    allFish
      ..addAll(schoolFish)
      ..addAll(itemFish);
  }

  void _addStreamLines(Size size) {
    for (int i = 0; i < config.streamLineCount; i++) {
      streamLines.add(
        StreamLineModel(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          length: 40 + _random.nextDouble() * 100,
          thickness: 1 + _random.nextDouble() * 1.5,
          speed:
              (0.3 + _random.nextDouble() * 0.7) *
              config.fishSpeedMultiplier *
              0.64,
          opacity: 0.06 + _random.nextDouble() * 0.10,
        ),
      );
    }
  }

  void _addSchoolFish(Size size) {
    final profile = schoolProfile;
    for (int i = 0; i < config.fishCount; i++) {
      schoolFish.add(
        FishModel(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          dx: (0.08 + _random.nextDouble() * 0.25) * config.fishSpeedMultiplier,
          dy: (_random.nextDouble() - 0.5) * 0.2,
          color: config.fishColor.withValues(alpha: config.fishAlpha),
          size:
              config.minFishSize +
              _random.nextDouble() * (config.maxFishSize - config.minFishSize),
          maxSpeed: profile.maxSpeed,
          minSpeed: profile.minSpeed,
          maxForce: profile.maxForce,
          maxTurnPerFrame: profile.maxTurn,
        ),
      );
    }
  }

  void _addItemFish(Size size) {
    if (destinations.isEmpty) return;

    final profile = itemProfile;
    final band = size.height / destinations.length;
    for (int i = 0; i < destinations.length; i++) {
      final destination = destinations[i];
      final fishSize = 60 + _random.nextDouble() * 20;
      final double y = (band * i + _random.nextDouble() * band)
          .clamp(0.0, max(0.0, size.height - fishSize))
          .toDouble();

      itemFish.add(
        FishModel(
          x: _random.nextDouble() * size.width,
          y: y,
          dx: -profile.maxSpeed * (0.6 + _random.nextDouble() * 0.4),
          dy: (_random.nextDouble() - 0.5) * 0.6,
          color: itemFishColor,
          size: fishSize,
          maxSpeed: profile.maxSpeed,
          minSpeed: profile.minSpeed,
          maxForce: profile.maxForce,
          maxTurnPerFrame: profile.maxTurn,
          destinationRoute: destination.route,
          hoverTooltip: destination.label,
        ),
      );
    }
  }

  void update(double dt, Size bounds) {
    if (bounds.isEmpty) return;
    _time += dt;
    _redistribute(bounds);

    _flock(dt, bounds);

    for (final fish in allFish) {
      fish.update(dt, bounds);
    }
    for (final line in streamLines) {
      line.update(dt, bounds, _time);
    }
  }

  void _flock(double dt, Size bounds) {
    if (allFish.isEmpty) return;

    // Forces accumulate here and are applied by [FishModel.update], so every
    // fish steers off the same snapshot. Committing inside the scan would let
    // later fish read updated neighbours, which sets the school shivering.
    for (final fish in allFish) {
      if (fish.isHovered) continue;
      final FlockProfile profile = fish.isInteractive
          ? itemProfile
          : schoolProfile;

      Offset separation = Offset.zero;
      Offset alignment = Offset.zero;
      Offset cohesion = Offset.zero;
      Offset makeWay = Offset.zero;
      double separationWeight = 0;
      double neighbourWeight = 0;
      double makeWayWeight = 0;

      final double scan = max(
        FlockTuning.neighbourRadius,
        max(profile.separationRadius, profile.avoidRadius),
      );
      final double scanSq = scan * scan;

      for (final other in allFish) {
        if (identical(other, fish)) continue;

        final Offset delta = _wrappedDelta(fish, other, bounds.width);
        final double distanceSq = delta.dx * delta.dx + delta.dy * delta.dy;
        if (distanceSq < 1e-9 || distanceSq > scanSq) continue;

        final double distance = sqrt(distanceSq);

        if (profile.avoid > 0 &&
            other.isInteractive &&
            !fish.isInteractive &&
            distance < profile.avoidRadius) {
          final (Offset push, double urgency) = _makeWay(
            delta,
            distance,
            other,
            profile.avoidRadius,
          );
          makeWay += push * urgency;
          makeWayWeight += urgency;
        }

        if (distance < profile.separationRadius) {
          final double push = 1.0 - distance / profile.separationRadius;
          separation -= delta * (push / distance);
          separationWeight += push;
        }

        if (distance > FlockTuning.neighbourRadius) continue;

        final double influence = 1.0 - distance / FlockTuning.neighbourRadius;
        alignment += other.velocity * influence;
        cohesion += delta * influence;
        neighbourWeight += influence;
      }

      Offset steering = Offset.zero;

      if (separationWeight > 0) {
        final Offset average = separation * (1.0 / separationWeight);
        steering +=
            _steer(fish, average, average.distance) * profile.separation;
      }

      // A fish stepping aside stops trying to hold formation. Without this the
      // shoal drags it straight back into the lane it just cleared.
      final double yielding = makeWayWeight.clamp(0.0, 1.0);
      final double holding = 1.0 - yielding;

      if (neighbourWeight > 0 && holding > 0) {
        final Offset meanVelocity = alignment * (1.0 / neighbourWeight);
        steering +=
            _steer(fish, meanVelocity, meanVelocity.distance / fish.maxSpeed) *
            profile.alignment *
            holding;

        final Offset toCentroid = cohesion * (1.0 / neighbourWeight);
        steering +=
            _steer(
              fish,
              toCentroid,
              toCentroid.distance / FlockTuning.cohesionDeadzone,
            ) *
            profile.cohesion *
            holding;
      }

      if (yielding > 0) {
        final Offset clear = makeWay * (1.0 / makeWayWeight);
        steering += _steer(fish, clear, yielding) * profile.avoid;
      }

      final Offset flow = Current.at(fish.x, fish.y, _time);
      steering += _steer(fish, flow, 1.0) * profile.current;

      final (Offset edgeDirection, double edgeStrength) = _edge(fish, bounds);
      if (edgeStrength > 0) {
        steering += _steer(fish, edgeDirection, edgeStrength) * profile.edge;
      }

      fish.applyForce(steering);
    }
  }

  /// Steering toward [direction], scaled by how clear the signal is — a fish in
  /// near-perfect balance shouldn't shout in the rounding error's direction.
  Offset _steer(FishModel fish, Offset direction, double strength) {
    final double length = direction.distance;
    final double clamped = strength.clamp(0.0, 1.0);
    if (length < 1e-9 || clamped <= 0) return Offset.zero;

    final Offset desired = direction * (fish.maxSpeed / length);
    return limit(desired - fish.velocity, fish.maxForce * clamped);
  }

  /// Short way around the horizontal wrap, or a wrapped fish is dragged back.
  Offset _wrappedDelta(FishModel from, FishModel to, double width) {
    double dx = to.x - from.x;
    if (width > 0) {
      if (dx > width / 2) {
        dx -= width;
      } else if (dx < -width / 2) {
        dx += width;
      }
    }
    return Offset(dx, to.y - from.y);
  }

  /// Step aside for [mover]. The push is mostly perpendicular to where it is
  /// going, so a fish clears the lane instead of being shoved along it, and it
  /// only applies to fish actually in the way — you don't dodge what's behind.
  (Offset, double) _makeWay(
    Offset delta,
    double distance,
    FishModel mover,
    double radius,
  ) {
    final Offset away = delta * (-1.0 / distance);
    final double ramp = 1.0 - distance / radius;

    final double speed = mover.speed;
    if (speed < 1e-9) return (away, ramp * ramp);

    final Offset heading = mover.velocity * (1.0 / speed);
    final double facing =
        (-(delta.dx * heading.dx + delta.dy * heading.dy) / distance).clamp(
          0.0,
          1.0,
        );
    if (facing <= 0) return (Offset.zero, 0.0);

    final double along = away.dx * heading.dx + away.dy * heading.dy;
    final Offset lateral = away - heading * along;
    final double lateralLength = lateral.distance;
    if (lateralLength < 1e-6) return (away, ramp * ramp * facing);

    final Offset push =
        lateral * (FlockTuning.avoidLateral / lateralLength) +
        away * (1.0 - FlockTuning.avoidLateral);
    return (push, ramp * ramp * facing);
  }

  (Offset, double) _edge(FishModel fish, Size bounds) {
    const double margin = FlockTuning.edgeMargin;
    final double fromTop = fish.y;
    final double fromBottom = bounds.height - fish.size - fish.y;

    if (fromTop < margin) {
      final double ramp = 1.0 - fromTop / margin;
      return (Offset(fish.dx, fish.maxSpeed), ramp);
    }
    if (fromBottom < margin) {
      final double ramp = 1.0 - fromBottom / margin;
      return (Offset(fish.dx, -fish.maxSpeed), ramp);
    }
    return (Offset.zero, 0.0);
  }

  void _redistribute(Size bounds) {
    final previous = _lastSize;
    _lastSize = bounds;
    if (previous == null || previous.isEmpty) return;
    if (previous.width == bounds.width && previous.height == bounds.height) {
      return;
    }

    final scaleX = bounds.width / previous.width;
    final scaleY = bounds.height / previous.height;

    for (final fish in allFish) {
      fish.x *= scaleX;
      fish.y *= scaleY;
    }
    for (final line in streamLines) {
      line.x *= scaleX;
      line.y *= scaleY;
    }
  }
}
