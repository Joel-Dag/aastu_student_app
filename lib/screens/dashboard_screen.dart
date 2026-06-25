import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/student_profile.dart';
import '../services/academic_service.dart';
import '../services/gpa_service.dart';
import '../services/plan_suggestion_service.dart';
import '../services/prerequisite_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/incomplete_warning_banner.dart';
import '../widgets/semester_table_card.dart';
import 'grade_entry_screen.dart';
import 'onboarding_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StudentProfile? _profile;
  List<Course> _courses = [];
  Set<String> _lockedSlots = {};
  bool _planApplied = false;
  bool _loading = true;
  String _previewStream = eceStreams.first;
  PrerequisiteAnalysis? _analysis;

  final _academic = AcademicService.instance;
  final _storage = StorageService.instance;
  final _plan = PlanSuggestionService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _storage.loadProfile();
    if (profile == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
      return;
    }

    final courses = _academic.buildStudentCourses(profile);
    final grades = await _storage.loadGrades();
    _academic.applyGrades(courses, grades);

    var lockedSlots = await _storage.loadLockedSlots();
    if (lockedSlots.contains('legacy')) {
      lockedSlots = {
        for (final s in _academic.pastSemesters(profile.currentYear))
          StorageService.slotKey(s.year, s.sem),
      };
      await _storage.saveLockedSlots(lockedSlots);
    }

    final planApplied = await _storage.isPlanApplied();

    setState(() {
      _profile = profile;
      _courses = courses;
      _lockedSlots = lockedSlots;
      _planApplied = planApplied;
      _previewStream = profile.effectiveStream();
      _analysis = PrerequisiteService.instance.analyze(
        courses,
        profile.currentYear,
        stream: profile.effectiveStream(_previewStream),
      );
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await _storage.saveGrades(_academic.extractGrades(_courses));
  }

  bool _isSlotLocked(int year, int sem) =>
      _lockedSlots.contains(StorageService.slotKey(year, sem));

  Future<void> _showLockDialog() async {
    if (_profile == null) return;

    final slots = _academic.lockableSemesters(_profile!.currentYear);
    final selected = Set<String>.from(_lockedSlots);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: const Text('Lock Semesters'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select which years and semesters to lock. Locked semesters cannot be edited.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: slots.map((slot) {
                          final key = StorageService.slotKey(slot.year, slot.sem);
                          final checked = selected.contains(key);
                          return CheckboxListTile(
                            value: checked,
                            activeColor: AppColors.aastuGold,
                            title: Text('Year ${slot.year} • Semester ${slot.sem}'),
                            onChanged: (v) {
                              setDialog(() {
                                if (v == true) {
                                  selected.add(key);
                                } else {
                                  selected.remove(key);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    setState(() => _lockedSlots = selected);
    await _storage.saveLockedSlots(selected);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selected.isEmpty
              ? 'All semesters unlocked.'
              : '${selected.length} semester(s) locked.',
        ),
        backgroundColor: selected.isEmpty ? AppColors.warning : AppColors.success,
      ),
    );
  }

  Future<void> _savePreviewStream(String stream) async {
    if (_profile == null || _profile!.currentYear >= 4) return;
    final updated = _profile!.copyWith(plannedStream: stream);
    await _storage.saveProfile(updated);
    setState(() {
      _profile = updated;
      _analysis = PrerequisiteService.instance.analyze(
        _courses,
        updated.currentYear,
        stream: stream,
      );
    });
  }

  void _updateGrade(Course course, String grade) {
    if (_isSlotLocked(course.year, course.sem)) return;
    setState(() {
      final idx = _courses.indexWhere((c) => c.key == course.key);
      if (idx >= 0) _courses[idx].grade = grade;
      _analysis = PrerequisiteService.instance.analyze(
        _courses,
        _profile!.currentYear,
        stream: _profile!.effectiveStream(_previewStream),
      );
    });
    _persist();
  }

  void _onPreviewStreamChanged(String stream) {
    setState(() {
      _previewStream = stream;
      _analysis = PrerequisiteService.instance.analyze(
        _courses,
        _profile!.currentYear,
        stream: stream,
      );
    });
    _savePreviewStream(stream);
  }

  String _streamForSlot(int year, int sem) {
    return _profile!.currentStream ?? _previewStream;
  }

  Future<void> _showSuggestPlanDialog() async {
    if (_profile == null) return;

    var targetCgpa = 3.5;
    var plannedStream = _profile!.effectiveStream(_previewStream);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.aastuBlueDark),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Suggest Graduation Plan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter your target CGPA and planned specialization stream. '
                    'The planner suggests per-course grades weighted by credit hours '
                    'to reach your goal across remaining semesters (including internship).',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Target CGPA'),
                      DropdownButton<double>(
                        value: targetCgpa,
                        dropdownColor: AppColors.cardDark,
                        items: [3.9, 3.75, 3.6, 3.5, 3.25, 3.0, 2.75, 2.5]
                            .map((v) => DropdownMenuItem(value: v, child: Text(v.toStringAsFixed(2))))
                            .toList(),
                        onChanged: (v) => setModal(() => targetCgpa = v ?? targetCgpa),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: plannedStream,
                    decoration: const InputDecoration(labelText: 'Planned Stream'),
                    items: eceStreams
                        .map((s) => DropdownMenuItem(value: s, child: Text('$s Engineering')))
                        .toList(),
                    onChanged: (v) => setModal(() => plannedStream = v ?? plannedStream),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _runSuggestPlan(targetCgpa, plannedStream);
                      },
                      child: const Text('Generate Plan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _runSuggestPlan(double target, String stream) async {
    if (_profile == null) return;

    final result = _plan.suggest(
      profile: _profile!,
      courses: _courses,
      targetCgpa: target,
      plannedStream: stream,
    );

    setState(() {
      _courses = result.updatedCourses;
      _planApplied = true;
      _previewStream = stream;
      _analysis = result.prerequisiteAnalysis;
    });

    await _persist();
    await _storage.setPlanApplied(true);

    if (_profile!.currentYear < 4) {
      final updated = _profile!.copyWith(plannedStream: stream);
      await _storage.saveProfile(updated);
      setState(() => _profile = updated);
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(result.success ? 'Plan Ready' : 'Best Effort Plan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(result.message),
              const SizedBox(height: 8),
              Text(
                'Required average SGPA per remaining semester: '
                '${result.requiredSemSgpa.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              if (result.prerequisiteAnalysis.retakeSchedule.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Retake schedule:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...result.prerequisiteAnalysis.retakeSchedule.map(
                  (r) => Text(
                    '• ${r.code} → Year ${r.scheduledYear} Sem ${r.scheduledSem}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('View Dashboard')),
        ],
      ),
    );
  }

  Future<void> _resetApp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Reset all data?'),
        content: const Text('This clears your profile, grades, and plans.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _storage.clearAll();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
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
    final stream = profile.effectiveStream(_previewStream);
    final pastGpa = GpaService.instance.compute(
      _courses,
      upToYear: profile.currentYear - 1,
    );
    final fullGpa = _planApplied
        ? GpaService.instance.compute(_courses, upToYear: 5, stream: stream)
        : pastGpa;

    final pastSlots = _academic.pastSemesters(profile.currentYear);
    final upcomingSlots = _academic.currentAndFutureSemesters(profile.currentYear);
    final incCount = _academic.countIncomplete(_courses);
    final anyLocked = _lockedSlots.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AASTU Student Guide'),
        actions: [
          IconButton(
            icon: Icon(anyLocked ? Icons.lock : Icons.lock_open),
            tooltip: 'Lock semesters',
            onPressed: _showLockDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GradeEntryScreen()),
                );
              } else if (v == 'reset') {
                _resetApp();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit past grades')),
              const PopupMenuItem(value: 'reset', child: Text('Reset app')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.aastuGold,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroCard(profile, pastGpa.cgpa, fullGpa.cgpa, anyLocked),
            const SizedBox(height: 16),
            IncompleteWarningBanner(incompleteCount: incCount),
            if (_analysis != null) _buildPrereqCard(_analysis!),
            const SizedBox(height: 16),
            _buildSgpaSection(pastGpa),
            const SizedBox(height: 24),
            if (pastSlots.isNotEmpty) ...[
              _sectionTitle('Past Semesters', Icons.history_edu),
              ...pastSlots.map((slot) => _buildSemesterCard(slot, stream, isPast: true)),
            ],
            if (upcomingSlots.isNotEmpty) ...[
              const SizedBox(height: 8),
              _sectionTitle(
                _planApplied ? 'Planned Future Semesters' : 'Current & Upcoming',
                _planApplied ? Icons.timeline : Icons.upcoming,
              ),
              ...upcomingSlots.map((slot) => _buildSemesterCard(
                    slot,
                    stream,
                    isPast: false,
                    showPlannedOnly: _planApplied,
                  )),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSuggestPlanDialog,
        backgroundColor: AppColors.aastuGold,
        foregroundColor: AppColors.aastuBlueDark,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Suggest Plan'),
      ),
    );
  }

  Widget _buildSemesterCard(
    ({int year, int sem}) slot,
    String stream, {
    required bool isPast,
    bool showPlannedOnly = false,
  }) {
    final slotStream = _streamForSlot(slot.year, slot.sem);
    var semCourses = _academic.coursesForSemester(
      _courses, slot.year, slot.sem, slotStream,
    );

    if (showPlannedOnly) {
      semCourses = semCourses.where((c) => c.grade != 'None').toList();
      if (semCourses.isEmpty) return const SizedBox.shrink();
    }

    final locked = _isSlotLocked(slot.year, slot.sem);
    final isFutureYear = slot.year > _profile!.currentYear;
    final isPreview = isFutureYear && !showPlannedOnly;

    return SemesterTableCard(
      year: slot.year,
      sem: slot.sem,
      courses: semCourses,
      locked: locked || showPlannedOnly,
      isPreview: isPreview,
      selectedStream: _academic.isStreamSemester(slot.year, slot.sem) ? slotStream : null,
      onStreamChanged: _academic.isStreamSemester(slot.year, slot.sem) && !showPlannedOnly
          ? _onPreviewStreamChanged
          : null,
      onGradeChanged: locked || showPlannedOnly || isPreview ? (_, _) {} : _updateGrade,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.aastuGold, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    StudentProfile profile,
    double currentCgpa,
    double projectedCgpa,
    bool anyLocked,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.aastuBlue.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            '${profile.department} • Year ${profile.currentYear}'
            '${profile.currentStream != null ? ' • ${profile.currentStream}' : ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _gpaTile('Current CGPA', currentCgpa.toStringAsFixed(2)),
              ),
              if (_planApplied) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _gpaTile('Projected CGPA', projectedCgpa.toStringAsFixed(2), gold: true),
                ),
              ],
            ],
          ),
          if (anyLocked)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.lock, size: 14, color: AppColors.aastuGold.withValues(alpha: 0.9)),
                  const SizedBox(width: 6),
                  Text(
                    '${_lockedSlots.length} semester(s) locked',
                    style: TextStyle(color: AppColors.aastuGold.withValues(alpha: 0.9), fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _gpaTile(String label, String value, {bool gold = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: gold ? AppColors.aastuGold.withValues(alpha: 0.5) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: gold ? AppColors.aastuGold : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrereqCard(PrerequisiteAnalysis analysis) {
    final hasIssues = analysis.unclearedFailures.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasIssues ? Icons.warning_amber_rounded : Icons.check_circle,
                  color: hasIssues ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 8),
                const Text('Prerequisite Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(analysis.summary, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (analysis.lagSemesters > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Estimated lag: ${analysis.lagSemesters} semester(s)',
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSgpaSection(GpaResult gpa) {
    if (gpa.semesterGpas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Semester GPAs', Icons.bar_chart),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: gpa.semesterGpas.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final s = gpa.semesterGpas[i];
              return Container(
                width: 90,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.aastuBlueLight.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Y${s.year}S${s.sem}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                    const SizedBox(height: 4),
                    Text(
                      s.sgpa.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.aastuGold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
