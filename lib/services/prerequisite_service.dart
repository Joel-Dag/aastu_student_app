import '../models/course.dart';

class RetakeSlot {
  final String code;
  final String name;
  final int ch;
  final int originalYear;
  final int originalSem;
  final int scheduledYear;
  final int scheduledSem;

  const RetakeSlot({
    required this.code,
    required this.name,
    required this.ch,
    required this.originalYear,
    required this.originalSem,
    required this.scheduledYear,
    required this.scheduledSem,
  });
}

class PrerequisiteAnalysis {
  final List<String> unclearedFailures;
  final List<RetakeSlot> retakeSchedule;
  final int lagSemesters;
  final Map<String, int> delayedCourses;
  final String summary;

  const PrerequisiteAnalysis({
    required this.unclearedFailures,
    required this.retakeSchedule,
    required this.lagSemesters,
    required this.delayedCourses,
    required this.summary,
  });
}

class PrerequisiteService {
  PrerequisiteService._();
  static final PrerequisiteService instance = PrerequisiteService._();

  Set<String> unclearedFailures(List<Course> courses) {
    final passed = courses
        .where((c) =>
            c.grade != 'None' &&
            c.grade != 'INC' &&
            c.grade != 'F' &&
            c.grade != 'PF')
        .map((c) => c.code)
        .toSet();

    return courses
        .where((c) => c.grade == 'F' && !passed.contains(c.code))
        .map((c) => c.code)
        .toSet();
  }

  /// Find earliest future semester matching parity (sem 2 retakes only in sem 2).
  ({int year, int sem})? _nextRetakeSlot(
    int fromYear,
    int targetSem,
    Set<String> occupied,
    String code,
  ) {
    for (var y = fromYear; y <= 6; y++) {
      for (var s = 1; s <= 2; s++) {
        if (y == fromYear && s < targetSem) continue;
        if (s != targetSem) continue;
        final key = 'RETAKE|$code|$y|$s';
        if (!occupied.contains(key)) {
          return (year: y, sem: s);
        }
      }
    }
    return null;
  }

  PrerequisiteAnalysis analyze(
    List<Course> allCourses,
    int currentYear, {
    String? stream,
  }) {
    final failures = unclearedFailures(allCourses);
    final codeToCourse = <String, Course>{};
    for (final c in allCourses) {
      codeToCourse.putIfAbsent(c.code, () => c);
    }

    final retakes = <RetakeSlot>[];
    final occupied = <String>{};
    final delayed = <String, int>{};

    for (final code in failures) {
      final original = allCourses.firstWhere(
        (c) => c.code == code && c.grade == 'F',
        orElse: () => codeToCourse[code]!,
      );
      final slot = _nextRetakeSlot(
        currentYear,
        original.sem,
        occupied,
        code,
      );
      if (slot != null) {
        occupied.add('RETAKE|$code|${slot.year}|${slot.sem}');
        retakes.add(
          RetakeSlot(
            code: code,
            name: original.name,
            ch: original.ch,
            originalYear: original.year,
            originalSem: original.sem,
            scheduledYear: slot.year,
            scheduledSem: slot.sem,
          ),
        );
      }
    }

    var maxLag = 0;
    for (final c in allCourses) {
      if (c.year >= currentYear) continue;
      if (!_isBlocked(c, failures, allCourses)) continue;

      final blockedBy = c.prerequisites.where(failures.contains).toList();
      if (blockedBy.isEmpty) continue;

      var lag = 0;
      for (final prereq in blockedBy) {
        final retake = retakes.firstWhere(
          (r) => r.code == prereq,
          orElse: () => retakes.isNotEmpty
              ? retakes.first
              : RetakeSlot(
                  code: prereq,
                  name: prereq,
                  ch: 0,
                  originalYear: 1,
                  originalSem: 1,
                  scheduledYear: currentYear,
                  scheduledSem: 1,
                ),
        );
        final semIndex = retake.scheduledYear * 2 + retake.scheduledSem;
        final courseIndex = c.year * 2 + c.sem;
        final diff = semIndex - courseIndex;
        if (diff > lag) lag = diff;
      }
      if (lag > 0) {
        delayed[c.code] = lag;
        if (lag > maxLag) maxLag = lag;
      }
    }

    final lagSemesters = maxLag;
    String summary;
    if (failures.isEmpty) {
      summary = 'No uncleared failures. You are on the standard track.';
    } else {
      summary =
          '${failures.length} failed course(s) require retakes. '
          'Prerequisite chains may delay up to $lagSemesters semester(s). '
          'Semester-II failures can only be retaken in future second semesters.';
    }

    return PrerequisiteAnalysis(
      unclearedFailures: failures.toList(),
      retakeSchedule: retakes,
      lagSemesters: lagSemesters,
      delayedCourses: delayed,
      summary: summary,
    );
  }

  bool _isBlocked(Course course, Set<String> failures, List<Course> all) {
    for (final prereq in course.prerequisites) {
      if (failures.contains(prereq)) return true;
      final prereqCourse = all.where((c) => c.code == prereq).firstOrNull;
      if (prereqCourse != null && prereqCourse.grade == 'F') {
        if (!all.any((c) => c.code == prereq && c.grade != 'F' && c.grade != 'None' && c.grade != 'INC')) {
          return true;
        }
      }
    }
    return false;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
