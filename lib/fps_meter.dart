import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FPSMeter extends StatefulWidget {
  const FPSMeter({super.key});

  @override
  State<FPSMeter> createState() => _FPSMeterState();
}

class _FPSMeterState extends State<FPSMeter> with SingleTickerProviderStateMixin {
  int _frameCount = 0;
  double _fps = 0;
  late Ticker _ticker;
  DateTime _lastTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _frameCount++;
      final currentTime = DateTime.now();
      final difference = currentTime.difference(_lastTime).inMilliseconds;
      if (difference >= 1000) {
        setState(() {
          _fps = (_frameCount * 1000) / difference;
          _frameCount = 0;
          _lastTime = currentTime;
        });
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'FPS: ${_fps.toStringAsFixed(1)}',
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
