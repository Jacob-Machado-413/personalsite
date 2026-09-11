import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'fish_model.dart';
import 'fish_widget.dart';
import 'stream_line_model.dart';

class FishBackground extends StatefulWidget {
  final int fishCount;
  final int streamLineCount;
  final Color fishColor;
  final double fishAlpha;
  final double fishSpeedMultiplier;
  final double minFishSize;
  final double maxFishSize;
  final Offset? mousePosition;

  const FishBackground({
    super.key,
    this.fishCount = 30,
    this.streamLineCount = 12,
    this.fishColor = Colors.blueAccent,
    this.fishAlpha = 0.18,
    this.fishSpeedMultiplier = 1.2,
    this.minFishSize = 25,
    this.maxFishSize = 60,
    this.mousePosition,
  });

  @override
  State<FishBackground> createState() => _FishBackgroundState();
}

class _FishBackgroundState extends State<FishBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<FishModel> _fishes = [];
  final List<StreamLineModel> _streamLines = [];
  final Random _random = Random();
  bool _initialized = false;
  Size? _lastSize;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _init(Size size) {
    if (_initialized) return;
    _initialized = true;
    _lastSize = size;

    for (int i = 0; i < widget.streamLineCount; i++) {
      _streamLines.add(
        StreamLineModel(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          length: 40 + _random.nextDouble() * 100,
          thickness: 1 + _random.nextDouble() * 1.5,
          speed:
              (0.3 + _random.nextDouble() * 0.7) *
              widget.fishSpeedMultiplier *
              0.4,
          opacity: 0.06 + _random.nextDouble() * 0.10,
        ),
      );
    }

    for (int i = 0; i < widget.fishCount; i++) {
      _fishes.add(
        FishModel(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          dx: (0.08 + _random.nextDouble() * 0.25) * widget.fishSpeedMultiplier,
          dy: (_random.nextDouble() - 0.5) * 0.2,
          color: widget.fishColor.withValues(alpha: widget.fishAlpha),
          size:
              widget.minFishSize +
              _random.nextDouble() * (widget.maxFishSize - widget.minFishSize),
        ),
      );
    }
  }

  void _tick(Duration elapsed) {
    if (!mounted) return;
    double dt = (elapsed.inMilliseconds - _lastTick.inMilliseconds) / 16.666;
    if (dt > 10.0) dt = 1.0;
    _lastTick = elapsed;

    final mediaSize = MediaQuery.of(context).size;
    if (mediaSize.width == 0 || mediaSize.height == 0) return;

    setState(() {
      if (_lastSize != null &&
          (mediaSize.width != _lastSize!.width ||
              mediaSize.height != _lastSize!.height)) {
        double sx = mediaSize.width / _lastSize!.width;
        double sy = mediaSize.height / _lastSize!.height;
        for (var f in _fishes) {
          f.x *= sx;
          f.y *= sy;
        }
        for (var l in _streamLines) {
          l.x *= sx;
          l.y *= sy;
        }
      }
      _lastSize = mediaSize;

      for (var f in _fishes) {
        f.update(dt, mediaSize, mousePosition: widget.mousePosition);
      }
      for (var l in _streamLines) {
        l.update(dt, mediaSize);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size.width > 0 && !_initialized) {
          _init(size);
        }
        return CustomPaint(
          painter: _FishBackgroundPainter(
            fishes: _fishes,
            streamLines: _streamLines,
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
      canvas.save();
      canvas.translate(fish.x, fish.y);
      canvas.rotate(atan2(fish.dy, fish.dx) + sin(fish.phase) * 0.2);
      FishPainter.drawFish(
        canvas,
        Size(fish.size * 1.5, fish.size),
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
