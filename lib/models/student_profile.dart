class StudentProfile {
  final String name;
  final String department;
  final int currentYear;
  final String? currentStream;
  /// Stream chosen for Year 4+ preview when student is still in Year 1–3.
  final String? plannedStream;

  const StudentProfile({
    required this.name,
    required this.department,
    required this.currentYear,
    this.currentStream,
    this.plannedStream,
  });

  bool get needsStream => currentYear >= 4;

  /// Stream used for Year 4+ course lists (current or planned specialization).
  String effectiveStream([String fallback = 'Computer']) =>
      currentStream ?? plannedStream ?? fallback;

  Map<String, dynamic> toJson() => {
        'name': name,
        'department': department,
        'currentYear': currentYear,
        'currentStream': currentStream,
        'plannedStream': plannedStream,
      };

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      name: json['name'] as String,
      department: json['department'] as String,
      currentYear: json['currentYear'] as int,
      currentStream: json['currentStream'] as String?,
      plannedStream: json['plannedStream'] as String?,
    );
  }

  StudentProfile copyWith({
    String? name,
    String? department,
    int? currentYear,
    String? currentStream,
    String? plannedStream,
  }) {
    return StudentProfile(
      name: name ?? this.name,
      department: department ?? this.department,
      currentYear: currentYear ?? this.currentYear,
      currentStream: currentStream ?? this.currentStream,
      plannedStream: plannedStream ?? this.plannedStream,
    );
  }
}

const eceStreams = [
  'Computer',
  'Communication',
  'Control',
  'Electronics',
  'Power',
];

const departments = [
  'Electrical & Computer Engineering',
  'Civil Engineering',
  'Mechanical Engineering',
  'Software Engineering',
  'ElectroMechanical Engineering',
  'Environmental Engineering',
  'Mining Engineering',
  'Chemical Engineering',
];

const comingSoonDepartments = {
  'Civil Engineering',
  'Mechanical Engineering',
  'Software Engineering',
  'ElectroMechanical Engineering',
  'Environmental Engineering',
  'Mining Engineering',
  'Chemical Engineering',
};
