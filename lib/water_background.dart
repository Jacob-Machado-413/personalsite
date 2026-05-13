import 'dart:ui';
import 'package:flutter/material.dart';

class WaterBackground extends StatefulWidget {
  final Color topColor;
  final Color bottomColor;
  final Widget child;
  final double time;

  const WaterBackground({
    super.key,
    required this.topColor,
    required this.bottomColor,
    required this.child,
    this.time = 0.0,
  });

  @override
  State<WaterBackground> createState() => _WaterBackgroundState();
}

class _WaterBackgroundState extends State<WaterBackground> {
  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      FragmentProgram program = await FragmentProgram.fromAsset(
        'shaders/water.frag',
      );
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
        });
      }
    } catch (e) {
      debugPrint("Failed to load shader: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) {
      // Fallback while loading
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [widget.topColor, widget.bottomColor],
          ),
        ),
        child: widget.child,
      );
    }

    return CustomPaint(
      painter: _WaterPainter(
        shader: _shader!,
        time: widget.time,
        topColor: widget.topColor,
        bottomColor: widget.bottomColor,
      ),
      child: widget.child,
    );
  }
}

class _WaterPainter extends CustomPainter {
  final FragmentShader shader;
  final double time;
  final Color topColor;
  final Color bottomColor;

  _WaterPainter({
    required this.shader,
    required this.time,
    required this.topColor,
    required this.bottomColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);

    // topColor (r, g, b, a)
    shader.setFloat(3, topColor.r);
    shader.setFloat(4, topColor.g);
    shader.setFloat(5, topColor.b);
    shader.setFloat(6, topColor.a);

    // bottomColor (r, g, b, a)
    shader.setFloat(7, bottomColor.r);
    shader.setFloat(8, bottomColor.g);
    shader.setFloat(9, bottomColor.b);
    shader.setFloat(10, bottomColor.a);

    final Paint paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.topColor != topColor ||
        oldDelegate.bottomColor != bottomColor;
  }
}
