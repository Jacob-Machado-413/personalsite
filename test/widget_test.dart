import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:site/fish_widget.dart';
import 'package:site/home_page.dart';
import 'package:site/main.dart';
import 'package:site/project_page.dart';
import 'package:site/projects.dart';

void main() {
  test('every project has a distinct, well-formed route', () {
    expect(kProjects, isNotEmpty);
    for (final project in kProjects) {
      expect(project.route, startsWith('/'));
    }
    final routes = kProjects.map((p) => p.route).toSet();
    expect(routes.length, kProjects.length, reason: 'routes must be unique');
    expect(routes, isNot(contains('/')));
    expect(routes, isNot(contains('/portfolio')));
  });

  testWidgets('MyApp registers a ProjectPage for each project', (tester) async {
    await tester.pumpWidget(const MyApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final routes = app.routes!;

    for (final project in kProjects) {
      final builder = routes[project.route];
      expect(builder, isNotNull, reason: 'no route for ${project.title}');

      final page = builder!(tester.element(find.byType(MaterialApp)));
      expect(page, isA<ProjectPage>());
      expect((page as ProjectPage).project.title, project.title);
    }

    // Let the home page's tickers unwind before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a project page renders its own content', (tester) async {
    final project = kProjects.first;
    await tester.pumpWidget(MaterialApp(home: ProjectPage(project: project)));
    await tester.pump();

    expect(find.text(project.title), findsOneWidget);
    expect(find.text(project.stack), findsOneWidget);
    for (final highlight in project.highlights) {
      expect(find.text(highlight), findsOneWidget);
    }
    expect(find.text(project.urlLabel!), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  test('every fish destination is About Me or a project', () {
    expect(kFishDestinations.first, kAboutMe);
    expect(kFishDestinations.length, kProjects.length + 1);

    final labels = kFishDestinations.map((d) => d.label).toSet();
    expect(labels.length, kFishDestinations.length, reason: 'labels collide');
    for (final project in kProjects) {
      expect(labels, contains(project.title));
    }
  });

  testWidgets('every fish destination has a registered route', (tester) async {
    await tester.pumpWidget(const MyApp());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    for (final destination in kFishDestinations) {
      expect(
        app.routes,
        contains(destination.route),
        reason: '${destination.label} swims to a route that does not exist',
      );
    }

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the home page renders one red fish per destination', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pump();

    final redFish = find.byWidgetPredicate(
      (w) => w is Fish && w.color == Colors.redAccent,
    );
    expect(redFish, findsNWidgets(kFishDestinations.length));

    await tester.pumpWidget(const SizedBox());
  });
}
