import '../models/course.dart';

/// Freshman (Year 1) common courses shared across all undergraduate programs.
///
/// Sourced from AASTU Student Handbook 2023/2024, section 3.5.5
/// (Electrical and Computer Engineering — First Year semester breakdown).
List<Course> getFreshmanCourses() {
  return [
    // --- Year 1, Semester 1 (18 credit hours) ---
    Course(
      code: 'Phil1009',
      name: 'Logic and Critical Thinking',
      ch: 3,
      year: 1,
      sem: 1,
      stream: 'Common',
      prerequisites: [],
    ),
    Course(
      code: 'Psyc1011',
      name: 'General Psychology',
      ch: 3,
      year: 1,
      sem: 1,
      stream: 'Common',
      prerequisites: [],
    ),
    Course(
      code: 'FLEn1003',
      name: 'Communicative English Language Skills I',
      ch: 3,
      year: 1,
      sem: 1,
      stream: 'Common',
      prerequisites: [],
    ),
    Course(
      code: 'GeES1005',
      name: 'Geography of Ethiopia and the Horn',
      ch: 3,
      year: 1,
      sem: 1,
      stream: 'Common',
      prerequisites: [],
    ),
    Course(
      code: 'Math1007',
      name: 'Mathematics for Natural Science',
      ch: 3,
      year: 1,
      sem: 1,
      stream: 'Common',
      prerequisites: [],
    ),
    Course(
      code: 'SpSc1013',
      name: 'Physical Fitness',
      ch: 0,
      year: 1,
      sem: 1,
      stream: 'Common',
      prerequisites: [],
    ),
    Course(
      code: 'Phys1001',
      name: 'General Physics',
      ch: 3,
      year: 1,
      sem: 1,
      stream: 'Common',
      prerequisites: [],
    ),

    // --- Year 1, Semester 2 (19 credit hours) ---
    Course(
      code: 'EmT1008',
      name: 'Introduction to Emerging Technology',
      ch: 3,
      year: 1,
      sem: 2,
      stream: 'Common',
      prerequisites: [],
    ),
    Course(
      code: 'FLEn1004',
      name: 'Communicative English Language Skills II',
      ch: 3,
      year: 1,
      sem: 2,
      stream: 'Common',
      prerequisites: ['FLEn1003'],
    ),
    Course(
      code: 'Math1014',
      name: 'Applied Mathematics IB',
      ch: 4,
      year: 1,
      sem: 2,
      stream: 'Common',
      prerequisites: [],
    ),
    Course(
      code: 'MCiE1012',
      name: 'Moral and Civic Education',
      ch: 2,
      year: 1,
      sem: 2,
      stream: 'Common',
      prerequisites: [],
    ),
    Course(
      code: 'Incl1010',
      name: 'Inclusiveness',
      ch: 2,
      year: 1,
      sem: 2,
      stream: 'Common',
      prerequisites: [],
    ),
    Course(
      code: 'Anth1002',
      name: 'Social Anthropology',
      ch: 2,
      year: 1,
      sem: 2,
      stream: 'Common',
      prerequisites: [],
    ),
    Course(
      code: 'Entr1006',
      name: 'Entrepreneurship',
      ch: 3,
      year: 1,
      sem: 2,
      stream: 'Common',
      prerequisites: [],
    ),
  ];
}
