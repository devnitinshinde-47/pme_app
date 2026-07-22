/// Java Spring Boot backend API endpoint constants and configurations.
abstract class ApiConstants {
  /// Base URL for the Spring Boot backend server.
  /// Replace with your actual server IP/domain (e.g. http://10.0.2.2:8080/api/v1 for Android Emulator or live domain).
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  // Auth Endpoints (Java Spring Boot REST Controller)
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh-token';

  // Headers
  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
