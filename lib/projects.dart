/// One portfolio entry. Each gets its own route and its own red fish.
class Project {
  /// Route path, e.g. '/specsuite'.
  final String route;

  /// Page heading, and the fish's hover tooltip.
  final String title;

  /// One-line stack summary shown under the heading.
  final String stack;

  /// Opening paragraph.
  final String blurb;

  /// Bullets under the blurb.
  final List<String> highlights;

  /// Optional outbound link shown at the bottom of the page.
  final String? url;
  final String? urlLabel;

  const Project({
    required this.route,
    required this.title,
    required this.stack,
    required this.blurb,
    required this.highlights,
    this.url,
    this.urlLabel,
  });
}

const List<Project> kProjects = [
  Project(
    route: '/specsuite',
    title: 'SpecSuite',
    stack: 'C#  ·  .NET  ·  WPF  ·  GitHub Actions  ·  Azure',
    blurb:
        "The largest thing I've worked on, and the one I led. SpecSuite replaced a "
        "legacy spectroscopy platform end to end, across a range of instrument "
        "hardware including next-generation models.",
    highlights: [
      'Architected extensible C# services and drivers so new instruments could be '
          'added without touching the core.',
      'Built the CI/CD pipelines on GitHub Actions and Azure that delivered it '
          'continuously to real users.',
      'Engineered unit and integration testing into every change, raising coverage '
          'by 60% and cutting regression defects.',
      'Worked directly with UX designers, turning their feedback into fast, precise '
          'iterations that reduced user-reported issues.',
    ],
    url:
        'https://www.metrohm.com/en_us/service/software-center/'
        'laboratory-raman-software.html#specsuite',
    urlLabel: 'See it at Metrohm',
  ),
  Project(
    route: '/youth-group',
    title: 'Youth Group Attendance Tracker',
    stack: '.NET 10  ·  Blazor WebAssembly  ·  EF Core  ·  SQLite  ·  Docker',
    blurb:
        'A full-stack web app that surfaces engagement patterns and attendance '
        "trends for my church's youth group.",
    highlights: [
      'Built the .NET 10 REST API and Blazor WebAssembly front-end end to end on '
          'EF Core and SQLite.',
      'Wrote 50 xUnit unit and integration tests, exercising the live API through '
          'WebApplicationFactory.',
      'Added custom API-key authentication and shipped it with Docker Compose on a '
          'self-hosted homelab.',
    ],
  ),
  Project(
    route: '/darker-and-deeper',
    title: 'Darker and Deeper',
    stack: 'Godot  ·  GDScript  ·  GLSL  ·  GMTK Game Jam 2026',
    blurb:
        'A submarine game where sonar is the only way to see the cave — and every '
        'ping tells the predator exactly where you are.',
    highlights: [
      'Custom sonar and CRT shaders drive the whole visual language of the game.',
      'Procedurally generated caves, with Windows and WebAssembly builds.',
      'Built and submitted inside the GMTK Game Jam weekend.',
    ],
    url: 'https://phyllistine.itch.io/darker-and-deeper',
    urlLabel: 'Play it on itch.io',
  ),
  Project(
    route: '/this-site',
    title: 'This Site',
    stack: 'Flutter  ·  Dart  ·  GLSL  ·  Docker  ·  nginx',
    blurb:
        'The page you are on. A school of interactive fish doubles as the '
        'navigation — the red ones are the links.',
    highlights: [
      "Wrote GLSL fragment shaders for Flutter's Impeller: a Kuwahara painterly "
          'pass and animated water.',
      'Each fish runs its own steering behaviour, with the background school '
          'reacting to the cursor.',
      'Built in Flutter and Dart, deployed with Docker and nginx.',
    ],
    url: 'https://github.com/Jacob-Machado-413/personalsite',
    urlLabel: 'Read the source on GitHub',
  ),
];

/// Something a red fish on the home page swims you to.
///
/// The About Me hub and every project are the same kind of thing here, so the
/// home page can spawn one fish per entry without special-casing any of them.
class FishDestination {
  /// Route name, registered in main.dart.
  final String route;

  /// Shown in the fish's hover tooltip.
  final String label;

  const FishDestination({required this.route, required this.label});
}

const FishDestination kAboutMe = FishDestination(
  route: '/portfolio',
  label: 'About Me',
);

/// About Me first, then one per project.
final List<FishDestination> kFishDestinations = [
  kAboutMe,
  for (final project in kProjects)
    FishDestination(route: project.route, label: project.title),
];
