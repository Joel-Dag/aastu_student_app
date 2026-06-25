import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/grade_entry_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AastuStudentGuideApp());
}

class AastuStudentGuideApp extends StatelessWidget {
  const AastuStudentGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AASTU Student Guide',
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
    final onboarded = await storage.hasOnboarded();

    if (!onboarded) {
      setState(() => _destination = const OnboardingScreen());
      return;
    }

    final grades = await storage.loadGrades();
    if (grades.isEmpty) {
      setState(() => _destination = const GradeEntryScreen(isFirstRun: true));
      return;
    }

    setState(() => _destination = const DashboardScreen());
  }

  @override
  Widget build(BuildContext context) {
    if (_destination == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.aastuGold),
        ),
      );
    }
    return _destination!;
  }
}
