import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/manual_plan_state.dart';
import '../models/student_profile.dart';
import '../services/academic_service.dart';
import '../services/gpa_service.dart';
import '../services/manual_plan_service.dart';
import '../services/plan_suggestion_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_course_sheet.dart';
import '../widgets/grade_dropdown.dart';
import '../widgets/incomplete_warning_banner.dart';
import '../widgets/semester_table_card.dart';
import 'about_us_screen.dart';
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
  Set<String> _finishedSlots = {};
  bool _internshipLocked = false;
  bool _planApplied = false;
  bool _loading = true;
  String _previewStream = eceStreams.first;
  ManualPlanState _manualPlan = const ManualPlanState();
  int _coursesNotInPlan = 0;

  final _academic = AcademicService.instance;
  final _storage = StorageService.instance;
  final _plan = PlanSuggestionService.instance;
  final _manualPlanner = ManualPlanService.instance;

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

    final finishedSlots = await _storage.loadFinishedSlots();
    final internshipLocked = await _storage.loadInternshipLocked() ?? false;
    final planApplied = await _storage.isPlanApplied();
    var manualPlan = await _storage.loadManualPlan();
    final stream = profile.effectiveStream();

    final blocking = _manualPlanner.blockingFailures(courses, courses);
    if (blocking.isNotEmpty) {
      final activated = _manualPlanner.activatePlan(
        current: manualPlan,
        blocking: blocking,
      );
      if (activated.active) {
        final firstActivation = !manualPlan.active;
        manualPlan = activated;
        if (firstActivation) {
          manualPlan = _stripSlotsInRange(manualPlan);
        }
        _manualPlanner.clearUnlockedFutureGrades(
          courses: courses,
          plan: manualPlan,
          lockedSlots: lockedSlots,
          stream: stream,
        );
        await _storage.saveManualPlan(manualPlan);
        await _storage.saveGrades(_academic.extractGrades(courses));
      }
    }

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _courses = courses;
      _lockedSlots = lockedSlots;
      _finishedSlots = finishedSlots;
      _internshipLocked = internshipLocked;
      _planApplied = planApplied;
      _previewStream = stream;
      _manualPlan = manualPlan;
      _loading = false;
    });
    _recomputeAnalysis();
  }

  ManualPlanState _stripSlotsInRange(ManualPlanState plan) {
    final kept = <String, List<String>>{};
    for (final entry in plan.slotCourseKeys.entries) {
      final parts = entry.key.split('|');
      if (parts.length != 2) continue;
      final y = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      if (y == null || s == null) continue;
      if (_manualPlanner.isSlotInPlanRange(plan, y, s)) continue;
      kept[entry.key] = List.from(entry.value);
    }
    return plan.copyWith(slotCourseKeys: kept);
  }

  Future<void> _persist() async {
    await _storage.saveGrades(_academic.extractGrades(_courses));
  }

  Future<void> _persistManualPlan() async {
    await _storage.saveManualPlan(_manualPlan);
  }

  void _recomputeAnalysis() {
    if (_profile == null) return;
    final stream = _profile!.effectiveStream(_previewStream);
    _coursesNotInPlan = _manualPlanner.countCoursesNotInPlan(
      allCourses: _courses,
      stream: stream,
      plan: _manualPlan,
    );
  }

  bool _isSlotLocked(int year, int sem) =>
      _lockedSlots.contains(StorageService.slotKey(year, sem));

  bool _isSlotFinished(int year, int sem) =>
      _finishedSlots.contains(StorageService.slotKey(year, sem));

  Future<void> _toggleFinishedSlot(int year, int sem, bool finished) async {
    final key = StorageService.slotKey(year, sem);
    setState(() {
      if (finished) {
        _finishedSlots.add(key);
      } else {
        _finishedSlots.remove(key);
      }
    });
    await _storage.saveFinishedSlots(_finishedSlots);
    _recomputeAnalysis();
  }

  Future<void> _confirmFinishSemester(int year, int sem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Finished this semester?'),
        content: Text('Have you finished Year $year Semester $sem? This will move it to Past Semesters.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (confirmed == true) {
      await _toggleFinishedSlot(year, sem, true);
    }
  }

  String _academicStatusMessage(Set<String> failures, int incompleteCount) {
    if (failures.isNotEmpty || incompleteCount > 0) return '';

    final unadded = _manualPlanner.countCoursesNotInPlan(
      allCourses: _courses,
      stream: _profile!.effectiveStream(_previewStream),
      plan: _manualPlan,
    );

    if (unadded == 0) {
      return 'Keep going on this track and you will graduate on time.';
    }

    final lag = _estimateSemesterLag(unadded);
    return 'Keep going on this track. You will graduate on a $lag semester lag if remaining courses are not added yet.';
  }

  int _estimateSemesterLag(int remainingCourses) {
    if (remainingCourses <= 2) return 0;
    if (remainingCourses <= 4) return 1;
    if (remainingCourses <= 6) return 2;
    return 3;
  }

  Future<void> _handleGradeChange(Course course, String grade) async {
    if (_isSlotLocked(course.year, course.sem)) return;

    final prevManualActive = _manualPlan.active;

    setState(() {
      final idx = _courses.indexWhere((c) => c.key == course.key);
      if (idx >= 0) _courses[idx].grade = grade;
    });
    await _persist();

    if (grade == 'F') {
      if (!_manualPlanner.isPrerequisiteForAny(course.code, _courses)) {
        setState(() => _recomputeAnalysis());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${course.name} marked as F. This is not a prerequisite for other courses — your semester cards are unchanged.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
      await _activateManualPlanning(showAlert: !prevManualActive);
      return;
    }
  }

  Future<void> _activateManualPlanning({required bool showAlert}) async {
    if (_profile == null) return;
    final stream = _profile!.effectiveStream(_previewStream);
    final blocking = _manualPlanner.blockingFailures(_courses, _courses);
    if (blocking.isEmpty) return;

    var plan = _manualPlanner.activatePlan(
      current: _manualPlan,
      blocking: blocking,
    );
    if (!plan.active) return;

    if (!_manualPlan.active) {
      plan = _stripSlotsInRange(plan);
    }

    _manualPlanner.clearUnlockedFutureGrades(
      courses: _courses,
      plan: plan,
      lockedSlots: _lockedSlots,
      stream: stream,
    );

    setState(() {
      _manualPlan = plan;
      _recomputeAnalysis();
    });

    await _persist();
    await _persistManualPlan();

    if (showAlert && mounted) {
      final names = blocking.map((c) => c.name).join(', ');
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Plan Your Remaining Semesters'),
          content: Text(
            'You failed $names, which is a prerequisite for future courses. '
            'Unlocked semesters from Year ${plan.clearFromYear} Sem ${plan.clearFromSem} onward have been cleared. '
            'Use Add Course on each semester to build your custom graduation plan.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _addCourseToSlot(int year, int sem, Course course) async {
    setState(() {
      _manualPlan = _manualPlanner.addCourseToSlot(
        plan: _manualPlan,
        year: year,
        sem: sem,
        courseKey: course.key,
      );
      final idx = _courses.indexWhere((c) => c.key == course.key);
      if (idx >= 0 && _courses[idx].grade != 'F') {
        _courses[idx].grade = 'None';
      }
      _recomputeAnalysis();
    });
    await _persistManualPlan();
    await _persist();
  }

  Future<void> _removeCourseFromSlot(int year, int sem, Course course) async {
    setState(() {
      _manualPlan = _manualPlanner.removeCourseFromSlot(
        plan: _manualPlan,
        year: year,
        sem: sem,
        courseKey: course.key,
      );
      if (!_manualPlanner.allPlannedKeys(_manualPlan).contains(course.key)) {
        final idx = _courses.indexWhere((c) => c.key == course.key);
        if (idx >= 0) _courses[idx].grade = 'None';
      }
      _recomputeAnalysis();
    });
    await _persistManualPlan();
    await _persist();
  }

  Future<void> _showLockDialog() async {
    if (_profile == null) return;

    final slots = [
      for (var year = 1; year <= 5; year++)
        for (var sem = 1; sem <= 2; sem++)
          (year: year, sem: sem),
    ];
    final selected = Set<String>.from(_lockedSlots);
    var internshipLocked = _internshipLocked;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            final children = <Widget>[];
            for (final slot in slots) {
              final key = StorageService.slotKey(slot.year, slot.sem);
              final checked = selected.contains(key);
              children.add(CheckboxListTile(
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
              ));
              if (slot.year == 4 && slot.sem == 2) {
                children.add(
                  CheckboxListTile(
                    value: internshipLocked,
                    activeColor: AppColors.aastuGold,
                    title: const Text('Lock Industry Internship grade'),
                    onChanged: (v) {
                      setDialog(() {
                        internshipLocked = v == true;
                      });
                    },
                  ),
                );
              }
            }

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
                        children: children,
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

    setState(() {
      _lockedSlots = selected;
      _internshipLocked = internshipLocked;
    });
    await _storage.saveLockedSlots(selected);
    await _storage.setInternshipLocked(internshipLocked);

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
      _recomputeAnalysis();
    });
  }

  void _onPreviewStreamChanged(String stream) {
    setState(() {
      _previewStream = stream;
      _recomputeAnalysis();
    });
    _savePreviewStream(stream);
  }

  String _streamForSlot(int year, int sem) {
    return _profile!.currentStream ?? _previewStream;
  }

  Course? _findInternshipCourse(String stream) {
    try {
      return _courses.firstWhere(
        (course) => _manualPlanner.isInternship(course) && course.year == 4 && course.sem == 2 && course.stream == stream,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildInternshipCard(
    Course internship, {
    required bool locked,
    required bool isPreview,
    required bool manualPlanMode,
    VoidCallback? onRemove,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isPreview ? null : AppTheme.heroGradient,
              color: isPreview ? AppColors.aastuBlueDark.withValues(alpha: 0.6) : null,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.aastuGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work_outline, color: AppColors.aastuGold),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Industry Internship',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${internship.ch} CH',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        internship.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${internship.code} • Year ${internship.year} Sem ${internship.sem}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.warning, size: 20),
                    tooltip: 'Remove from plan',
                    onPressed: onRemove,
                  ),
                GradeDropdown(
                  value: internship.grade,
                  enabled: !locked && !isPreview,
                  onChanged: (grade) async {
                    if (locked || isPreview) return;
                    await _handleGradeChange(internship, grade);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      finishedSlots: _finishedSlots,
    );

    setState(() {
      _courses = result.updatedCourses;
      _planApplied = true;
      _previewStream = stream;
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
          child: Text(result.message),
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

    final pastKeys = {
      for (final slot in _academic.pastSemesters(profile.currentYear))
        StorageService.slotKey(slot.year, slot.sem),
      ..._finishedSlots,
    };
    final pastSlots = pastKeys
        .map((key) {
          final parts = key.split('|');
          if (parts.length != 2) return null;
          final year = int.tryParse(parts[0]);
          final sem = int.tryParse(parts[1]);
          if (year == null || sem == null) return null;
          return (year: year, sem: sem);
        })
        .whereType<({int year, int sem})>()
        .toList()
      ..sort((a, b) {
        final ai = a.year * 2 + a.sem;
        final bi = b.year * 2 + b.sem;
        return ai.compareTo(bi);
      });
    final upcomingSlots = _academic.currentAndFutureSemesters(profile.currentYear)
        .where((slot) => !_finishedSlots.contains(StorageService.slotKey(slot.year, slot.sem)))
        .toList();
    final incCount = _academic.countIncomplete(_courses);
    final anyLocked = _lockedSlots.isNotEmpty;
    final failures = _manualPlanner.unclearedFailures(_courses);
    final internshipCourse = _findInternshipCourse(stream);
    final statusMessage = _academicStatusMessage(failures, incCount);

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
              } else if (v == 'about') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                );
              } else if (v == 'reset') {
                _resetApp();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit past grades')),
              const PopupMenuItem(value: 'about', child: Text('About Us')),
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
            if (_manualPlan.active) _buildManualPlanBanner(),
            if (failures.isNotEmpty || _manualPlan.active || statusMessage.isNotEmpty)
              _buildStatusCard(failures, statusMessage),
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
                _manualPlan.active
                    ? 'Plan Your Remaining Semesters'
                    : (_planApplied ? 'Planned Future Semesters' : 'Current & Upcoming'),
                _manualPlan.active ? Icons.edit_calendar : Icons.upcoming,
              ),
              for (final slot in upcomingSlots) ...[
                _buildSemesterCard(
                  slot,
                  stream,
                  isPast: false,
                  showPlannedOnly: _planApplied,
                  onFinishSemester: !_isSlotFinished(slot.year, slot.sem)
                      ? () => _confirmFinishSemester(slot.year, slot.sem)
                      : null,
                ),
                if (slot.year == 4 && slot.sem == 2 && internshipCourse != null)
                  _buildInternshipCard(
                    internshipCourse,
                    locked: _isSlotLocked(4, 2) || _internshipLocked,
                    isPreview: 4 > profile.currentYear,
                    manualPlanMode: _manualPlan.active,
                    onRemove: _manualPlan.active && _manualPlanner.allPlannedKeys(_manualPlan).contains(internshipCourse.key)
                        ? () => _removeCourseFromSlot(4, 2, internshipCourse)
                        : null,
                  ),
              ],
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

  Widget _buildManualPlanBanner() {
    return Card(
      color: AppColors.aastuBlueDark.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.edit_calendar, color: AppColors.aastuGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Custom graduation plan active',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _coursesNotInPlan > 0
                        ? '$_coursesNotInPlan course(s) not yet added to your plan.'
                        : 'All required courses are in your plan.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Set<String> failures, String statusMessage) {
    final blocking = _manualPlanner.blockingFailures(_courses, _courses);
    final nonBlocking = failures
        .where((code) => !_manualPlanner.isPrerequisiteForAny(code, _courses))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  blocking.isNotEmpty ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: blocking.isNotEmpty ? AppColors.warning : AppColors.aastuBlueLight,
                ),
                const SizedBox(width: 8),
                const Text('Academic Status', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (blocking.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'You failed ${blocking.map((c) => c.name).join(', ')} — prerequisite course(s). '
                'Build your remaining semesters using Add Course on each unlocked card.',
                style: const TextStyle(color: AppColors.warning, fontSize: 13),
              ),
            ],
            if (nonBlocking.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Failed (no prerequisite impact): ${nonBlocking.join(', ')}. '
                'Retake when available; your semester cards are unchanged.',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            if (statusMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                statusMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            if (failures.isEmpty && _manualPlan.active && statusMessage.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Continue adding courses to complete your graduation plan.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterCard(
    ({int year, int sem}) slot,
    String stream, {
    required bool isPast,
    bool showPlannedOnly = false,
    VoidCallback? onFinishSemester,
  }) {
    final slotStream = _streamForSlot(slot.year, slot.sem);
    final locked = _isSlotLocked(slot.year, slot.sem);
    final inManualRange = _manualPlan.active &&
        _manualPlanner.isSlotInPlanRange(_manualPlan, slot.year, slot.sem) &&
        !locked &&
        !isPast;

    List<Course> semCourses;
    var manualPlanMode = false;
    int? minCredits;
    int? maxCredits;

    if (inManualRange) {
      semCourses = _manualPlanner.coursesForSlot(
        plan: _manualPlan,
        allCourses: _courses,
        year: slot.year,
        sem: slot.sem,
      );
      manualPlanMode = true;
      minCredits = ManualPlanService.minCreditHours;
      maxCredits = _manualPlanner.maxCreditsFor(
        slot.year,
        GpaService.instance
            .compute(_courses, upToYear: _profile!.currentYear - 1)
            .cgpa,
      );
    } else {
      semCourses = _academic.coursesForSemester(
        _courses, slot.year, slot.sem, slotStream,
      );
      if (showPlannedOnly) {
        semCourses = semCourses.where((c) => c.grade != 'None').toList();
        if (semCourses.isEmpty) return const SizedBox.shrink();
      }
    }

    if (slot.year == 4 && slot.sem == 2) {
      semCourses = semCourses.where((c) => !_manualPlanner.isInternship(c)).toList();
      if (showPlannedOnly && semCourses.isEmpty && !manualPlanMode) {
        // Keep the semester visible only if there are other planned courses.
      }
    }

    final isFutureYear = slot.year > _profile!.currentYear;
    final isPreview = isFutureYear && !showPlannedOnly && !manualPlanMode;

    return SemesterTableCard(
      year: slot.year,
      sem: slot.sem,
      courses: semCourses,
      locked: locked || (showPlannedOnly && !manualPlanMode),
      isPreview: isPreview,
      manualPlanMode: manualPlanMode,
      minCredits: minCredits,
      maxCredits: maxCredits,
      selectedStream: _academic.isStreamSemester(slot.year, slot.sem) ? slotStream : null,
      onStreamChanged: _academic.isStreamSemester(slot.year, slot.sem) && !showPlannedOnly
          ? _onPreviewStreamChanged
          : null,
      onGradeChanged: locked || isPreview ? (_, _) {} : _handleGradeChange,
      onAddCourse: manualPlanMode
          ? () => showAddCourseSheet(
                context: context,
                allCourses: _courses,
                stream: slotStream,
                targetYear: slot.year,
                targetSem: slot.sem,
                plan: _manualPlan,
                failures: _manualPlanner.unclearedFailures(_courses),
                onCourseSelected: (c) => _addCourseToSlot(slot.year, slot.sem, c),
              )
          : null,
      onRemoveCourse: manualPlanMode
          ? (c) => _removeCourseFromSlot(slot.year, slot.sem, c)
          : null,
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
