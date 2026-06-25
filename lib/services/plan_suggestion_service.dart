import '../models/course.dart';
import '../models/student_profile.dart';
import 'gpa_service.dart';
import 'prerequisite_service.dart';

class PlanSuggestionResult {
  final bool success;
  final String message;
  final List<Course> updatedCourses;
  final double projectedCgpa;
  final double requiredSemSgpa;
  final PrerequisiteAnalysis prerequisiteAnalysis;

  const PlanSuggestionResult({
    required this.success,
    required this.message,
    required this.updatedCourses,
    required this.projectedCgpa,
    required this.requiredSemSgpa,
    required this.prerequisiteAnalysis,
  });
}

class PlanSuggestionService {
  PlanSuggestionService._();
  static final PlanSuggestionService instance = PlanSuggestionService._();

  final _gpa = GpaService.instance;
  final _prereq = PrerequisiteService.instance;

  static const _gradableGrades = [
    'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'F',
  ];

  PlanSuggestionResult suggest({
    required StudentProfile profile,
    required List<Course> courses,
    required double targetCgpa,
    required String plannedStream,
  }) {
    final analysis = _prereq.analyze(courses, profile.currentYear, stream: plannedStream);
    final working = courses.map((c) => Course.cloneOf(c)).toList();

    final earned = _pastTotals(working, profile.currentYear, plannedStream);

    _clearPlannableGrades(working, profile.currentYear, plannedStream);

    var remainingCh = _remainingCreditHours(working, profile.currentYear, plannedStream);

    // Failed courses slated for retake: move their CH from earned into the remaining pool.
    final retakeAdjustment = _retakeCreditAdjustment(working, analysis);
    final adjustedEarnedCh = earned.totalCh - retakeAdjustment.ch;
    final adjustedEarnedGp = earned.totalGp;
    remainingCh += retakeAdjustment.ch;

    final totalCh = adjustedEarnedCh + remainingCh;
    final neededGp = targetCgpa * totalCh - adjustedEarnedGp;
    final requiredSemSgpa = remainingCh > 0
        ? (neededGp / remainingCh).clamp(0.0, 4.0)
        : 4.0;

    _applyRetakeGrades(working, analysis, requiredSemSgpa);

    _fillFutureSemesters(
      working,
      profile.currentYear,
      plannedStream,
      requiredSemSgpa,
    );

    _calibrateToTarget(
      working,
      profile.currentYear,
      plannedStream,
      targetCgpa,
    );

    final result = _gpa.compute(
      working,
      upToYear: 5,
      stream: plannedStream,
    );

    final achievable = result.cgpa >= targetCgpa - 0.02;
    final semLabel = requiredSemSgpa.toStringAsFixed(2);

    return PlanSuggestionResult(
      success: achievable,
      message: achievable
          ? 'Plan generated targeting CGPA ${targetCgpa.toStringAsFixed(2)}. '
              'Aim for ~$semLabel SGPA each remaining semester (including internship). '
              'Projected: ${result.cgpa.toStringAsFixed(2)}.'
          : 'Target ${targetCgpa.toStringAsFixed(2)} is very ambitious from your current baseline. '
              'You would need ~$semLabel SGPA per remaining semester. '
              'Best achievable projection: ${result.cgpa.toStringAsFixed(2)}.',
      updatedCourses: working,
      projectedCgpa: result.cgpa,
      requiredSemSgpa: requiredSemSgpa,
      prerequisiteAnalysis: analysis,
    );
  }

  /// Graded courses strictly before [currentYear] (locked academic history).
  ({double totalGp, int totalCh}) _pastTotals(
    List<Course> courses,
    int currentYear,
    String stream,
  ) {
    final passed = _passedCodes(courses);
    var totalGp = 0.0;
    var totalCh = 0;

    for (final c in courses) {
      if (c.year >= currentYear) continue;
      if (c.grade == 'None' || c.grade == 'INC' || c.ch == 0) continue;
      if (!_courseCountsForStream(c, stream)) continue;
      if (c.grade == 'F' && passed.contains(c.code)) continue;

      totalCh += c.ch;
      totalGp += gradingScale[c.grade]! * c.ch;
    }
    return (totalGp: totalGp, totalCh: totalCh);
  }

  /// Clears planned grades from current year onward so re-runs recalculate fresh.
  void _clearPlannableGrades(
    List<Course> courses,
    int currentYear,
    String stream,
  ) {
    for (final c in courses) {
      if (c.year < currentYear) continue;
      if (c.grade == 'None' || c.grade == 'INC') continue;
      if (!_courseCountsForStream(c, stream)) continue;
      c.grade = 'None';
    }
  }

  ({int ch}) _retakeCreditAdjustment(
    List<Course> courses,
    PrerequisiteAnalysis analysis,
  ) {
    var ch = 0;
    for (final retake in analysis.retakeSchedule) {
      for (final c in courses) {
        if (c.code == retake.code && c.grade == 'F') {
          ch += c.ch;
          break;
        }
      }
    }
    return (ch: ch);
  }

  Set<String> _passedCodes(List<Course> courses) {
    return courses
        .where((c) {
          final g = c.grade;
          return g != 'None' && g != 'INC' && g != 'F';
        })
        .map((c) => c.code)
        .toSet();
  }

  bool _courseCountsForStream(Course c, String stream) {
    if (c.stream == 'Common') return true;
    if (c.year < 4) return true;
    return c.stream == stream;
  }

  int _remainingCreditHours(
    List<Course> courses,
    int currentYear,
    String stream,
  ) {
    var ch = 0;
    for (final c in courses) {
      if (c.year < currentYear) continue;
      if (c.grade != 'None') continue;
      if (c.ch == 0) continue;
      if (!_courseCountsForStream(c, stream)) continue;
      ch += c.ch;
    }
    return ch;
  }

  void _applyRetakeGrades(
    List<Course> courses,
    PrerequisiteAnalysis analysis,
    double requiredSemSgpa,
  ) {
    final retakeGrade = _gradeFromGp(requiredSemSgpa);
    for (final retake in analysis.retakeSchedule) {
      final idx = courses.indexWhere(
        (c) => c.code == retake.code && c.grade == 'F',
      );
      if (idx >= 0) {
        courses[idx].grade = retakeGrade;
      }
    }
  }

  void _fillFutureSemesters(
    List<Course> courses,
    int currentYear,
    String stream,
    double requiredSemSgpa,
  ) {
    for (var y = currentYear; y <= 5; y++) {
      for (var s = 1; s <= 2; s++) {
        final semCourses = courses.where((c) {
          if (c.year != y || c.sem != s) return false;
          if (c.grade != 'None') return false;
          if (!_courseCountsForStream(c, stream)) return false;
          return true;
        }).toList();

        if (semCourses.isEmpty) continue;

        final grades = _distributeSemesterGrades(semCourses, requiredSemSgpa);
        for (var i = 0; i < semCourses.length; i++) {
          semCourses[i].grade = semCourses[i].ch == 0 ? 'A' : grades[i];
        }
      }
    }
  }

  /// Iteratively nudge future-course letter grades so projected CGPA ≈ target.
  void _calibrateToTarget(
    List<Course> courses,
    int currentYear,
    String stream,
    double targetCgpa,
  ) {
    const tolerance = 0.015;

    for (var pass = 0; pass < 800; pass++) {
      final cgpa = _gpa.compute(courses, upToYear: 5, stream: stream).cgpa;
      final diff = cgpa - targetCgpa;

      if (diff.abs() <= tolerance) return;

      final adjustable = courses.where((c) {
        if (c.year < currentYear) return false;
        if (c.ch == 0) return false;
        if (c.grade == 'None' || c.grade == 'INC') return false;
        if (!_courseCountsForStream(c, stream)) return false;
        return true;
      }).toList();

      if (adjustable.isEmpty) return;

      if (diff > tolerance) {
        adjustable.sort((a, b) {
          final gpCmp = gradingScale[b.grade]!.compareTo(gradingScale[a.grade]!);
          if (gpCmp != 0) return gpCmp;
          return a.ch.compareTo(b.ch);
        });
        if (!_stepGrade(adjustable.first, up: false)) return;
      } else {
        adjustable.sort((a, b) {
          final gpCmp = gradingScale[a.grade]!.compareTo(gradingScale[b.grade]!);
          if (gpCmp != 0) return gpCmp;
          return b.ch.compareTo(a.ch);
        });
        if (!_stepGrade(adjustable.first, up: true)) return;
      }
    }
  }

  bool _stepGrade(Course course, {required bool up}) {
    final idx = _gradableGrades.indexOf(course.grade);
    if (idx < 0) return false;

    if (up && idx > 0) {
      course.grade = _gradableGrades[idx - 1];
      return true;
    }
    if (!up && idx < _gradableGrades.length - 1) {
      course.grade = _gradableGrades[idx + 1];
      return true;
    }
    return false;
  }

  /// Assigns varied letter grades; higher CH → slightly lower grade within the semester.
  List<String> _distributeSemesterGrades(List<Course> courses, double targetSgpa) {
    final gradable = courses.where((c) => c.ch > 0).toList();
    if (gradable.isEmpty) {
      return courses.map((c) => c.ch == 0 ? 'A' : _gradeFromGp(targetSgpa)).toList();
    }

    final totalCh = gradable.fold<int>(0, (s, c) => s + c.ch);
    final targetTotalGp = targetSgpa * totalCh;
    final maxCh = gradable.map((c) => c.ch).reduce((a, b) => a > b ? a : b);
    final avgCh = totalCh / gradable.length;

    const spread = 0.55;
    final gpByCourse = <Course, double>{};
    for (final c in gradable) {
      final difficulty = maxCh > 0 ? (c.ch - avgCh) / maxCh : 0.0;
      gpByCourse[c] = (targetSgpa - spread * difficulty).clamp(0.0, 4.0);
    }

    var currentGp = 0.0;
    for (final c in gradable) {
      currentGp += gpByCourse[c]! * c.ch;
    }
    if (totalCh > 0) {
      final adjustment = (targetTotalGp - currentGp) / totalCh;
      for (final c in gradable) {
        gpByCourse[c] = (gpByCourse[c]! + adjustment).clamp(0.0, 4.0);
      }
    }

    final gradeByCourse = <Course, String>{};
    for (final c in gradable) {
      gradeByCourse[c] = _gradeFromGp(gpByCourse[c]!);
    }

    _fineTuneSemester(gradable, gradeByCourse, targetTotalGp);

    return courses.map((c) {
      if (c.ch == 0) return 'A';
      return gradeByCourse[c] ?? _gradeFromGp(targetSgpa);
    }).toList();
  }

  void _fineTuneSemester(
    List<Course> gradable,
    Map<Course, String> gradeByCourse,
    double targetTotalGp,
  ) {
    for (var pass = 0; pass < 20; pass++) {
      var currentGp = 0.0;
      var totalCh = 0;
      for (final c in gradable) {
        totalCh += c.ch;
        currentGp += gradingScale[gradeByCourse[c]!]! * c.ch;
      }
      if (totalCh == 0) return;

      final diff = targetTotalGp - currentGp;
      if (diff.abs() < 0.05) return;

      gradable.sort((a, b) => a.ch.compareTo(b.ch));
      final adjustCourse = diff > 0 ? gradable.first : gradable.last;
      final current = gradeByCourse[adjustCourse]!;
      final idx = _gradableGrades.indexOf(current);
      if (idx < 0) return;

      if (diff > 0 && idx > 0) {
        gradeByCourse[adjustCourse] = _gradableGrades[idx - 1];
      } else if (diff < 0 && idx < _gradableGrades.length - 1) {
        gradeByCourse[adjustCourse] = _gradableGrades[idx + 1];
      } else {
        return;
      }
    }
  }

  String _gradeFromGp(double gp) {
    if (gp >= 3.95) return 'A+';
    if (gp >= 3.85) return 'A';
    if (gp >= 3.6) return 'A-';
    if (gp >= 3.35) return 'B+';
    if (gp >= 3.0) return 'B';
    if (gp >= 2.75) return 'B-';
    if (gp >= 2.45) return 'C+';
    if (gp >= 2.0) return 'C';
    if (gp >= 1.75) return 'C-';
    if (gp >= 1.0) return 'D';
    return 'F';
  }
}
