import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class IncompleteWarningBanner extends StatelessWidget {
  final int incompleteCount;

  const IncompleteWarningBanner({super.key, required this.incompleteCount});

  @override
  Widget build(BuildContext context) {
    if (incompleteCount <= 0) return const SizedBox.shrink();

    final label = incompleteCount == 1
        ? '1 course marked Incomplete'
        : '$incompleteCount courses marked Incomplete';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Remember to clear incomplete grades — they count as 0.0 until resolved.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
