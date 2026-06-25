import '../curricula/ece_curriculum.dart';
import '../curricula/freshman.dart';
import '../models/course.dart';
import '../models/student_profile.dart';

class AcademicService {
  AcademicService._();
  static final AcademicService instance = AcademicService._();

  static const departmentEce = 'Electrical & Computer Engineering';

  List<Course> getCurriculum({String department = departmentEce}) {
    final courses = <Course>[...getFreshmanCourses()];
    if (department == departmentEce) {
      courses.addAll(getEceCourses());
    }
    return courses;
  }

  List<Course> buildStudentCourses(StudentProfile profile) {
    return cloneCourses(getCurriculum(department: profile.department));
  }

  /// Courses visible for a given year/semester based on stream selection.
  List<Course> coursesForSemester(
    List<Course> all,
    int year,
    int sem,
    String? stream,
  ) {
    return all.where((c) {
      if (c.year != year || c.sem != sem) return false;
      if (c.stream == 'Common') return true;
      if (year < 4) return false;
      return stream != null && c.stream == stream;
    }).toList();
  }

  /// All semesters strictly before [currentYear].
  List<({int year, int sem})> pastSemesters(int currentYear) {
    final slots = <({int year, int sem})>[];
    for (var y = 1; y < currentYear; y++) {
      slots.add((year: y, sem: 1));
      slots.add((year: y, sem: 2));
    }
    return slots;
  }

  /// Current year through year 5 (preview / planning semesters).
  List<({int year, int sem})> currentAndFutureSemesters(int currentYear) {
    final slots = <({int year, int sem})>[];
    for (var y = currentYear; y <= 5; y++) {
      slots.add((year: y, sem: 1));
      slots.add((year: y, sem: 2));
    }
    return slots;
  }

  /// Future semesters from current year through year 5.
  List<({int year, int sem})> futureSemesters(int currentYear) {
    return currentAndFutureSemesters(currentYear);
  }

  /// Semesters available for the lock picker (past + current year).
  List<({int year, int sem})> lockableSemesters(int currentYear) {
    final slots = <({int year, int sem})>[];
    for (var y = 1; y <= currentYear; y++) {
      slots.add((year: y, sem: 1));
      slots.add((year: y, sem: 2));
    }
    return slots;
  }

  bool isStreamSemester(int year, int sem) => year == 4 && sem == 2;

  int countIncomplete(List<Course> courses) =>
      courses.where((c) => c.grade == 'INC').length;

  void applyGrades(List<Course> courses, Map<String, String> grades) {
    for (final course in courses) {
      if (grades.containsKey(course.key)) {
        course.grade = grades[course.key]!;
      }
    }
  }

  Map<String, String> extractGrades(List<Course> courses) {
    return {
      for (final c in courses)
        if (c.grade != 'None') c.key: c.grade,
    };
  }
}
