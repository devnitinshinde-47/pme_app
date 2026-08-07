import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../data/datasources/auth_remote_data_source.dart';
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

  // ── Resend timer: 120 seconds (2 minutes) per product requirement ────────
  static const int _resendCooldownSeconds = 120;
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
    } on DeviceLockedApiException catch (e) {
      if (!mounted) return;
      _showDeviceLockedDialog(e.message, e.userId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _otpError = e.toString());
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
    } on DeviceLockedApiException catch (e) {
      if (!mounted) return;
      _showDeviceLockedDialog(e.message, e.userId);
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

  /// Shows the Device Locked bottom sheet when the account is bound to another device.
  void _showDeviceLockedDialog(String message, String? userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DeviceLockedSheet(
        userId: userId,
        authRepository: _authRepository,
      ),
    );
  }

  String _formatTimer() {
    final minutes = _timerSeconds ~/ 60;
    final seconds = _timerSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
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
                              'Resend OTP in ${_formatTimer()}',
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

// ─── Device Locked Bottom Sheet ────────────────────────────────────────────────

class _DeviceLockedSheet extends StatefulWidget {
  final String? userId;
  final AuthRepository authRepository;

  const _DeviceLockedSheet({this.userId, required this.authRepository});

  @override
  State<_DeviceLockedSheet> createState() => _DeviceLockedSheetState();
}

class _DeviceLockedSheetState extends State<_DeviceLockedSheet> {
  bool _isSubmitting = false;
  bool _requestSent = false;
  String? _error;

  Future<void> _submitRequest() async {
    if (widget.userId == null) {
      setState(() => _error = 'Unable to identify account. Please try again.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.authRepository.submitDeviceChangeRequest(widget.userId!);
      if (!mounted) return;
      setState(() => _requestSent = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _requestSent ? _buildSuccess() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),

        // Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.phone_locked_rounded, size: 32, color: Color(0xFFF59E0B)),
        ),
        const SizedBox(height: 16),

        // Title
        const Text(
          'Single Device Policy Enforced',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),

        // Description
        const Text(
          'To ensure account security and compliance, Pawan Mate Education accounts are limited to 1 active registered device at a time.\n\n'
          'This account is currently bound to another device. If you have switched devices, please request a device change below for admin approval.',
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Info note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Admin approval is required before completing login on a new device.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Request Device Change Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Request Device Change',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Cancel
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.check_circle_rounded, size: 36, color: Color(0xFF16A34A)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Request Submitted!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your device change request has been sent to the admin. '
          'You will be able to login once it is approved.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'OK, Got it',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
