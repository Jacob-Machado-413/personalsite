import 'dart:math';
import 'package:flutter/material.dart';
import 'boid.dart';
import 'fish_model.dart';
import 'projects.dart';
import 'stream_line_model.dart';

class FlockTuning {
  static const double separationRadius = 34;
  static const double neighbourRadius = 95;
  static const double cohesionDeadzone = 40;
  static const double edgeMargin = 100;
  static const double fleeRadius = 130;

  const FlockTuning._();
}

class FlockProfile {
  const FlockProfile({
    required this.separation,
    required this.alignment,
    required this.cohesion,
    required this.cruise,
    required this.cruiseVelocity,
    required this.edge,
    required this.flee,
    required this.maxSpeed,
    required this.minSpeed,
    required this.maxForce,
    required this.maxTurn,
  });

  final double separation;
  final double alignment;
  final double cohesion;
  final double cruise;
  final Offset cruiseVelocity;
  final double edge;
  final double flee;

  final double maxSpeed;
  final double minSpeed;
  final double maxForce;
  final double maxTurn;

  static const FlockProfile school = FlockProfile(
    separation: 1.9,
    alignment: 1.0,
    cohesion: 0.9,
    cruise: 0.45,
    cruiseVelocity: Offset(0.55, 0),
    edge: 2.2,
    flee: 3.2,
    maxSpeed: 0.95,
    minSpeed: 0.30,
    maxForce: 0.022,
    maxTurn: 0.08,
  );

  /// Red fish are full members of the school, so at this cruise weight the
  /// shoal wins and carries them rightward with it. Cruise has to clear ~1.0
  /// to beat alignment and pull a red fish left; see [School.itemProfile].
  static const FlockProfile item = FlockProfile(
    separation: 1.9,
    alignment: 1.0,
    cohesion: 0.9,
    cruise: 0.18,
    cruiseVelocity: Offset(-0.9, 0),
    edge: 2.2,
    flee: 3.2,
    maxSpeed: 1.25,
    minSpeed: 0.45,
    maxForce: 0.026,
    maxTurn: 0.10,
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
  });

  final SchoolConfig config;
  final List<FishDestination> destinations;
  final FlockProfile itemProfile;

  final List<FishModel> schoolFish = [];
  final List<FishModel> itemFish = [];
  final List<FishModel> allFish = [];
  final List<StreamLineModel> streamLines = [];

  static const Color itemFishColor = Colors.redAccent;

  final Random _random = Random();
  Size? _lastSize;
  bool _populated = false;

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
              0.4,
          opacity: 0.06 + _random.nextDouble() * 0.10,
        ),
      );
    }
  }

  void _addSchoolFish(Size size) {
    const profile = FlockProfile.school;
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
          dx: -(0.6 + _random.nextDouble() * 0.5),
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

  void update(double dt, Size bounds, {Offset? mousePosition}) {
    if (bounds.isEmpty) return;
    _redistribute(bounds);

    _flock(dt, bounds, mousePosition);

    for (final fish in allFish) {
      fish.update(dt, bounds);
    }
    for (final line in streamLines) {
      line.update(dt, bounds);
    }
  }

  void _flock(double dt, Size bounds, Offset? mousePosition) {
    if (allFish.isEmpty) return;

    // Forces accumulate here and are applied by [FishModel.update], so every
    // fish steers off the same snapshot. Committing inside the scan would let
    // later fish read updated neighbours, which sets the school shivering.
    for (final fish in allFish) {
      if (fish.isHovered) continue;
      final FlockProfile profile = fish.isInteractive
          ? itemProfile
          : FlockProfile.school;

      Offset separation = Offset.zero;
      Offset alignment = Offset.zero;
      Offset cohesion = Offset.zero;
      double separationWeight = 0;
      double neighbourWeight = 0;

      for (final other in allFish) {
        if (identical(other, fish)) continue;

        final Offset delta = _wrappedDelta(fish, other, bounds.width);
        final double distanceSq = delta.dx * delta.dx + delta.dy * delta.dy;
        if (distanceSq >
                FlockTuning.neighbourRadius * FlockTuning.neighbourRadius ||
            distanceSq < 1e-9) {
          continue;
        }

        final double distance = sqrt(distanceSq);
        final double influence = 1.0 - distance / FlockTuning.neighbourRadius;

        alignment += other.velocity * influence;
        cohesion += delta * influence;
        neighbourWeight += influence;

        if (distance < FlockTuning.separationRadius) {
          final double push = 1.0 - distance / FlockTuning.separationRadius;
          separation -= delta * (push / distance);
          separationWeight += push;
        }
      }

      Offset steering = Offset.zero;

      if (separationWeight > 0) {
        final Offset average = separation * (1.0 / separationWeight);
        steering +=
            _steer(fish, average, average.distance) * profile.separation;
      }

      if (neighbourWeight > 0) {
        final Offset meanVelocity = alignment * (1.0 / neighbourWeight);
        steering +=
            _steer(fish, meanVelocity, meanVelocity.distance / fish.maxSpeed) *
            profile.alignment;

        final Offset toCentroid = cohesion * (1.0 / neighbourWeight);
        steering +=
            _steer(
              fish,
              toCentroid,
              toCentroid.distance / FlockTuning.cohesionDeadzone,
            ) *
            profile.cohesion;
      }

      steering += _steer(fish, profile.cruiseVelocity, 1.0) * profile.cruise;

      final (Offset edgeDirection, double edgeStrength) = _edge(fish, bounds);
      if (edgeStrength > 0) {
        steering += _steer(fish, edgeDirection, edgeStrength) * profile.edge;
      }

      final (Offset fleeDirection, double fleeStrength) = _flee(
        fish,
        mousePosition,
      );
      if (fleeStrength > 0) {
        steering += _steer(fish, fleeDirection, fleeStrength) * profile.flee;
      }

      fish.applyForce(steering);
    }
  }

  /// Steering force toward [direction], scaled by how clear the signal is —
  /// a fish in near-perfect balance shouldn't shout in the rounding error's
  /// direction, which is what normalising every behaviour to full speed does.
  Offset _steer(FishModel fish, Offset direction, double strength) {
    final double length = direction.distance;
    final double clamped = strength.clamp(0.0, 1.0);
    if (length < 1e-9 || clamped <= 0) return Offset.zero;

    final Offset desired = direction * (fish.maxSpeed / length);
    return limit(desired - fish.velocity, fish.maxForce * clamped);
  }

  /// Takes the short way around the horizontal wrap. Without it, a fish that
  /// wraps is a screen-width from its school and gets dragged straight back.
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

  (Offset, double) _flee(FishModel fish, Offset? mousePosition) {
    if (mousePosition == null) return (Offset.zero, 0.0);

    final Offset away = fish.position - mousePosition;
    final double distance = away.distance;
    if (distance < 1e-9 || distance > FlockTuning.fleeRadius) {
      return (Offset.zero, 0.0);
    }

    final double ramp = 1.0 - distance / FlockTuning.fleeRadius;
    return (away, ramp * ramp);
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
