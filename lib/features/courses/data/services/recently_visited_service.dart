import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';

/// Local service tracking recently visited courses for student quick re-access on Home Screen.
class RecentlyVisitedService {
  static const String _storageKey = 'pme_recently_visited_courses_v1';
  static final List<CourseModel> _cache = [];
  static bool _hasLoadedFromStorage = false;

  /// ValueNotifier triggered whenever a new course visit is recorded
  static final ValueNotifier<int> revisionNotifier = ValueNotifier<int>(0);

  /// Records a course as visited and persists it locally.
  static Future<void> addCourse(CourseModel course) async {
    if (course.id.isEmpty) return;

    await _ensureLoaded();

    _cache.removeWhere((c) => c.id == course.id);
    _cache.insert(0, course);

    // Maintain max 10 recently visited items
    if (_cache.length > 10) {
      _cache.removeLast();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _cache.map((c) => jsonEncode(c.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (_) {}

    // Notify listeners dynamically for instant UI update
    revisionNotifier.value++;
  }

  /// Retrieves the list of recently visited courses.
  static Future<List<CourseModel>> getRecentlyVisitedCourses() async {
    await _ensureLoaded();
    return List.unmodifiable(_cache);
  }

  static Future<void> _ensureLoaded() async {
    if (_hasLoadedFromStorage) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      if (jsonList.isNotEmpty) {
        _cache.clear();
        for (final item in jsonList) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            _cache.add(CourseModel.fromJson(map));
          } catch (_) {}
        }
      }
    } catch (_) {}

    _hasLoadedFromStorage = true;
  }
}
