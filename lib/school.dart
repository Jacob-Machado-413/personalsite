import 'dart:math';
import 'package:flutter/material.dart';
import 'fish_model.dart';
import 'projects.dart';
import 'stream_line_model.dart';

/// Tuning for the background school and its stream lines.
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

/// Every fish on screen, in one simulation.
///
/// Background fish and the interactive item fish used to live in two separate
/// widgets with a Ticker each, so neither could see the other. They share a
/// School now, which is what lets item fish steer around the school they swim
/// through. Nothing here touches Flutter's scheduler — whoever owns the ticker
/// calls [update].
class School {
  /// Red fish are spawned one per destination; empty means background only,
  /// which is how the content pages use it.
  School({this.config = const SchoolConfig(), this.destinations = const []});

  final SchoolConfig config;
  final List<FishDestination> destinations;

  final List<FishModel> schoolFish = [];
  final List<FishModel> itemFish = [];
  final List<StreamLineModel> streamLines = [];

  static const Color itemFishColor = Colors.redAccent;
  static const double itemFishSpeedMultiplier = 4.0;

  final Random _random = Random();
  Size? _lastSize;
  bool _populated = false;

  bool get populated => _populated;

  /// Every fish in the simulation, background and interactive alike.
  Iterable<FishModel> get allFish => [...schoolFish, ...itemFish];

  /// Fill the tank. Idempotent, so it is safe to call from a build.
  void populate(Size size) {
    if (_populated || size.isEmpty) return;
    _populated = true;
    _lastSize = size;

    _addStreamLines(size);
    _addSchoolFish(size);
    _addItemFish(size);
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
        ),
      );
    }
  }

  void _addItemFish(Size size) {
    if (destinations.isEmpty) return;

    // Evenly spaced horizontal bands with a little jitter, so they don't all
    // start stacked on top of each other.
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
          dx: _itemFishDx(),
          dy: (_random.nextDouble() - 0.5) * 0.6, // Reduced vertical drift
          color: itemFishColor,
          size: fishSize,
          destinationRoute: destination.route,
          hoverTooltip: destination.label,
        ),
      );
    }
  }

  /// Red fish only swim left, and never slowly enough to look becalmed.
  double _itemFishDx() {
    final dx = -(_random.nextDouble() * 0.5) * itemFishSpeedMultiplier;
    return dx > -1.5 ? -1.5 : dx;
  }

  /// Step everything one frame.
  void update(double dt, Size bounds, {Offset? mousePosition}) {
    if (bounds.isEmpty) return;
    _redistribute(bounds);

    for (final fish in schoolFish) {
      fish.update(dt, bounds, mousePosition: mousePosition);
    }
    for (final fish in itemFish) {
      fish.update(dt, bounds, mousePosition: mousePosition);
    }
    for (final line in streamLines) {
      line.update(dt, bounds);
    }
  }

  /// Keep everyone proportionally placed when the window resizes.
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
