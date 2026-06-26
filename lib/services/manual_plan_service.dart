import '../models/course.dart';
import '../models/manual_plan_state.dart';

class CoursePickerGroup {
  final int year;
  final int sem;
  final List<CoursePickerItem> courses;

  const CoursePickerGroup({
    required this.year,
    required this.sem,
    required this.courses,
  });
}

class CoursePickerItem {
  final Course course;
  final bool selectable;
  final String? blockReason;

  const CoursePickerItem({
    required this.course,
    required this.selectable,
    this.blockReason,
  });
}

class ManualPlanService {
  ManualPlanService._();
  static final ManualPlanService instance = ManualPlanService._();

  static const minCreditHours = 15;
  static const maxCreditHoursDefault = 20;
  static const maxCreditHoursYear5WithCgpa = 22;
  static const cgpaThresholdForExtraCredits = 2.5;

  int semIndex(int year, int sem) => year * 2 + sem;

  ({int year, int sem}) nextSemester(int year, int sem) {
    if (sem == 1) return (year: year, sem: 2);
    return (year: year + 1, sem: 1);
  }

  bool isPrerequisiteForAny(String code, List<Course> curriculum) {
    return curriculum.any((c) => c.prerequisites.contains(code));
  }

  Set<String> passedCodes(List<Course> courses) {
    return courses
        .where((c) {
          final g = c.grade;
          return g != 'None' && g != 'INC' && g != 'F' && g != 'PF';
        })
        .map((c) => c.code)
        .toSet();
  }

  Set<String> unclearedFailures(List<Course> courses) {
    final passed = passedCodes(courses);
    return courses
        .where((c) => c.grade == 'F' && !passed.contains(c.code))
        .map((c) => c.code)
        .toSet();
  }

  List<Course> blockingFailures(List<Course> courses, List<Course> curriculum) {
    final failures = unclearedFailures(courses);
    return courses
        .where(
          (c) =>
              c.grade == 'F' &&
              failures.contains(c.code) &&
              isPrerequisiteForAny(c.code, curriculum),
        )
        .toList();
  }

  bool countsForStream(Course c, String stream) {
    if (c.stream == 'Common') return true;
    if (c.year < 4) return true;
    return c.stream == stream;
  }

  List<Course> streamCourses(List<Course> all, String stream) {
    return all.where((c) => countsForStream(c, stream)).toList();
  }

  bool isSlotInPlanRange(
    ManualPlanState plan,
    int year,
    int sem,
  ) {
    if (!plan.active) return false;
    return semIndex(year, sem) >= semIndex(plan.clearFromYear, plan.clearFromSem);
  }

  ManualPlanState earliestClearFrom(List<Course> blocking) {
    if (blocking.isEmpty) {
      return const ManualPlanState();
    }
    var clearYear = 5;
    var clearSem = 2;
    var minIndex = 999;

    for (final f in blocking) {
      final next = nextSemester(f.year, f.sem);
      final idx = semIndex(next.year, next.sem);
      if (idx < minIndex) {
        minIndex = idx;
        clearYear = next.year;
        clearSem = next.sem;
      }
    }

    return ManualPlanState(
      active: true,
      clearFromYear: clearYear,
      clearFromSem: clearSem,
    );
  }

  ManualPlanState activatePlan({
    required ManualPlanState current,
    required List<Course> blocking,
  }) {
    final earliest = earliestClearFrom(blocking);
    if (!earliest.active) return current;

    final currentIdx = current.active
        ? semIndex(current.clearFromYear, current.clearFromSem)
        : 999;
    final newIdx = semIndex(earliest.clearFromYear, earliest.clearFromSem);

    if (current.active && newIdx >= currentIdx) {
      return current;
    }

    final prunedSlots = <String, List<String>>{};
    if (current.active && newIdx < currentIdx) {
      for (final entry in current.slotCourseKeys.entries) {
        final parts = entry.key.split('|');
        if (parts.length != 2) continue;
        final y = int.tryParse(parts[0]);
        final s = int.tryParse(parts[1]);
        if (y == null || s == null) continue;
        if (semIndex(y, s) >= newIdx) continue;
        prunedSlots[entry.key] = List.from(entry.value);
      }
    }

    return ManualPlanState(
      active: true,
      clearFromYear: earliest.clearFromYear,
      clearFromSem: earliest.clearFromSem,
      slotCourseKeys: newIdx < currentIdx ? prunedSlots : current.slotCourseKeys,
    );
  }

  void clearUnlockedFutureGrades({
    required List<Course> courses,
    required ManualPlanState plan,
    required Set<String> lockedSlots,
    required String stream,
  }) {
    for (final c in courses) {
      if (!countsForStream(c, stream)) continue;
      if (!isSlotInPlanRange(plan, c.year, c.sem)) continue;
      final key = ManualPlanState.slotKey(c.year, c.sem);
      if (lockedSlots.contains(key)) continue;
      if (c.grade != 'PF') c.grade = 'None';
    }
  }

  Set<String> allPlannedKeys(ManualPlanState plan) {
    return plan.slotCourseKeys.values.expand((keys) => keys).toSet();
  }

  List<Course> coursesForSlot({
    required ManualPlanState plan,
    required List<Course> allCourses,
    required int year,
    required int sem,
  }) {
    final keys = plan.keysFor(year, sem);
    final result = <Course>[];
    for (final key in keys) {
      final course = allCourses.where((c) => c.key == key).firstOrNull;
      if (course != null) result.add(course);
    }
    return result;
  }

  int creditHoursFor(List<Course> courses) {
    return courses.where((c) => c.ch > 0).fold(0, (s, c) => s + c.ch);
  }

  int maxCreditsFor(int year, double priorCgpa) {
    if (year < 5) return maxCreditHoursDefault;
    if (priorCgpa > cgpaThresholdForExtraCredits) {
      return maxCreditHoursYear5WithCgpa;
    }
    return maxCreditHoursDefault;
  }

  bool isBlockedByFailures(Course course, Set<String> failures) {
    for (final prereq in course.prerequisites) {
      if (failures.contains(prereq)) return true;
    }
    return false;
  }

  String prereqLabel(Course course, List<Course> curriculum) {
    if (course.prerequisites.isEmpty) return 'No prerequisites';
    final names = course.prerequisites.map((code) {
      final match = curriculum.where((c) => c.code == code).firstOrNull;
      return match != null ? '${match.name} ($code)' : code;
    }).join(', ');
    return 'Requires: $names';
  }

  List<CoursePickerGroup> buildPickerGroups({
    required List<Course> allCourses,
    required String stream,
    required int targetYear,
    required int targetSem,
    required ManualPlanState plan,
    required Set<String> failures,
  }) {
    final passed = passedCodes(allCourses);
    final planned = allPlannedKeys(plan);
    final relevant = streamCourses(allCourses, stream)
        .where((c) => c.sem == targetSem)
        .where((c) => !passed.contains(c.code))
        .where((c) => !planned.contains(c.key))
        .toList();

    final bySlot = <String, List<Course>>{};
    for (final c in relevant) {
      final key = ManualPlanState.slotKey(c.year, c.sem);
      bySlot.putIfAbsent(key, () => []).add(c);
    }

    final groups = <CoursePickerGroup>[];
    final sortedKeys = bySlot.keys.toList()
      ..sort((a, b) {
        final pa = a.split('|');
        final pb = b.split('|');
        final ia = semIndex(int.parse(pa[0]), int.parse(pa[1]));
        final ib = semIndex(int.parse(pb[0]), int.parse(pb[1]));
        return ia.compareTo(ib);
      });

    for (final key in sortedKeys) {
      final parts = key.split('|');
      final y = int.parse(parts[0]);
      final s = int.parse(parts[1]);
      final items = bySlot[key]!
          .map((course) {
            final blocked = isBlockedByFailures(course, failures);
            return CoursePickerItem(
              course: course,
              selectable: !blocked,
              blockReason: blocked
                  ? 'Blocked: uncleared failed prerequisite'
                  : null,
            );
          })
          .toList()
        ..sort((a, b) => a.course.name.compareTo(b.course.name));

      groups.add(CoursePickerGroup(year: y, sem: s, courses: items));
    }

    return groups;
  }

  int countCoursesNotInPlan({
    required List<Course> allCourses,
    required String stream,
    required ManualPlanState plan,
  }) {
    if (!plan.active) return 0;
    final passed = passedCodes(allCourses);
    final planned = allPlannedKeys(plan);
    return streamCourses(allCourses, stream)
        .where((c) => c.ch > 0)
        .where((c) => !passed.contains(c.code))
        .where((c) => !planned.contains(c.key))
        .length;
  }

  ManualPlanState addCourseToSlot({
    required ManualPlanState plan,
    required int year,
    required int sem,
    required String courseKey,
  }) {
    final slot = ManualPlanState.slotKey(year, sem);
    final updated = Map<String, List<String>>.from(plan.slotCourseKeys);
    final list = List<String>.from(updated[slot] ?? []);
    if (!list.contains(courseKey)) list.add(courseKey);
    updated[slot] = list;
    return plan.copyWith(slotCourseKeys: updated);
  }

  ManualPlanState removeCourseFromSlot({
    required ManualPlanState plan,
    required int year,
    required int sem,
    required String courseKey,
  }) {
    final slot = ManualPlanState.slotKey(year, sem);
    final updated = Map<String, List<String>>.from(plan.slotCourseKeys);
    final list = List<String>.from(updated[slot] ?? [])..remove(courseKey);
    if (list.isEmpty) {
      updated.remove(slot);
    } else {
      updated[slot] = list;
    }
    return plan.copyWith(slotCourseKeys: updated);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
