import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Local session data source managing SharedPreferences for JWT, Refresh Tokens, and course request states.
class AuthLocalDataSource {
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserData = 'auth_user_data';
  static const String _keyRequestedCourseIds = 'requested_course_ids';
  static const String _keyEnrolledCourseIds = 'enrolled_course_ids';

  /// Save authentication session tokens & user object
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
  }

  /// Get stored JWT access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  /// Get stored user model
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonStr = prefs.getString(_keyUserData);
    if (userJsonStr == null || userJsonStr.isEmpty) return null;
    try {
      final userMap = jsonDecode(userJsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(userMap);
    } catch (_) {
      return null;
    }
  }

  /// Update stored JWT access token
  Future<void> updateAccessToken(String newAccessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, newAccessToken);
  }

  /// Get set of requested course IDs
  Future<Set<String>> getRequestedCourseIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyRequestedCourseIds) ?? [];
    return list.toSet();
  }

  /// Set / override all requested course IDs (sync with server)
  Future<void> setRequestedCourseIds(List<String> courseIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyRequestedCourseIds, courseIds);
  }

  /// Add a course ID to requested list
  Future<void> addRequestedCourseId(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_keyRequestedCourseIds) ?? []).toSet();
    current.add(courseId);
    await prefs.setStringList(_keyRequestedCourseIds, current.toList());
  }

  /// Remove a course ID from requested list
  Future<void> removeRequestedCourseId(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_keyRequestedCourseIds) ?? []).toSet();
    current.remove(courseId);
    await prefs.setStringList(_keyRequestedCourseIds, current.toList());
  }

  /// Get set of granted/enrolled course IDs
  Future<Set<String>> getEnrolledCourseIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyEnrolledCourseIds) ?? [];
    return list.toSet();
  }

  /// Set / override all enrolled course IDs
  Future<void> setEnrolledCourseIds(List<String> courseIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyEnrolledCourseIds, courseIds);
  }

  /// Add a course ID to enrolled list (when admin grants access)
  Future<void> addEnrolledCourseId(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_keyEnrolledCourseIds) ?? []).toSet();
    current.add(courseId);
    await prefs.setStringList(_keyEnrolledCourseIds, current.toList());
  }

  /// Remove a course ID from enrolled list
  Future<void> removeEnrolledCourseId(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_keyEnrolledCourseIds) ?? []).toSet();
    current.remove(courseId);
    await prefs.setStringList(_keyEnrolledCourseIds, current.toList());
  }

  /// Clear session (Logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyRequestedCourseIds);
    await prefs.remove(_keyEnrolledCourseIds);
  }
}
