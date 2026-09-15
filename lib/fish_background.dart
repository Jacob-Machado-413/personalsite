import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'fish_model.dart';
import 'fish_widget.dart';
import 'school.dart';
import 'stream_line_model.dart';

class FishBackground extends StatefulWidget {
  final School? school;
  final SchoolConfig config;

  const FishBackground({super.key, this.config = const SchoolConfig()})
    : school = null;

  const FishBackground.shared(School this.school, {super.key})
    : config = const SchoolConfig();

  @override
  State<FishBackground> createState() => _FishBackgroundState();
}

class _FishBackgroundState extends State<FishBackground>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  School? _ownSchool;
  Duration _lastTick = Duration.zero;

  School get _school => widget.school ?? _ownSchool!;

  @override
  void initState() {
    super.initState();
    if (widget.school == null) {
      _ownSchool = School(config: widget.config);
      _ticker = createTicker(_tick)..start();
    }
  }

  void _tick(Duration elapsed) {
    if (!mounted) return;
    double dt =
        (elapsed.inMicroseconds - _lastTick.inMicroseconds) /
        (1000000.0 / 60.0);
    if (dt > 10.0) dt = 1.0; // Prevent huge jumps if suspended
    _lastTick = elapsed;

    final size = MediaQuery.of(context).size;
    if (size.isEmpty) return;

    setState(() {
      _ownSchool!.update(dt, size);
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size.width > 0) _school.populate(size);

        return CustomPaint(
          painter: _FishBackgroundPainter(
            fishes: _school.schoolFish,
            streamLines: _school.streamLines,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _FishBackgroundPainter extends CustomPainter {
  final List<FishModel> fishes;
  final List<StreamLineModel> streamLines;

  _FishBackgroundPainter({required this.fishes, required this.streamLines});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..style = PaintingStyle.fill;
    for (var line in streamLines) {
      linePaint.color = Colors.white.withValues(alpha: line.opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(line.x, line.y, line.length, line.thickness),
          Radius.circular(line.thickness / 2),
        ),
        linePaint,
      );
    }

    for (var fish in fishes) {
      final double width = fish.size * 1.5;
      final double height = fish.size;

      canvas.save();
      // Rotate about the fish's centre. Rotating about the corner swings the body
      // through an arc on every heading change, amplifying small course corrections.
      canvas.translate(fish.x + width / 2, fish.y + height / 2);
      canvas.rotate(fish.heading);
      canvas.translate(-width / 2, -height / 2);
      FishPainter.drawFish(
        canvas,
        Size(width, height),
        fish.color,
        fish.phase,
        false,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FishBackgroundPainter old) => true;
}
