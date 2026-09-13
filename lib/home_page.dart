import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'fish_widget.dart';

import 'water_background.dart';
import 'fps_meter.dart';
import 'fish_background.dart';
import 'projects.dart';
import 'school.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Configuration Settings
  static const bool _enablePostProcess = true;
  static const double _postBlurRadius = 1.2; // 0=crisp, ~1.5=soft underwater

  static const bool _enableFpsMeter = false;

  static const Color _hoverHaloColor = Colors.white;
  static const double _hoverHaloAlpha = 0.2;

  static const Color _topGradientColor = Color.fromARGB(
    255,
    125,
    218,
    255,
  ); // Light blue top
  static const Color _bottomGradientColor = Color.fromARGB(
    255,
    49,
    155,
    197,
  ); // Deep blue bottom

  late Ticker _ticker;
  ui.FragmentShader? _postShader;

  /// Background school and item fish, stepped together by [_ticker].
  final School _school = School(
    config: const SchoolConfig(
      fishCount: 80,
      streamLineCount: 15,
      fishAlpha: 0.2,
      fishSpeedMultiplier: 3.0,
      minFishSize: 40,
      maxFishSize: 70,
    ),
    destinations: kFishDestinations,
  );

  Duration _lastTick = Duration.zero;
  Offset? _mousePosition;
  double _waterTime = 0.0;
  Duration _lastWaterElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/underwater.frag',
      );
      if (mounted) {
        setState(() {
          _postShader = program.fragmentShader();
        });
      }
    } catch (e) {
      debugPrint("Failed to load underwater shader: $e");
    }
  }

  void _tick(Duration elapsed) {
    if (!mounted) return;
    // Calculate delta to make movement independent of frame rate
    double dt = (elapsed.inMilliseconds - _lastTick.inMilliseconds) / 16.666;
    if (dt > 10.0) dt = 1.0; // Prevent huge jumps if suspended
    _lastTick = elapsed;

    // Advance water shader time (consolidated into main ticker)
    double waterDt =
        (elapsed.inMicroseconds - _lastWaterElapsed.inMicroseconds) / 1000000.0;
    _lastWaterElapsed = elapsed;
    _waterTime += waterDt;

    final mediaSize = MediaQuery.of(context).size;

    setState(() {
      _school.update(dt, mediaSize, mousePosition: _mousePosition);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MouseRegion(
        onHover: (event) => _mousePosition = event.localPosition,
        onExit: (_) => _mousePosition = null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            _school.populate(size);

            // Layer 1: Elements to be filtered (Background, lines, fish bodies)
            Widget filteredLayer = WaterBackground(
              topColor: _topGradientColor,
              bottomColor: _bottomGradientColor,
              time: _waterTime,
              child: Stack(
                children: [
                  // Background Layer (Stream lines and background fish)
                  Positioned.fill(child: FishBackground.shared(_school)),
                  // Interactive Fish Bodies (Kept as widgets for hit testing)
                  ..._school.itemFish.map((fish) {
                    Widget fishWidget = Fish(
                      color: fish.color,
                      size: fish.size,
                      angle: atan2(fish.dy, fish.dx) + sin(fish.phase) * 0.2,
                      phase: fish.phase,
                      hasEyes: fish.isInteractive,
                    );

                    Widget content = fishWidget;

                    if (fish.isInteractive) {
                      if (fish.isHovered) {
                        content = Container(
                          width: fish.size * 1.5,
                          height: fish.size * 1.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _hoverHaloColor,
                              width: 2,
                            ),
                            color: _hoverHaloColor.withValues(
                              alpha: _hoverHaloAlpha,
                            ),
                          ),
                          child: Center(child: fishWidget),
                        );
                      }

                      content = MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => fish.isHovered = true),
                        onExit: (_) => setState(() => fish.isHovered = false),
                        child: GestureDetector(
                          onTap: () {
                            final route = fish.destinationRoute;
                            if (route != null) {
                              final fishCenter = Offset(
                                fish.x + fish.size / 2,
                                fish.y + fish.size / 2,
                              );
                              final app = context
                                  .findAncestorWidgetOfExactType<MaterialApp>();
                              final builder = app?.routes?[route];
                              if (builder != null) {
                                Navigator.push(
                                  context,
                                  _PortalPageRoute(
                                    pageBuilder: builder,
                                    portalCenter: fishCenter,
                                    routeName: route,
                                  ),
                                );
                              }
                            }
                          },
                          child: content,
                        ),
                      );
                    }

                    double adjustedX = (fish.isInteractive && fish.isHovered)
                        ? fish.x - fish.size * 0.25
                        : fish.x;
                    double adjustedY = (fish.isInteractive && fish.isHovered)
                        ? fish.y - fish.size * 0.25
                        : fish.y;

                    return Positioned(
                      left: adjustedX,
                      top: adjustedY,
                      child: content,
                    );
                  }),
                ],
              ),
            );

            if (_enablePostProcess && _postShader != null) {
              final shader = _postShader!;
              final blur = _postBlurRadius;
              final time = _waterTime;
              filteredLayer = AnimatedSampler((
                ui.Image image,
                Size size,
                Canvas canvas,
              ) {
                shader
                  ..setFloat(0, size.width) // u_resolution.x
                  ..setFloat(1, size.height) // u_resolution.y
                  ..setFloat(2, time) // u_time
                  ..setFloat(3, blur) // u_blurRadius
                  ..setImageSampler(0, image);

                canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
              }, child: filteredLayer);
            }

            // Combined Layer: Filtered content with unfiltered text on top
            return Stack(
              children: [
                filteredLayer,
                // FPS Meter
                if (_enableFpsMeter)
                  const Positioned(top: 8, right: 8, child: FPSMeter()),
                //  Instructions Text (Unfiltered)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Follow a red fish to dive deeper.",
                          style: TextStyle(fontSize: 20, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // Fish Tooltips (Unfiltered)
                ..._school.itemFish.map((fish) {
                  if (!fish.isHovered) return const SizedBox.shrink();

                  double adjustedX = (fish.isInteractive && fish.isHovered)
                      ? fish.x - fish.size * 0.25
                      : fish.x;
                  double adjustedY = (fish.isInteractive && fish.isHovered)
                      ? fish.y - fish.size * 0.25
                      : fish.y;

                  double boxSize = (fish.isInteractive && fish.isHovered)
                      ? fish.size * 1.5
                      : fish.size;

                  return Positioned(
                    left: adjustedX,
                    top: adjustedY,
                    width: boxSize,
                    height: boxSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -40,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              fish.hoverTooltip ?? 'Explore',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Page transition: circular portal expanding from the fish's position ──

class _PortalPageRoute extends PageRouteBuilder {
  _PortalPageRoute({
    required WidgetBuilder pageBuilder,
    required Offset portalCenter,
    required String routeName,
  }) : super(
         settings: RouteSettings(name: routeName),
         pageBuilder: (context, animation, _) => pageBuilder(context),
         transitionDuration: const Duration(milliseconds: 700),
         reverseTransitionDuration: const Duration(milliseconds: 500),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curved = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
             reverseCurve: Curves.easeInCubic,
           );

           return AnimatedBuilder(
             animation: curved,
             builder: (context, _) {
               final size = MediaQuery.of(context).size;
               final maxR = _maxCornerDistance(portalCenter, size);
               final radius = 4.0 + curved.value * (maxR - 4.0);

               // Fade the new page in as the circle expands
               final opacity = (curved.value - 0.3).clamp(0.0, 1.0) / 0.7;

               return Opacity(
                 opacity: opacity,
                 child: ClipPath(
                   clipper: _CircleRevealClipper(
                     center: portalCenter,
                     radius: radius,
                   ),
                   child: child,
                 ),
               );
             },
           );
         },
       );

  static double _maxCornerDistance(Offset center, Size size) {
    double maxD = 0;
    for (final c in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final d = (c - center).distance;
      if (d > maxD) maxD = d;
    }
    return maxD;
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  _CircleRevealClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleRevealClipper old) =>
      old.center != center || old.radius != radius;
}
