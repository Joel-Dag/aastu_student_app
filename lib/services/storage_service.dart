import 'dart:convert';



import 'package:shared_preferences/shared_preferences.dart';



import '../models/student_profile.dart';

import '../models/manual_plan_state.dart';



class StorageService {

  StorageService._();

  static final StorageService instance = StorageService._();



  static const _profileKey = 'student_profile';

  static const _gradesKey = 'course_grades';

  static const _lockedKey = 'data_locked';

  static const _lockedSlotsKey = 'locked_semesters';

  static const _onboardedKey = 'has_onboarded';

  static const _planAppliedKey = 'plan_applied';

  static const _manualPlanKey = 'manual_plan_state';



  static String slotKey(int year, int sem) => '$year|$sem';



  Future<bool> hasOnboarded() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_onboardedKey) ?? false;

  }



  Future<void> saveProfile(StudentProfile profile) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));

    await prefs.setBool(_onboardedKey, true);

  }



  Future<StudentProfile?> loadProfile() async {

    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_profileKey);

    if (raw == null) return null;

    return StudentProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  }



  Future<void> saveGrades(Map<String, String> grades) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_gradesKey, jsonEncode(grades));

  }



  Future<Map<String, String>> loadGrades() async {

    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_gradesKey);

    if (raw == null) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    return decoded.map((k, v) => MapEntry(k, v as String));

  }



  /// Legacy global lock — migrated to per-semester locks on first read.

  Future<bool> isLocked() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_lockedKey) ?? false;

  }



  Future<void> setLocked(bool locked) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_lockedKey, locked);

  }



  Future<Set<String>> loadLockedSlots() async {

    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_lockedSlotsKey);

    if (raw != null) {

      final list = jsonDecode(raw) as List<dynamic>;

      return list.map((e) => e as String).toSet();

    }



    // Migrate legacy global lock flag.

    if (prefs.getBool(_lockedKey) ?? false) {

      return {'legacy'};

    }

    return {};

  }



  Future<void> saveLockedSlots(Set<String> slots) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_lockedSlotsKey, jsonEncode(slots.toList()));

    await prefs.setBool(_lockedKey, slots.isNotEmpty);

  }



  Future<bool> isPlanApplied() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_planAppliedKey) ?? false;

  }



  Future<void> setPlanApplied(bool applied) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_planAppliedKey, applied);

  }



  Future<void> saveManualPlan(ManualPlanState plan) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_manualPlanKey, jsonEncode(plan.toJson()));

  }



  Future<ManualPlanState> loadManualPlan() async {

    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_manualPlanKey);

    if (raw == null) return const ManualPlanState();

    return ManualPlanState.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  }



  Future<void> clearAll() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

  }

}

