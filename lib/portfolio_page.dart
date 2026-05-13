import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'water_background.dart';
import 'fish_model.dart';
import 'fish_widget.dart';
import 'stream_line_model.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage>
    with SingleTickerProviderStateMixin {
  // ── Water / fish config ──────────────────────────────────────────────────
  static const int _fishCount = 30;
  static const int _streamLineCount = 12;
  static const double _fishSpeed = 1.2;
  static const double _fishAlpha = 0.18;

  // ── Text colors (dark on white) ──────────────────────────────────────────
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _muted = Color(0xFF5A6A7A);
  static const Color _accent = Color(0xFF0D7CB0);

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

    for (int i = 0; i < _streamLineCount; i++) {
      _streamLines.add(
        StreamLineModel(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          length: 40 + _random.nextDouble() * 100,
          thickness: 1 + _random.nextDouble() * 1.5,
          speed: (0.3 + _random.nextDouble() * 0.7) * _fishSpeed * 0.4,
          opacity: 0.06 + _random.nextDouble() * 0.10,
        ),
      );
    }

    for (int i = 0; i < _fishCount; i++) {
      _fishes.add(
        FishModel(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          dx: (0.08 + _random.nextDouble() * 0.25) * _fishSpeed,
          dy: (_random.nextDouble() - 0.5) * 0.2,
          color: Colors.blueAccent.withValues(alpha: _fishAlpha),
          size: 25 + _random.nextDouble() * 35,
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
        f.update(dt, mediaSize);
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

  // ── Helpers ──────────────────────────────────────────────────────────────
  Future<void> _launch(String raw) async {
    final uri = Uri.parse(raw);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B66),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (size.width > 0 && !_initialized) _init(size);

          return WaterBackground(
            topColor: const Color.fromARGB(255, 125, 218, 255),
            bottomColor: const Color.fromARGB(255, 49, 155, 197),
            child: Stack(
              children: [
                // ── Decorative fish & stream lines behind everything ──────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DecoPainter(
                      fishes: _fishes,
                      streamLines: _streamLines,
                    ),
                  ),
                ),

                // ── White content card ─────────────────────────────────────
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: wide ? 40 : 16,
                        vertical: wide ? 48 : 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SelectionArea(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: wide ? 56 : 28,
                              vertical: 48,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _intro(),
                                const SizedBox(height: 64),
                                _section('What I\'ve made'),
                                const SizedBox(height: 24),
                                _projects(),
                                const SizedBox(height: 64),
                                _section('Say hello'),
                                const SizedBox(height: 24),
                                _contact(),
                                const SizedBox(height: 48),
                                Center(
                                  child: Text(
                                    '© ${DateTime.now().year} Jacob Machado',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Floating back button ──────────────────────────────────
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Intro ────────────────────────────────────────────────────────────────
  Widget _intro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 28),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 20, height: 1.7, color: _dark),
            children: [
              TextSpan(text: 'Hey, I\'m '),
              TextSpan(
                text: 'Jacob',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: _dark,
                ),
              ),
              TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'I\'m a .NET software engineer based in Torrance, CA. '
          'I take aging desktop applications — the kind scientists and engineers rely on every day — '
          'and rebuild them into modern, modular systems. '
          'Plugin architectures, CI/CD pipelines, hardware drivers, you name it. '
          'I care about making software that feels solid and gets out of the way.',
          style: TextStyle(fontSize: 16, height: 1.75, color: _muted),
        ),
      ],
    );
  }

  // ── What I do ────────────────────────────────────────────────────────────
  Widget _whatIDo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('What I do'),
        const SizedBox(height: 24),
        _pillar(
          'Architecture',
          'I design extensible plugin-based systems that support diverse hardware models — '
              'replacing monolithic legacy code with clean, modular foundations that teams can reason about.',
        ),
        const SizedBox(height: 20),
        _pillar(
          'Delivery',
          'I automate the boring stuff so humans don\'t have to. CI/CD pipelines, Docker, Azure, '
              'weekly releases — I cut our delivery time by 40% and stopped regressions before they hit users.',
        ),
        const SizedBox(height: 20),
        _pillar(
          'Hardware',
          'I write low-level C# drivers that talk to real spectroscopy instruments. '
              'There\'s something deeply satisfying about bridging physical hardware and a clean software API.',
        ),
      ],
    );
  }

  Widget _pillar(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 2,
            height: 28,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.7,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Skills ───────────────────────────────────────────────────────────────
  Widget _skills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _skillGroup('Languages', ['C#', 'Python', 'C++', 'Java', 'JavaScript']),
        const SizedBox(height: 22),
        _skillGroup('Frameworks & tools', ['.NET', 'WPF', 'WinForms', 'Godot']),
        const SizedBox(height: 22),
        _skillGroup('DevOps & cloud', [
          'Azure',
          'Docker',
          'GitHub Actions',
          'Ansible',
          'Semaphore',
          'CI/CD',
        ]),
        const SizedBox(height: 22),
        _skillGroup('Also comfortable with', [
          'Git',
          'Test automation',
          'System debugging',
          'Spectroscopy drivers',
        ]),
      ],
    );
  }

  Widget _skillGroup(String label, List<String> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _muted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: skills
              .map(
                (s) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _accent,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ── Projects ─────────────────────────────────────────────────────────────
  Widget _projects() {
    return Column(
      children: [
        _projectCard(
          'SpecSuite',
          'C#, .NET, WPF — Large desktop application replacing a legacy '
              'spectroscopy platform with modular architecture and real-time hardware integration. '
              'this is largest thing I have worked on, and was the lead developer.',
          url:
              'https://www.metrohm.com/en_us/service/software-center/'
              'laboratory-raman-software.html#specsuite',
        ),
        const SizedBox(height: 16),
        _projectCard(
          'Youth Group CRM',
          '.NET, Flutter, Dart, C# — made a CRM system for my church\'s youth group.'
              ' mobile and desktop ui, mostly to track attendance trends and manage group activities.',
        ),
        const SizedBox(height: 16),
        _projectCard(
          'This Website',
          'Flutter, Dart — Made a small personal website, '
              'with a portfolio page and custom procedural animations. Also added some shaders to experiment with ',
          url: 'https://jacobmachado.com',
        ),
      ],
    );
  }

  Widget _projectCard(String title, String description, {String? url}) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _muted.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: url != null ? const Color(0xFF1A73E8) : _dark,
                    decoration: url != null ? TextDecoration.underline : null,
                  ),
                ),
              ),
              if (url != null)
                const Icon(Icons.open_in_new, size: 16, color: _muted),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14.5, height: 1.6, color: _muted),
          ),
        ],
      ),
    );

    if (url != null) {
      return GestureDetector(onTap: () => _launch(url), child: card);
    }
    return card;
  }

  // ── Contact ──────────────────────────────────────────────────────────────
  Widget _contact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _contactLink('jmachadoat4@gmail.com', 'mailto:jmachadoat4@gmail.com'),
        const SizedBox(height: 10),
        _contactLink(
          'linkedin.com/in/jacob-machado',
          'https://linkedin.com/in/jacob-machado',
        ),
        const SizedBox(height: 10),
        _contactLink('jacobmachado.com', 'https://jacobmachado.com'),
      ],
    );
  }

  Widget _contactLink(String label, String url) {
    return GestureDetector(
      onTap: () => _launch(url),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: _accent,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: Color(0x400D7CB0),
        ),
      ),
    );
  }

  // ── Section header ───────────────────────────────────────────────────────
  Widget _section(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _accent,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(height: 1, color: _muted.withValues(alpha: 0.18)),
        ),
      ],
    );
  }
}

// ── Decorative background painter ──────────────────────────────────────────
class _DecoPainter extends CustomPainter {
  final List<FishModel> fishes;
  final List<StreamLineModel> streamLines;

  _DecoPainter({required this.fishes, required this.streamLines});

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
  bool shouldRepaint(covariant _DecoPainter old) => true;
}
