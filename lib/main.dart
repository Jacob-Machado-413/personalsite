import 'package:flutter/material.dart';
import 'home_page.dart';
import 'portfolio_page.dart';
import 'project_page.dart';
import 'projects.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jacob Machado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        // One route per portfolio entry; the home page's red fish look these up by name.
        '/': (context) => const HomePage(),
        '/portfolio': (context) => const PortfolioPage(),
        for (final project in kProjects)
          project.route: (context) => ProjectPage(project: project),
      },
    );
  }
}
