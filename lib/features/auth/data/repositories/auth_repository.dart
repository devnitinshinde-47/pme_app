import 'dart:async';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_manager.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../../../core/utils/app_cache_manager.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

/// Central repository managing student OTP authentication, token refresh, and persistent session state.
class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  bool useMockFallback;

  AuthRepository({
    AuthRemoteDataSource? remoteDataSource,
    AuthLocalDataSource? localDataSource,
    this.useMockFallback = false,
  })  : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource(),
        _localDataSource = localDataSource ?? AuthLocalDataSource();

  /// Send 6-digit OTP to mobile number
  Future<SendOtpResponse> sendOtp(String mobileNumber) async {
    try {
      final response = await _remoteDataSource.sendOtp(mobileNumber);
      return response;
    } catch (e) {
      if (e is ApiException && useMockFallback) {
        return await _mockSendOtp(mobileNumber);
      }
      rethrow;
    }
  }

  /// Verify 6-digit OTP code and persist returned JWT + refresh tokens
  Future<VerifyOtpResponse> verifyOtp(String mobileNumber, String otp) async {
    try {
      final verifyResponse = await _remoteDataSource.verifyOtp(mobileNumber, otp);

      if (verifyResponse.success &&
          verifyResponse.accessToken != null &&
          verifyResponse.refreshToken != null &&
          verifyResponse.user != null) {
        await _localDataSource.saveSession(
          accessToken: verifyResponse.accessToken!,
          refreshToken: verifyResponse.refreshToken!,
          user: verifyResponse.user!,
        );
        // Startup runs before a student has an access token. Register again
        // after login so this device receives course notifications.
        await FcmNotificationService.instance.initialize();
        await FcmNotificationService.instance.syncTokenWithBackend();
      }

      return verifyResponse;
    } catch (e) {
      if (e is ApiException && useMockFallback) {
        final mockResponse = await _mockVerifyOtp(mobileNumber, otp);
        if (mockResponse.accessToken != null &&
            mockResponse.refreshToken != null &&
            mockResponse.user != null) {
          await _localDataSource.saveSession(
            accessToken: mockResponse.accessToken!,
            refreshToken: mockResponse.refreshToken!,
            user: mockResponse.user!,
          );
        }
        return mockResponse;
      }
      rethrow;
    }
  }

  /// Returns the locally stored session immediately so launch is not blocked by
  /// an unreliable network request. Token refresh happens in the background;
  /// regular API calls continue to handle an invalid/expired session normally.
  Future<UserModel?> tryAutoLogin() async {
    final refreshToken = await _localDataSource.getRefreshToken();
    final savedUser = await _localDataSource.getUser();

    if (refreshToken == null || savedUser == null) {
      return null;
    }

    unawaited(_refreshAccessTokenInBackground());
    return savedUser;
  }

  Future<void> _refreshAccessTokenInBackground() async {
    try {
      await TokenManager.instance.refreshAccessToken();
    } catch (_) {
      // Offline launch is supported; retry/reauthentication is handled by API calls.
    }
  }

  /// Logout current user: revokes refresh token on backend and clears local storage & cache
  Future<void> logout() async {
    final refreshToken = await _localDataSource.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _remoteDataSource.logout(refreshToken);
      } catch (_) {}
    }
    await AppCacheManager.instance.clearOnLogout();
  }

  /// Get current stored user
  Future<UserModel?> getStoredUser() async {
    return await _localDataSource.getUser();
  }

  /// Update student profile name both on backend and local storage session
  Future<UserModel> updateProfileName(String newName) async {
    final token = await _localDataSource.getAccessToken();
    final currentUser = await _localDataSource.getUser();

    if (token != null && token.isNotEmpty) {
      try {
        final updatedServerUser = await _remoteDataSource.updateProfileName(newName, token);
        await _localDataSource.saveSession(
          accessToken: token,
          refreshToken: (await _localDataSource.getRefreshToken()) ?? '',
          user: updatedServerUser,
        );
        return updatedServerUser;
      } catch (_) {}
    }

    final localUpdatedUser = currentUser != null
        ? currentUser.copyWith(name: newName)
        : UserModel(id: 'std_local', mobileNumber: '', name: newName);

    await _localDataSource.saveSession(
      accessToken: token ?? '',
      refreshToken: (await _localDataSource.getRefreshToken()) ?? '',
      user: localUpdatedUser,
    );
    return localUpdatedUser;
  }

  /// Submit a device change request when the student is locked on a different device.
  /// [userId] comes from the DEVICE_LOCKED error response body.
  Future<SendOtpResponse> submitDeviceChangeRequest(String userId) async {
    return await _remoteDataSource.submitDeviceChangeRequest(userId);
  }

  // ─── Mock Fallbacks ─────────────────────────────────────────────────────────

  Future<SendOtpResponse> _mockSendOtp(String mobileNumber) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return SendOtpResponse(
      success: true,
      message: 'OTP sent successfully to $mobileNumber',
    );
  }

  Future<VerifyOtpResponse> _mockVerifyOtp(String mobileNumber, String otp) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (otp.length != 6) {
      throw const ApiException('Invalid 6-digit OTP code');
    }

    final lastChar = mobileNumber.isNotEmpty ? mobileNumber[mobileNumber.length - 1] : '0';
    final lastDigit = int.tryParse(lastChar) ?? 0;
    final isNew = lastDigit % 2 != 0;

    final user = UserModel(
      id: 'STD_${DateTime.now().millisecondsSinceEpoch}',
      mobileNumber: mobileNumber,
      name: isNew ? 'New Student' : 'Pawan Mate Student',
      role: 'STUDENT',
      isNewUser: isNew,
    );

    return VerifyOtpResponse(
      success: true,
      message: 'Login successful',
      accessToken: 'mock_jwt_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_jwt_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      user: user,
    );
  }
}
