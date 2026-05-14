import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'water_background.dart';
import 'fish_background.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  // ── Text colors (dark on white) ──────────────────────────────────────────
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _muted = Color(0xFF5A6A7A);
  static const Color _accent = Color(0xFF0D7CB0);

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
          return WaterBackground(
            topColor: const Color.fromARGB(255, 125, 218, 255),
            bottomColor: const Color.fromARGB(255, 49, 155, 197),
            child: Stack(
              children: [
                // ── Decorative fish & stream lines behind everything ──────
                const Positioned.fill(child: FishBackground()),

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
