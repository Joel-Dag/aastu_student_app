import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/student_profile.dart';
import '../theme/app_theme.dart';
import 'grade_dropdown.dart';

class SemesterTableCard extends StatelessWidget {
  final int year;
  final int sem;
  final List<Course> courses;
  final bool locked;
  final bool isPreview;
  final String? selectedStream;
  final ValueChanged<String>? onStreamChanged;
  final void Function(Course course, String grade) onGradeChanged;

  const SemesterTableCard({
    super.key,
    required this.year,
    required this.sem,
    required this.courses,
    required this.locked,
    required this.onGradeChanged,
    this.isPreview = false,
    this.selectedStream,
    this.onStreamChanged,
  });

  bool get _showStreamPicker =>
      year == 4 && sem == 2 && onStreamChanged != null;

  @override
  Widget build(BuildContext context) {
    var semGp = 0.0;
    var semCh = 0;
    var hasInc = false;
    final passedCodes = courses
        .where((c) => c.grade != 'None' && c.grade != 'INC' && c.grade != 'F')
        .map((c) => c.code)
        .toSet();

    for (final c in courses) {
      if (c.grade == 'INC') hasInc = true;
      if (c.grade == 'None' || c.grade == 'INC' || c.ch == 0) continue;
      if (c.grade == 'F' && passedCodes.contains(c.code)) continue;
      semCh += c.ch;
      semGp += gradingScale[c.grade]! * c.ch;
    }
    final sgpa = semCh > 0 ? semGp / semCh : (hasInc ? 0.0 : null);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.aastuGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Y$year • S$sem',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.aastuGold,
                        ),
                      ),
                    ),
                    if (isPreview) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Upcoming',
                          style: TextStyle(fontSize: 10, color: Colors.white60),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (sgpa != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SGPA ${sgpa.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$semCh CH',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_showStreamPicker) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.account_tree_outlined, color: AppColors.aastuGold, size: 18),
                      const SizedBox(width: 8),
                      const Text('Stream:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.aastuBlueDark.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.aastuGold.withValues(alpha: 0.3)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedStream ?? eceStreams.first,
                              isExpanded: true,
                              isDense: true,
                              dropdownColor: AppColors.cardDark,
                              items: eceStreams
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text('$s Engineering', style: const TextStyle(fontSize: 12)),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) onStreamChanged!(v);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (courses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No courses for this semester.', textAlign: TextAlign.center),
            )
          else
            ...courses.map((course) => _CourseRow(
                  course: course,
                  locked: locked || isPreview,
                  onGradeChanged: (g) => onGradeChanged(course, g),
                )),
        ],
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final Course course;
  final bool locked;
  final ValueChanged<String> onGradeChanged;

  const _CourseRow({
    required this.course,
    required this.locked,
    required this.onGradeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chLabel = course.ch == 0 ? 'P/F' : '${course.ch} CH';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${course.code} • $chLabel',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          GradeDropdown(
            value: course.grade,
            enabled: !locked,
            onChanged: onGradeChanged,
          ),
        ],
      ),
    );
  }
}
