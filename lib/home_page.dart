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
  static const bool _enablePostProcess = true;
  static const double _postBlurRadius = 1.2;

  static const bool _enableFpsMeter = true;

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

  final School _school = School(
    config: const SchoolConfig(
      fishCount: 160,
      streamLineCount: 15,
      fishAlpha: 0.2,
      fishSpeedMultiplier: 3.0,
      minFishSize: 40,
      maxFishSize: 70,
    ),
    destinations: kFishDestinations,
  );

  static const double _microsPerFrame = 1000000.0 / 60.0;

  Duration _lastTick = Duration.zero;
  double _waterTime = 0.0;

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
    // Microseconds, not milliseconds: Duration.inMilliseconds truncates, which
    // on a perfect 60Hz clock alternates dt between 0.96 and 1.02 and shimmers.
    final int deltaUs = elapsed.inMicroseconds - _lastTick.inMicroseconds;
    _lastTick = elapsed;

    double dt = deltaUs / _microsPerFrame;
    if (dt > 10.0) dt = 1.0; // Prevent huge jumps if suspended
    _waterTime += deltaUs / 1000000.0;

    final mediaSize = MediaQuery.of(context).size;

    setState(() {
      _school.update(dt, mediaSize);
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          _school.populate(size);

          Widget filteredLayer = WaterBackground(
            topColor: _topGradientColor,
            bottomColor: _bottomGradientColor,
            time: _waterTime,
            child: Stack(
              children: [
                Positioned.fill(child: FishBackground.shared(_school)),
                ..._school.itemFish.map((fish) {
                  Widget fishWidget = Fish(
                    color: fish.color,
                    size: fish.size,
                    angle: fish.heading,
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
                          border: Border.all(color: _hoverHaloColor, width: 2),
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

          return Stack(
            children: [
              filteredLayer,
              if (_enableFpsMeter)
                const Positioned(top: 8, right: 8, child: FPSMeter()),
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
    );
  }
}

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
