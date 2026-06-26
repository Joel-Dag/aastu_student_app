import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/grade_entry_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AastuStudentGuideApp());
}

class AastuStudentGuideApp extends StatelessWidget {
  const AastuStudentGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Guide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppBootstrapper(),
    );
  }
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _resolveStartScreen();
  }

  Future<void> _resolveStartScreen() async {
    final storage = StorageService.instance;

    final results = await Future.wait([
      storage.hasOnboarded(),
      storage.loadGrades(),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);

    final onboarded = results[0] as bool;
    final grades = results[1] as Map<String, String>;

    if (!mounted) return;

    if (!onboarded) {
      setState(() => _destination = const OnboardingScreen());
      return;
    }

    if (grades.isEmpty) {
      setState(() => _destination = const GradeEntryScreen(isFirstRun: true));
      return;
    }

    setState(() => _destination = const DashboardScreen());
  }

  @override
  Widget build(BuildContext context) {
    if (_destination == null) {
      return const SplashScreen();
    }
    return _destination!;
  }
}
