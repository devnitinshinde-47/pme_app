import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

/// Repository managing authentication flow with Spring Boot REST API integration & fallback simulation.
class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  bool useMockFallback;

  AuthRepository({
    AuthRemoteDataSource? remoteDataSource,
    this.useMockFallback = true,
  }) : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource();

  /// Send 6-digit OTP to mobile number
  Future<SendOtpResponse> sendOtp(String mobileNumber) async {
    try {
      if (!useMockFallback) {
        return await _remoteDataSource.sendOtp(mobileNumber);
      }
      return await _mockSendOtp(mobileNumber);
    } catch (e) {
      if (e is ApiException && useMockFallback) {
        debugPrint('Spring Boot backend unavailable, using mock OTP mode: $e');
        return await _mockSendOtp(mobileNumber);
      }
      rethrow;
    }
  }

  /// Verify 6-digit OTP
  Future<AuthResponse> verifyOtp(String mobileNumber, String otp) async {
    try {
      if (!useMockFallback) {
        return await _remoteDataSource.verifyOtp(mobileNumber, otp);
      }
      return await _mockVerifyOtp(mobileNumber, otp);
    } catch (e) {
      if (e is ApiException && useMockFallback) {
        debugPrint('Spring Boot backend unavailable, using mock verify mode: $e');
        return await _mockVerifyOtp(mobileNumber, otp);
      }
      rethrow;
    }
  }

  Future<SendOtpResponse> _mockSendOtp(String mobileNumber) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return SendOtpResponse(
      success: true,
      message: 'OTP sent successfully to +91 $mobileNumber',
      txnId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<AuthResponse> _mockVerifyOtp(String mobileNumber, String otp) async {
    await Future.delayed(const Duration(milliseconds: 1400));
    // Verify 6 digit OTP (accept any valid 6 digit or 123456)
    if (otp.length != 6) {
      throw const ApiException('Invalid 6-digit OTP code');
    }
    
    // Simulate lookup: new user if phone ends with odd digit, existing user if even
    final lastChar = mobileNumber.isNotEmpty ? mobileNumber[mobileNumber.length - 1] : '0';
    final lastDigit = int.tryParse(lastChar) ?? 0;
    final isNew = lastDigit % 2 != 0;

    final user = UserModel(
      id: 'STD_${DateTime.now().millisecondsSinceEpoch}',
      mobileNumber: mobileNumber,
      name: isNew ? 'New Student' : 'Pawan Mate Student',
      token: 'jwt_mock_token_${DateTime.now().millisecondsSinceEpoch}',
      isNewUser: isNew,
    );

    return AuthResponse(
      success: true,
      message: 'Login Successful',
      user: user,
    );
  }
}
