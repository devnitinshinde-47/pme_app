import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/services/device_id_service.dart';
import '../models/user_model.dart';

/// Remote data source calling Java Spring Boot Auth REST APIs.
class AuthRemoteDataSource {
  final ApiClient _apiClient;
  final DeviceIdService _deviceIdService;

  AuthRemoteDataSource({ApiClient? apiClient, DeviceIdService? deviceIdService})
      : _apiClient = apiClient ?? ApiClient(),
        _deviceIdService = deviceIdService ?? DeviceIdService();

  /// Send 6-digit OTP request to Java Spring Boot student portal
  /// API Contract: POST /api/auth/send-otp
  /// Body: {"mobileNo": "9876543210"}
  Future<SendOtpResponse> sendOtp(String mobileNo) async {
    final responseJson = await _apiClient.post(
      endpoint: ApiConstants.sendOtp,
      body: {'mobileNo': mobileNo},
    );
    return SendOtpResponse.fromJson(responseJson);
  }

  /// Verify 6-digit OTP request to Java Spring Boot student portal
  /// API Contract: POST /api/auth/verify-otp
  /// Body: {"mobileNo": "9876543210", "otp": "123456", "deviceId": "device_fingerprint"}
  Future<VerifyOtpResponse> verifyOtp(String mobileNo, String otp) async {
    try {
      // Get device ID for single device login enforcement
      final deviceId = await _deviceIdService.getDeviceId();
      
      final responseJson = await _apiClient.post(
        endpoint: ApiConstants.verifyOtp,
        body: {
          'mobileNo': mobileNo,
          'otp': otp,
          'deviceId': deviceId,
        },
      );
      return VerifyOtpResponse.fromJson(responseJson);
    } on ApiException catch (e) {
      // The current API reports an invalid OTP with a non-standard error
      // status. A status code means the verification request reached the API;
      // only connection failures (which have no status) keep their retry text.
      if (e.statusCode != null) {
        throw const ApiException('Incorrect OTP. Please try again.');
      }
      rethrow;
    }
  }

  /// Refresh JWT access token using refresh token
  /// API Contract: POST /api/auth/refresh-token
  /// Body: {"token": "refresh_token_string"}
  Future<RefreshTokenResponse> refreshToken(String refreshToken) async {
    final responseJson = await _apiClient.post(
      endpoint: ApiConstants.refreshToken,
      body: {'token': refreshToken},
    );
    return RefreshTokenResponse.fromJson(responseJson);
  }

  /// Revoke refresh token (logout)
  /// API Contract: POST /api/auth/logout
  /// Body: {"token": "refresh_token_string"}
  Future<SendOtpResponse> logout(String refreshToken) async {
    final responseJson = await _apiClient.post(
      endpoint: ApiConstants.logout,
      body: {'token': refreshToken},
    );
    return SendOtpResponse.fromJson(responseJson);
  }

  /// Update student profile name
  /// API Contract: PUT /api/users/profile
  /// Body: {"name": "New Student Name"}
  Future<UserModel> updateProfileName(String newName, String token) async {
    final responseJson = await _apiClient.put(
      customBaseUrl: '${ApiConstants.apiBaseUrl}/users',
      endpoint: '/profile',
      body: {'name': newName},
      token: token,
    );
    return UserModel.fromJson(Map<String, dynamic>.from(responseJson));
  }
}
