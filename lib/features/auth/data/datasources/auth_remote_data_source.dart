import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/user_model.dart';

/// Remote data source calling Java Spring Boot Auth REST APIs.
class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Send 6-digit OTP request to Java Spring Boot backend
  /// API Contract: POST /api/v1/auth/send-otp
  /// Body: {"mobileNumber": "9876543210"}
  Future<SendOtpResponse> sendOtp(String mobileNumber) async {
    final responseJson = await _apiClient.post(
      endpoint: ApiConstants.sendOtp,
      body: {'mobileNumber': mobileNumber},
    );
    return SendOtpResponse.fromJson(responseJson);
  }

  /// Verify 6-digit OTP request to Java Spring Boot backend
  /// API Contract: POST /api/v1/auth/verify-otp
  /// Body: {"mobileNumber": "9876543210", "otp": "123456"}
  Future<AuthResponse> verifyOtp(String mobileNumber, String otp) async {
    final responseJson = await _apiClient.post(
      endpoint: ApiConstants.verifyOtp,
      body: {
        'mobileNumber': mobileNumber,
        'otp': otp,
      },
    );
    return AuthResponse.fromJson(responseJson);
  }
}
