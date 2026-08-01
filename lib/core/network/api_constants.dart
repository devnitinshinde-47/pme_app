/// Java Spring Boot backend API endpoint constants and configurations.
abstract class ApiConstants {
  /// Base API URL for the Spring Boot backend server (/api) deployed on the VPS.
  static String get apiBaseUrl => 'https://api.pawanmateeducation.tech/api';

  static String get authBaseUrl => '$apiBaseUrl/auth';
  static String get coursesBaseUrl => '$apiBaseUrl/courses';
  static String get progressBaseUrl => '$apiBaseUrl/progress';
  static String get notificationsBaseUrl => '$apiBaseUrl/notifications';

  // Legacy compatibility getter
  static String get baseUrl => authBaseUrl;

  // Student Auth Endpoints
  static const String sendOtp = '/send-otp';
  static const String verifyOtp = '/verify-otp';
  static const String refreshToken = '/refresh-token';
  static const String logout = '/logout';

  // Course Endpoints (/api/courses)
  static const String courses = '';
  static const String courseSettings = '/settings';

  // Headers
  static Map<String, String> headers({String? token, String? deviceId}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (deviceId != null && deviceId.isNotEmpty) 'X-Device-Id': deviceId,
    };
  }
}
