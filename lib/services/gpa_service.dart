import '../models/course.dart';

class SemesterGpa {
  final int year;
  final int sem;
  final double sgpa;
  final int creditHours;
  final bool hasIncomplete;

  const SemesterGpa({
    required this.year,
    required this.sem,
    required this.sgpa,
    required this.creditHours,
    this.hasIncomplete = false,
  });
}

class GpaResult {
  final double cgpa;
  final int totalCreditHours;
  final List<SemesterGpa> semesterGpas;

  const GpaResult({
    required this.cgpa,
    required this.totalCreditHours,
    required this.semesterGpas,
  });
}

class GpaService {
  GpaService._();
  static final GpaService instance = GpaService._();

  bool _countsTowardGpa(String grade) =>
      grade != 'None' && grade != 'INC' && grade != 'PF';

  /// Cleared F if a later passing attempt exists for the same course code.
  Set<String> _passedCodes(List<Course> courses) {
    return courses
        .where((c) {
          final g = c.grade;
          return g != 'None' && g != 'INC' && g != 'F' && g != 'PF';
        })
        .map((c) => c.code)
        .toSet();
  }

  GpaResult compute(
    List<Course> courses, {
    int? upToYear,
    String? stream,
  }) {
    final passed = _passedCodes(courses);
    final semesterGpas = <SemesterGpa>[];
    var totalGp = 0.0;
    var totalCh = 0;

    final years = upToYear != null
        ? List.generate(upToYear, (i) => i + 1)
        : courses.map((c) => c.year).toSet().toList()..sort();

    for (final year in years) {
      for (var sem = 1; sem <= 2; sem++) {
        final semCourses = courses.where((c) {
          if (c.year != year || c.sem != sem) return false;
          if (c.stream == 'Common') return true;
          if (year < 4) return false;
          return stream != null && c.stream == stream;
        }).toList();

        if (semCourses.isEmpty) continue;

        var semGp = 0.0;
        var semCh = 0;
        var hasInc = false;

        for (final c in semCourses) {
          if (c.grade == 'INC') hasInc = true;
          if (!_countsTowardGpa(c.grade) || c.ch == 0) continue;
          if (c.grade == 'F' && passed.contains(c.code)) continue;

          semCh += c.ch;
          semGp += gradingScale[c.grade]! * c.ch;
        }

        if (semCh > 0) {
          semesterGpas.add(
            SemesterGpa(
              year: year,
              sem: sem,
              sgpa: semGp / semCh,
              creditHours: semCh,
              hasIncomplete: hasInc,
            ),
          );
          totalCh += semCh;
          totalGp += semGp;
        } else if (hasInc) {
          semesterGpas.add(
            SemesterGpa(
              year: year,
              sem: sem,
              sgpa: 0,
              creditHours: 0,
              hasIncomplete: true,
            ),
          );
        }
      }
    }

    return GpaResult(
      cgpa: totalCh > 0 ? totalGp / totalCh : 0,
      totalCreditHours: totalCh,
      semesterGpas: semesterGpas,
    );
  }

  ({double totalGp, int totalCh}) rawTotals(List<Course> courses, {String? stream}) {
    final passed = _passedCodes(courses);
    var totalGp = 0.0;
    var totalCh = 0;

    for (final c in courses) {
      if (c.grade == 'None' || c.grade == 'INC' || c.ch == 0) continue;
      if (c.stream != 'Common' && (stream == null || c.stream != stream)) continue;
      if (c.grade == 'F' && passed.contains(c.code)) continue;
      totalCh += c.ch;
      totalGp += gradingScale[c.grade]! * c.ch;
    }
    return (totalGp: totalGp, totalCh: totalCh);
  }
}
