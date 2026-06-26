import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/manual_plan_state.dart';
import '../services/manual_plan_service.dart';
import '../theme/app_theme.dart';

Future<void> showAddCourseSheet({
  required BuildContext context,
  required List<Course> allCourses,
  required String stream,
  required int targetYear,
  required int targetSem,
  required ManualPlanState plan,
  required Set<String> failures,
  required ValueChanged<Course> onCourseSelected,
}) {
  final planner = ManualPlanService.instance;
  final groups = planner.buildPickerGroups(
    allCourses: allCourses,
    stream: stream,
    targetYear: targetYear,
    targetSem: targetSem,
    plan: plan,
    failures: failures,
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_circle_outline,
                            color: AppColors.aastuGold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add Course — Year $targetYear Sem $targetSem',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Semester $targetSem courses only. Failed courses can be added for retake. '
                      'Courses blocked by uncleared failed prerequisites are grayed out.',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: groups.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No remaining courses for this semester slot.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: groups.length,
                        itemBuilder: (context, gi) {
                          final group = groups[gi];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 8),
                                child: Text(
                                  'Year ${group.year} • Semester ${group.sem}',
                                  style: const TextStyle(
                                    color: AppColors.aastuGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              ...group.courses.map((item) {
                                final c = item.course;
                                final ch = c.ch == 0 ? 'P/F' : '${c.ch} CH';
                                return Opacity(
                                  opacity: item.selectable ? 1 : 0.45,
                                  child: ListTile(
                                    enabled: item.selectable,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      c.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: item.selectable
                                            ? Colors.white
                                            : Colors.white54,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${c.code} • $ch',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          planner.prereqLabel(c, allCourses),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: item.selectable
                                                ? Colors.white38
                                                : AppColors.warning,
                                          ),
                                        ),
                                        if (item.blockReason != null)
                                          Text(
                                            item.blockReason!,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        if (c.grade == 'F')
                                          const Text(
                                            'Failed — retake',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.aastuBlueLight,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: item.selectable
                                        ? const Icon(Icons.add,
                                            color: AppColors.aastuGold)
                                        : const Icon(Icons.block,
                                            color: Colors.white24),
                                    onTap: item.selectable
                                        ? () {
                                            Navigator.pop(ctx);
                                            onCourseSelected(c);
                                          }
                                        : null,
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}
