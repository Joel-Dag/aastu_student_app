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
  final bool manualPlanMode;
  final int? minCredits;
  final int? maxCredits;
  final String? selectedStream;
  final ValueChanged<String>? onStreamChanged;
  final void Function(Course course, String grade) onGradeChanged;
  final VoidCallback? onAddCourse;
  final void Function(Course course)? onRemoveCourse;
  final VoidCallback? onFinishSemester;

  const SemesterTableCard({
    super.key,
    required this.year,
    required this.sem,
    required this.courses,
    required this.locked,
    required this.onGradeChanged,
    this.isPreview = false,
    this.manualPlanMode = false,
    this.minCredits,
    this.maxCredits,
    this.selectedStream,
    this.onStreamChanged,
    this.onAddCourse,
    this.onRemoveCourse,
    this.onFinishSemester,
  });

  bool get _showStreamPicker =>
      year == 4 && sem == 2 && onStreamChanged != null;

  @override
  Widget build(BuildContext context) {
    var semGp = 0.0;
    var gradedCh = 0;
    var hasInc = false;
    final totalCh = courses.where((c) => c.ch > 0).fold<int>(0, (sum, c) => sum + c.ch);
    final passedCodes = courses
        .where((c) => c.grade != 'None' && c.grade != 'INC' && c.grade != 'F')
        .map((c) => c.code)
        .toSet();

    for (final c in courses) {
      if (c.grade == 'INC') hasInc = true;
      if (c.grade == 'None' || c.grade == 'INC' || c.ch == 0) continue;
      if (c.grade == 'F' && passedCodes.contains(c.code)) continue;
      gradedCh += c.ch;
      semGp += gradingScale[c.grade]! * c.ch;
    }
    final sgpa = gradedCh > 0 ? semGp / gradedCh : (hasInc ? 0.0 : null);

    final showCreditRules = manualPlanMode && minCredits != null && maxCredits != null;
    final creditStatus = showCreditRules
        ? _creditStatus(totalCh, minCredits!, maxCredits!)
        : _CreditStatus.ok;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isPreview && !manualPlanMode ? null : AppTheme.heroGradient,
              color: isPreview && !manualPlanMode
                  ? AppColors.aastuBlueDark.withValues(alpha: 0.6)
                  : null,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
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
                    if (manualPlanMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.aastuGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Your Plan',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.aastuGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else if (isPreview) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                    if (onFinishSemester != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton.icon(
                          onPressed: onFinishSemester,
                          icon: const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                          label: const Text('Finished', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    if (manualPlanMode || sgpa != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (sgpa != null)
                            Text(
                              'SGPA ${sgpa.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          Text(
                            '$totalCh CH',
                            style: TextStyle(
                              color: creditStatus == _CreditStatus.ok
                                  ? Colors.white70
                                  : AppColors.warning,
                              fontSize: 11,
                              fontWeight: creditStatus != _CreditStatus.ok
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (showCreditRules) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Limit: $minCredits–$maxCredits CH',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  if (creditStatus != _CreditStatus.ok)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        creditStatus == _CreditStatus.belowMin
                            ? 'Below minimum ($minCredits CH required)'
                            : 'Above maximum ($maxCredits CH limit)',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
                if (_showStreamPicker) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.account_tree_outlined,
                          color: AppColors.aastuGold, size: 18),
                      const SizedBox(width: 8),
                      const Text('Stream:',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                AppColors.aastuBlueDark.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.aastuGold.withValues(alpha: 0.3),
                            ),
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
                                        child: Text('$s Engineering',
                                            style:
                                                const TextStyle(fontSize: 12)),
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    manualPlanMode
                        ? 'No courses planned for this semester yet.'
                        : 'No courses for this semester.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  if (manualPlanMode && onAddCourse != null && !locked) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: onAddCourse,
                      icon: const Icon(Icons.add, color: AppColors.aastuGold),
                      label: const Text('Add Course'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.aastuGold,
                        side: BorderSide(
                          color: AppColors.aastuGold.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            ...courses.map((course) => _CourseRow(
                  course: course,
                  locked: locked || (isPreview && !manualPlanMode),
                  showRemove: manualPlanMode && !locked && onRemoveCourse != null,
                  onRemove: onRemoveCourse != null
                      ? () => onRemoveCourse!(course)
                      : null,
                  onGradeChanged: (g) => onGradeChanged(course, g),
                )),
          if (manualPlanMode && courses.isNotEmpty && onAddCourse != null && !locked)
            Padding(
              padding: const EdgeInsets.all(12),
              child: OutlinedButton.icon(
                onPressed: onAddCourse,
                icon: const Icon(Icons.add, size: 18, color: AppColors.aastuGold),
                label: const Text('Add Course'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.aastuGold,
                  side: BorderSide(
                    color: AppColors.aastuGold.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  _CreditStatus _creditStatus(int ch, int min, int max) {
    if (ch < min) return _CreditStatus.belowMin;
    if (ch > max) return _CreditStatus.aboveMax;
    return _CreditStatus.ok;
  }
}

enum _CreditStatus { ok, belowMin, aboveMax }

class _CourseRow extends StatelessWidget {
  final Course course;
  final bool locked;
  final bool showRemove;
  final VoidCallback? onRemove;
  final ValueChanged<String> onGradeChanged;

  const _CourseRow({
    required this.course,
    required this.locked,
    required this.onGradeChanged,
    this.showRemove = false,
    this.onRemove,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${course.code} • $chLabel',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                if (course.grade == 'F')
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Retake',
                      style: TextStyle(
                        color: AppColors.aastuBlueLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showRemove)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.warning, size: 20),
              tooltip: 'Remove from plan',
              onPressed: onRemove,
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
