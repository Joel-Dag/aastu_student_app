import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.aastuBlue.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text(
              'About Us',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'AASTU Student Guide helps ECE students plan and track their coursework, grades, and graduation path. '
            'It visualizes past semesters, upcoming required courses, and a custom graduation plan so students can keep their academic progress on target.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'The app includes the following features:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            '• Track your grades and GPA across semesters.\n'
            '• Lock completed semesters to prevent accidental edits.\n'
            '• Build a custom manual graduation plan when prerequisite failures occur.\n'
            '• Generate a suggested plan based on your target CGPA and stream.\n'
            '• Visualize your academic progress with a clear and intuitive interface.',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Developer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'JoDag',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Thank you for using the app. If you have feedback or need further enhancements, feel free to share your ideas.',
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
