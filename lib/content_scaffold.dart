import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'water_background.dart';
import 'fish_background.dart';

// ── Shared text colors (dark on white) ─────────────────────────────────────
const Color kDark = Color(0xFF1A1A1A);
const Color kMuted = Color(0xFF5A6A7A);
const Color kAccent = Color(0xFF0D7CB0);

const Color kWaterTop = Color.fromARGB(255, 125, 218, 255);
const Color kWaterBottom = Color.fromARGB(255, 49, 155, 197);

/// Open an off-site link, ignoring it if the platform refuses.
Future<void> launchExternal(String raw) async {
  final uri = Uri.parse(raw);
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

/// The white content card over the water, shared by every non-home page:
/// background fish, a back arrow, and a scrolling column of [children].
class ContentScaffold extends StatelessWidget {
  final List<Widget> children;

  const ContentScaffold({super.key, required this.children});

  void _back(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B66),
      body: WaterBackground(
        topColor: kWaterTop,
        bottomColor: kWaterBottom,
        child: Stack(
          children: [
            // ── Decorative fish & stream lines behind everything ──────────
            const Positioned.fill(child: FishBackground()),

            // ── White content card ────────────────────────────────────────
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
                            GestureDetector(
                              onTap: () => _back(context),
                              child: const Padding(
                                padding: EdgeInsets.only(bottom: 28),
                                child: Icon(
                                  Icons.arrow_back,
                                  size: 20,
                                  color: kMuted,
                                ),
                              ),
                            ),
                            ...children,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small caps-ish section rule used to break up a content page.
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kAccent,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(height: 1, color: kMuted.withValues(alpha: 0.18)),
        ),
      ],
    );
  }
}

/// A tappable external link, styled as underlined accent text.
class ExternalLink extends StatelessWidget {
  final String label;
  final String url;

  const ExternalLink({super.key, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchExternal(url),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          color: kAccent,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: Color(0x400D7CB0),
        ),
      ),
    );
  }
}
