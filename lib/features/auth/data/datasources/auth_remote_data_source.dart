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

  /// Send 6-digit OTP request to Java Spring Boot student portal.
  /// Now passes deviceId so the backend can block sending if the account
  /// is already locked to a different device.
  ///
  /// API Contract: POST /api/auth/send-otp
  /// Body: {"mobileNo": "9876543210", "deviceId": "device_fingerprint"}
  ///
  /// Throws [DeviceLockedApiException] (errorCode == "DEVICE_LOCKED") when
  /// the account is bound to another device. All other API errors are rethrown
  /// as [ApiException] with the real server message — NOT masked as "Incorrect OTP".
  Future<SendOtpResponse> sendOtp(String mobileNo) async {
    final deviceId = await _deviceIdService.getDeviceId();
    try {
      final responseJson = await _apiClient.post(
        endpoint: ApiConstants.sendOtp,
        body: {
          'mobileNo': mobileNo,
          'deviceId': deviceId,
        },
      );
      return SendOtpResponse.fromJson(responseJson);
    } on ApiException catch (e) {
      // Promote device-locked errors to a typed exception so the UI
      // can show the dedicated "Device Locked" dialog.
      if (e.errorCode == 'DEVICE_LOCKED') {
        throw DeviceLockedApiException(e.message, userId: e.userId);
      }
      rethrow;
    }
  }

  /// Verify 6-digit OTP request to Java Spring Boot student portal
  /// API Contract: POST /api/auth/verify-otp
  /// Body: {"mobileNo": "9876543210", "otp": "123456", "deviceId": "device_fingerprint"}
  ///
  /// Throws [DeviceLockedApiException] when device mismatch with no approved change request.
  /// Throws [ApiException] with the real server message for all other errors.
  Future<VerifyOtpResponse> verifyOtp(String mobileNo, String otp) async {
    final deviceId = await _deviceIdService.getDeviceId();
    try {
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
      if (e.errorCode == 'DEVICE_LOCKED') {
        throw DeviceLockedApiException(e.message, userId: e.userId);
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

  /// Submit a device change request on behalf of the student.
  /// API Contract: POST /api/auth/device-change-requests
  /// Body: {"userId": "uuid", "newDeviceId": "device_fingerprint"}
  Future<SendOtpResponse> submitDeviceChangeRequest(String userId) async {
    final deviceId = await _deviceIdService.getDeviceId();
    final responseJson = await _apiClient.post(
      endpoint: '/device-change-requests',
      body: {
        'userId': userId,
        'newDeviceId': deviceId,
      },
    );
    return SendOtpResponse.fromJson(responseJson);
  }
}

/// Thrown specifically when the backend returns errorCode == "DEVICE_LOCKED".
/// Carries [userId] so the UI can immediately submit a device change request
/// without a separate user-lookup API call.
class DeviceLockedApiException implements Exception {
  final String message;
  final String? userId;

  const DeviceLockedApiException(this.message, {this.userId});

  @override
  String toString() => message;
}
