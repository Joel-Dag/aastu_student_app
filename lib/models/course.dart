class Course {
  final String code;
  final String name;
  final int ch;
  final int year;
  final int sem;
  final String stream;
  final List<String> prerequisites;
  String grade;

  Course({
    required this.code,
    required this.name,
    required this.ch,
    required this.year,
    required this.sem,
    required this.stream,
    required this.prerequisites,
    this.grade = 'None',
  });

  String get key => '$code|$year|$sem|$stream';

  bool get isPassFailOnly => ch == 0;

  Course copyWith({String? grade}) {
    return Course(
      code: code,
      name: name,
      ch: ch,
      year: year,
      sem: sem,
      stream: stream,
      prerequisites: List<String>.from(prerequisites),
      grade: grade ?? this.grade,
    );
  }

  static Course cloneOf(Course template, {String? grade}) {
    return Course(
      code: template.code,
      name: template.name,
      ch: template.ch,
      year: template.year,
      sem: template.sem,
      stream: template.stream,
      prerequisites: List<String>.from(template.prerequisites),
      grade: grade ?? template.grade,
    );
  }
}

/// AASTU grading scale (Handbook 2023/2024, §2.14).
const Map<String, double> gradingScale = {
  'A+': 4.0,
  'A': 4.0,
  'A-': 3.75,
  'B+': 3.5,
  'B': 3.0,
  'B-': 2.75,
  'C+': 2.5,
  'C': 2.0,
  'C-': 1.75,
  'D': 1.0,
  'F': 0.0,
  'INC': 0.0,
  'None': 0.0,
};

const selectableGrades = [
  'A+',
  'A',
  'A-',
  'B+',
  'B',
  'B-',
  'C+',
  'C',
  'C-',
  'D',
  'F',
  'INC',
];

List<Course> cloneCourses(List<Course> templates) =>
    templates.map((c) => Course.cloneOf(c)).toList();
