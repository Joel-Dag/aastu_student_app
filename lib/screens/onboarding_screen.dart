import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'grade_entry_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _step = 0;
  String _department = departments.first;
  int _year = 1;
  String? _stream;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your name.');
      return;
    }
    if (_year >= 4 && (_stream == null || _stream!.isEmpty)) {
      _showError('Please select your specialization stream.');
      return;
    }

    final profile = StudentProfile(
      name: _nameController.text.trim(),
      department: _department,
      currentYear: _year,
      currentStream: _year >= 4 ? _stream : null,
    );

    await StorageService.instance.saveProfile(profile);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GradeEntryScreen(isFirstRun: true)),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  void _next() {
    if (_step == 0 && _nameController.text.trim().isEmpty) {
      _showError('Please enter your name.');
      return;
    }
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surfaceDark,
              AppColors.aastuBlueDark.withValues(alpha: 0.4),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildHeader(),
              const SizedBox(height: 8),
              _buildStepIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildNameStep(),
                    _buildDepartmentYearStep(),
                    _buildStreamStep(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    child: Text(_step < 2 ? 'Continue' : 'Start Grade Entry'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.goldGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.aastuGold.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.school_rounded, size: 36, color: AppColors.aastuBlueDark),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.goldGradient.createShader(bounds),
          child: const Text(
            'AASTU Student Guide',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Track grades • Plan your path • Graduate on time',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= _step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: active ? AppTheme.goldGradient : null,
                color: active ? null : Colors.white12,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('What should we call you?', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline, color: AppColors.aastuGold),
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentYearStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Program', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _department,
            isDense: true,
            isExpanded: true,
            itemHeight: 48,
            decoration: const InputDecoration(labelText: 'Department'),
            items: departments
                .map((d) {
                  final isComingSoon = comingSoonDepartments.contains(d);
                  return DropdownMenuItem(
                    value: d,
                    enabled: !isComingSoon,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        isComingSoon ? '$d (Coming soon)' : d,
                        style: TextStyle(
                          fontSize: 14,
                          color: isComingSoon ? Colors.white38 : null,
                        ),
                      ),
                    ),
                  );
                })
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              final isComingSoon = comingSoonDepartments.contains(v);
              if (!isComingSoon) {
                setState(() => _department = v);
              }
            },
          ),
          const SizedBox(height: 20),
          const Text('Current Year', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(5, (i) {
              final year = i + 1;
              final selected = _year == year;
              return ChoiceChip(
                label: Text('Year $year'),
                selected: selected,
                selectedColor: AppColors.aastuGold,
                labelStyle: TextStyle(
                  color: selected ? AppColors.aastuBlueDark : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) => setState(() {
                  _year = year;
                  if (year < 4) _stream = null;
                }),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamStep() {
    if (_year < 4) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Almost done!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.aastuGold.withValues(alpha: 0.9)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Stream selection is only required from Year 4 onward. '
                        'You can choose your planned stream later when using Suggest Plan.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Stream', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Select your ECE specialization stream.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ...eceStreams.map((s) {
            final selected = _stream == s;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: selected
                    ? AppColors.aastuGold.withValues(alpha: 0.15)
                    : AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _stream = s),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.aastuGold : Colors.white12,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selected ? AppColors.aastuGold : Colors.white38,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$s Engineering',
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? AppColors.aastuGold : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
