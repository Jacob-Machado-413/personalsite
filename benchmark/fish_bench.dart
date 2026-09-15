import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:site/fish_model.dart';
import 'package:site/fish_widget.dart';
import 'package:site/projects.dart';
import 'package:site/school.dart';

const int kBackgroundFish = 80; // home page config
const int kItemFish = 5; // About Me + 4 projects
const int kFrames = 2000;
const int kRepeats = 5;
const Size kBounds = Size(1600, 900);

List<FishModel> buildFish() {
  final random = Random(1234); // fixed seed: same fish every run
  final fish = <FishModel>[];

  for (int i = 0; i < kBackgroundFish; i++) {
    fish.add(
      FishModel(
        x: random.nextDouble() * kBounds.width,
        y: random.nextDouble() * kBounds.height,
        dx: (0.08 + random.nextDouble() * 0.25) * 3.0,
        dy: (random.nextDouble() - 0.5) * 0.2,
        color: Colors.blueAccent.withValues(alpha: 0.2),
        size: 40 + random.nextDouble() * 30,
        maxSpeed: FlockProfile.school.maxSpeed,
        minSpeed: FlockProfile.school.minSpeed,
        maxForce: FlockProfile.school.maxForce,
      ),
    );
  }
  for (int i = 0; i < kItemFish; i++) {
    fish.add(
      FishModel(
        x: random.nextDouble() * kBounds.width,
        y: random.nextDouble() * kBounds.height,
        dx: -1.5,
        dy: (random.nextDouble() - 0.5) * 0.6,
        color: Colors.redAccent,
        size: 60 + random.nextDouble() * 20,
        maxSpeed: FlockProfile.item.maxSpeed,
        minSpeed: FlockProfile.item.minSpeed,
        maxForce: FlockProfile.item.maxForce,
        destinationRoute: '/x',
        hoverTooltip: 'x',
      ),
    );
  }
  return fish;
}

double measure(void Function() frame) {
  for (int i = 0; i < 300; i++) {
    frame();
  }

  final samples = <double>[];
  for (int r = 0; r < kRepeats; r++) {
    final sw = Stopwatch()..start();
    for (int i = 0; i < kFrames; i++) {
      frame();
    }
    sw.stop();
    samples.add(sw.elapsedMicroseconds / kFrames);
  }
  samples.sort();
  return samples[samples.length ~/ 2];
}

void report(String label, double usPerFrame) {
  final ms = usPerFrame / 1000.0;
  final budget = (ms / 16.667 * 100).toStringAsFixed(1);
  debugPrint(
    'BENCH  ${label.padRight(28)} '
    '${ms.toStringAsFixed(3)} ms/frame   '
    '${budget.padLeft(5)}% of a 60fps budget',
  );
}

void main() {
  test('fish benchmark', () {
    debugPrint(
      'BENCH  fish=${kBackgroundFish + kItemFish} '
      'frames=$kFrames repeats=$kRepeats',
    );

    final mouse = Offset(kBounds.width * 0.5, kBounds.height * 0.5);

    School freshSchool() => School(
      config: const SchoolConfig(
        fishCount: kBackgroundFish,
        streamLineCount: 15,
        fishSpeedMultiplier: 3.0,
        minFishSize: 40,
        maxFishSize: 70,
      ),
      destinations: kFishDestinations,
    )..populate(kBounds);

    final school = freshSchool();
    report(
      'sim: flock (85), no cursor',
      measure(() {
        school.update(1.0, kBounds);
      }),
    );

    final school2 = freshSchool();
    report(
      'sim: flock (85), cursor',
      measure(() {
        school2.update(1.0, kBounds, mousePosition: mouse);
      }),
    );

    final paintFish = buildFish();
    for (int i = 0; i < paintFish.length; i++) {
      paintFish[i].phase = i * 0.3; // spread the tail phases
    }

    report(
      'paint: 85 fish to a Picture',
      measure(() {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        for (final f in paintFish) {
          canvas.save();
          canvas.translate(f.x, f.y);
          canvas.rotate(atan2(f.dy, f.dx) + sin(f.phase) * 0.2);
          FishPainter.drawFish(
            canvas,
            Size(f.size * 1.5, f.size),
            f.color,
            f.phase,
            false,
          );
          canvas.restore();
        }
        recorder.endRecording().dispose();
      }),
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
