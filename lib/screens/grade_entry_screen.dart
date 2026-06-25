import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/student_profile.dart';
import '../services/academic_service.dart';
import '../services/gpa_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/incomplete_warning_banner.dart';
import '../widgets/semester_table_card.dart';
import 'dashboard_screen.dart';

class GradeEntryScreen extends StatefulWidget {
  final bool isFirstRun;

  const GradeEntryScreen({super.key, this.isFirstRun = false});

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  StudentProfile? _profile;
  List<Course> _courses = [];
  String _previewStream = eceStreams.first;
  bool _loading = true;

  final _academic = AcademicService.instance;
  final _storage = StorageService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _storage.loadProfile();
    if (profile == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final courses = _academic.buildStudentCourses(profile);
    final grades = await _storage.loadGrades();
    _academic.applyGrades(courses, grades);

    setState(() {
      _profile = profile;
      _courses = courses;
      _previewStream = profile.effectiveStream();
      _loading = false;
    });
  }

  Future<void> _saveGrades() async {
    await _storage.saveGrades(_academic.extractGrades(_courses));
  }

  Future<void> _savePreviewStream(String stream) async {
    if (_profile == null || _profile!.currentYear >= 4) return;
    final updated = _profile!.copyWith(plannedStream: stream);
    await _storage.saveProfile(updated);
    setState(() => _profile = updated);
  }

  void _updateGrade(Course course, String grade) {
    setState(() {
      final idx = _courses.indexWhere((c) => c.key == course.key);
      if (idx >= 0) _courses[idx].grade = grade;
    });
    _saveGrades();
  }

  void _onPreviewStreamChanged(String stream) {
    setState(() => _previewStream = stream);
    _savePreviewStream(stream);
  }

  String _streamForSlot(int year, int sem) {
    if (_academic.isStreamSemester(year, sem) || year >= 4) return _previewStream;
    return _profile?.currentStream ?? _previewStream;
  }

  bool _allPastGradesFilled() {
    if (_profile == null) return false;
    final slots = _academic.pastSemesters(_profile!.currentYear);
    for (final slot in slots) {
      final semCourses = _academic.coursesForSemester(
        _courses,
        slot.year,
        slot.sem,
        _streamForSlot(slot.year, slot.sem),
      );
      for (final c in semCourses) {
        if (c.grade == 'None') return false;
      }
    }
    return true;
  }

  void _goToDashboard() {
    if (!_allPastGradesFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill a grade for every past course before continuing.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.aastuGold)),
      );
    }

    final profile = _profile!;
    final pastSlots = _academic.pastSemesters(profile.currentYear);
    final upcomingSlots = _academic.currentAndFutureSemesters(profile.currentYear);
    final incCount = _academic.countIncomplete(_courses);
    final gpa = GpaService.instance.compute(
      _courses,
      upToYear: profile.currentYear - 1,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstRun ? 'Enter Your Grades' : 'Edit Grades'),
        automaticallyImplyLeading: !widget.isFirstRun,
      ),
      body: Column(
        children: [
          _buildSummaryHeader(profile, gpa.cgpa, pastSlots.length),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                IncompleteWarningBanner(incompleteCount: incCount),
                if (pastSlots.isNotEmpty) ...[
                  _sectionTitle('Past Semesters', Icons.history_edu),
                  ...pastSlots.map((slot) => _buildSemesterCard(slot, isPreview: false)),
                ],
                if (upcomingSlots.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _sectionTitle('Current & Upcoming', Icons.upcoming),
                  ...upcomingSlots.map((slot) {
                    final isFutureYear = slot.year > profile.currentYear;
                    return _buildSemesterCard(slot, isPreview: isFutureYear);
                  }),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _goToDashboard,
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text('Continue to Dashboard'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterCard(({int year, int sem}) slot, {required bool isPreview}) {
    final stream = _streamForSlot(slot.year, slot.sem);
    final semCourses = _academic.coursesForSemester(
      _courses,
      slot.year,
      slot.sem,
      stream,
    );

    final editable = !isPreview && slot.year < _profile!.currentYear;

    return SemesterTableCard(
      year: slot.year,
      sem: slot.sem,
      courses: semCourses,
      locked: false,
      isPreview: isPreview,
      selectedStream: _academic.isStreamSemester(slot.year, slot.sem) ? _previewStream : null,
      onStreamChanged: _academic.isStreamSemester(slot.year, slot.sem) ? _onPreviewStreamChanged : null,
      onGradeChanged: editable ? _updateGrade : (_, _) {},
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.aastuGold, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(StudentProfile profile, double cgpa, int semesterCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppTheme.heroGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, ${profile.name}!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Year ${profile.currentYear} • Fill grades for $semesterCount past semester(s)',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip('CGPA', cgpa.toStringAsFixed(2)),
              const SizedBox(width: 10),
              _statChip('Semesters', '$semesterCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.aastuGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.aastuGold.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: AppColors.aastuGold, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
