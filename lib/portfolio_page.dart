import 'package:flutter/material.dart';
import 'content_scaffold.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentScaffold(
      children: [
        _intro(),
        const SizedBox(height: 24),
        // The fish are the only route to the project pages, so say so for
        // anyone who lands here without having seen the home page.
        const Text(
          "The other red fish are projects — follow one to see what I've built.",
          style: TextStyle(
            fontSize: 16,
            height: 1.75,
            color: kMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 64),
        const SectionHeader('Say hello'),
        const SizedBox(height: 24),
        _contact(),
        const SizedBox(height: 48),
        Center(
          child: Text(
            '© ${DateTime.now().year} Jacob Machado',
            style: const TextStyle(color: kMuted, fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
      ],
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
            color: kAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 28),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 20, height: 1.7, color: kDark),
            children: [
              TextSpan(text: "Hey, I'm "),
              TextSpan(
                text: 'Jacob',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  color: kDark,
                ),
              ),
              TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "I'm a .NET software engineer based in Torrance, CA. "
          'I take aging desktop applications — the kind scientists and engineers rely on every day — '
          'and rebuild them into modern, modular systems. '
          'Plugin architectures, CI/CD pipelines, hardware drivers, you name it. '
          'I care about making software that feels solid and gets out of the way.',
          style: TextStyle(fontSize: 16, height: 1.75, color: kMuted),
        ),
      ],
    );
  }

  // ── Contact ──────────────────────────────────────────────────────────────
  Widget _contact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExternalLink(
          label: 'jmachadoat4@gmail.com',
          url: 'mailto:jmachadoat4@gmail.com',
        ),
        const SizedBox(height: 10),
        const ExternalLink(
          label: 'linkedin.com/in/jacob-machado',
          url: 'https://linkedin.com/in/jacob-machado',
        ),
        const SizedBox(height: 10),
        const ExternalLink(
          label: 'jacobmachado.com',
          url: 'https://jacobmachado.com',
        ),
      ],
    );
  }
}
