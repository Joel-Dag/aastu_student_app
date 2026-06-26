class ManualPlanState {
  final bool active;
  final int clearFromYear;
  final int clearFromSem;
  final Map<String, List<String>> slotCourseKeys;

  const ManualPlanState({
    this.active = false,
    this.clearFromYear = 5,
    this.clearFromSem = 2,
    this.slotCourseKeys = const {},
  });

  static String slotKey(int year, int sem) => '$year|$sem';

  List<String> keysFor(int year, int sem) =>
      List.unmodifiable(slotCourseKeys[slotKey(year, sem)] ?? const []);

  ManualPlanState copyWith({
    bool? active,
    int? clearFromYear,
    int? clearFromSem,
    Map<String, List<String>>? slotCourseKeys,
  }) {
    return ManualPlanState(
      active: active ?? this.active,
      clearFromYear: clearFromYear ?? this.clearFromYear,
      clearFromSem: clearFromSem ?? this.clearFromSem,
      slotCourseKeys: slotCourseKeys ?? this.slotCourseKeys,
    );
  }

  Map<String, dynamic> toJson() => {
        'active': active,
        'clearFromYear': clearFromYear,
        'clearFromSem': clearFromSem,
        'slots': slotCourseKeys,
      };

  factory ManualPlanState.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as Map<String, dynamic>? ?? {};
    return ManualPlanState(
      active: json['active'] as bool? ?? false,
      clearFromYear: json['clearFromYear'] as int? ?? 5,
      clearFromSem: json['clearFromSem'] as int? ?? 2,
      slotCourseKeys: rawSlots.map(
        (k, v) => MapEntry(k, List<String>.from(v as List<dynamic>)),
      ),
    );
  }
}
