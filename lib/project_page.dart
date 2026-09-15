import 'package:flutter/material.dart';
import 'content_scaffold.dart';
import 'projects.dart';

class ProjectPage extends StatelessWidget {
  final Project project;

  const ProjectPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return ContentScaffold(
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
        Text(
          project.title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: kDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          project.stack,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kAccent,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          project.blurb,
          style: const TextStyle(fontSize: 17, height: 1.75, color: kMuted),
        ),
        const SizedBox(height: 48),
        const SectionHeader('What it took'),
        const SizedBox(height: 24),
        ...project.highlights.map(_bullet),
        if (project.url != null) ...[
          const SizedBox(height: 40),
          ExternalLink(
            label: project.urlLabel ?? project.url!,
            url: project.url!,
          ),
        ],
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 9, right: 14),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: kAccent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15.5,
                height: 1.65,
                color: kMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
