import 'package:flutter/material.dart';

import '../models/course.dart';
import '../theme/app_theme.dart';

class GradeDropdown extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const GradeDropdown({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  Color _gradeColor(String grade) {
    if (grade == 'F') return AppColors.danger;
    if (grade == 'INC') return AppColors.warning;
    if (grade == 'None') return Colors.white38;
    if (grade.startsWith('A')) return AppColors.success;
    if (grade.startsWith('B')) return AppColors.aastuGoldLight;
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.aastuBlueDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.aastuGold.withValues(alpha: 0.3)),
      ),
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.cardDark,
        icon: Icon(
          Icons.arrow_drop_down_rounded,
          color: enabled ? AppColors.aastuGold : Colors.white24,
        ),
        items: [
          const DropdownMenuItem(value: 'None', child: Text('—', style: TextStyle(color: Colors.white38))),
          ...selectableGrades.map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(
                g == 'INC' ? 'Incomplete' : g,
                style: TextStyle(
                  color: _gradeColor(g),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        onChanged: enabled ? (v) { if (v != null) onChanged(v); } : null,
      ),
    );
  }
}
