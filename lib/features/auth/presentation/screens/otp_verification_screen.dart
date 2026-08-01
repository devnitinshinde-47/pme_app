import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/custom_button.dart';
import '../widgets/otp_input_field.dart';

/// Human-crafted 6-Digit OTP Verification Screen.
class OtpVerificationScreen extends StatefulWidget {
  final String mobileNumber;
  final AuthRepository? authRepository;

  const OtpVerificationScreen({
    super.key,
    required this.mobileNumber,
    this.authRepository,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> with CodeAutoFill {
  late final AuthRepository _authRepository;
  String _enteredOtp = '';
  String? _autoOtpCode;
  String? _otpError;
  bool _isLoading = false;
  bool _isResending = false;

  static const int _resendCooldownSeconds = 60;
  int _timerSeconds = _resendCooldownSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepository();
    _startResendTimer();
    _listenForSmsOtp();
  }

  void _listenForSmsOtp() async {
    try {
      await SmsAutoFill().listenForCode();
    } catch (_) {
      // Platform unsupported or permission denied
    }
  }

  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      final digitsOnly = code!.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length == 6) {
        setState(() {
          _autoOtpCode = digitsOnly;
          _enteredOtp = digitsOnly;
          _otpError = null;
        });
        _handleVerifyOtp();
      }
    }
  }

  void _startResendTimer() {
    setState(() => _timerSeconds = _resendCooldownSeconds);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    final error = Validators.validateOtp(_enteredOtp);
    if (error != null) {
      setState(() => _otpError = error);
      return;
    }

    setState(() {
      _otpError = null;
      _isLoading = true;
    });

    try {
      final authResponse = await _authRepository.verifyOtp(
        widget.mobileNumber,
        _enteredOtp,
      );

      if (!mounted) return;

      if (!authResponse.success || authResponse.user == null) {
        setState(() => _otpError = 'Incorrect OTP. Please try again.');
        return;
      }

      final user = authResponse.user!;
      final welcomeMessage = user.isNewUser
          ? 'Account created! Welcome to Pawan Mate Education.'
          : 'Welcome back, ${user.name}!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(welcomeMessage),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
        arguments: user,
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString();
      
      // Check for device change error
      if (errorMessage.contains('Device change detected') || errorMessage.contains('Contact admin')) {
        errorMessage = 'Device change detected! Please contact admin to login on a new device.';
      }
      
      setState(() => _otpError = errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_timerSeconds > 0 || _isResending) return;

    setState(() => _isResending = true);
    try {
      final response = await _authRepository.sendOtp(widget.mobileNumber);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Headline
                const Text(
                  'Verify Mobile Number',
                  style: AppStyles.headingLarge,
                ),
                const SizedBox(height: 8),

                // Target Number Chip Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: AppStyles.borderRadiusMedium,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '+91 ${widget.mobileNumber}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Enter 6-Digit OTP Code',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // 6-Digit OTP Box Component
                OtpInputField(
                  length: 6,
                  errorText: _otpError,
                  otpCode: _autoOtpCode,
                  onChanged: (otp) {
                    setState(() {
                      _enteredOtp = otp;
                      if (_otpError != null) _otpError = null;
                    });
                  },
                  onCompleted: (otp) {
                    _enteredOtp = otp;
                    _handleVerifyOtp();
                  },
                ),

                const SizedBox(height: 32),

                // Verify Button
                CustomButton(
                  text: 'Verify & Continue',
                  isLoading: _isLoading,
                  onPressed: _handleVerifyOtp,
                ),

                const SizedBox(height: 28),

                // Resend Code Indicator
                Center(
                  child: _timerSeconds > 0
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'Resend OTP code in ${_timerSeconds}s',
                              style: AppStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Didn't receive the code? ",
                              style: AppStyles.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: _isResending ? null : _handleResendOtp,
                              child: _isResending
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Resend OTP',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
