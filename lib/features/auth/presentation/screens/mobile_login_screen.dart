import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/custom_button.dart';
import '../widgets/phone_input_field.dart';

/// Human-crafted Mobile Entry Screen for Pawan Mate Education.
class MobileLoginScreen extends StatefulWidget {
  final AuthRepository? authRepository;

  const MobileLoginScreen({super.key, this.authRepository});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  late final TextEditingController _phoneController;
  late final AuthRepository _authRepository;

  String? _phoneError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _authRepository = widget.authRepository ?? AuthRepository();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    final error = Validators.validateMobile(phone);

    if (error != null) {
      setState(() => _phoneError = error);
      return;
    }

    setState(() {
      _phoneError = null;
      _isLoading = true;
    });

    try {
      final response = await _authRepository.sendOtp(phone);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushNamed(
        AppRoutes.otpVerification,
        arguments: phone,
      );
    } on DeviceLockedApiException catch (e) {
      if (!mounted) return;
      // Show the Device Locked sheet right at the mobile entry screen —
      // no OTP was sent (saves SMS credits), and the user gets a clear CTA.
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _DeviceLockedBottomSheet(
          userId: e.userId,
          authRepository: _authRepository,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _phoneError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Top Brand Header
                      Row(
                        children: [
                          Image.asset(
                            AppAssets.logo,
                            height: 64,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Pawan Mate',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'EDUCATION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // Main Title Banner
                      const Text(
                        'Get Started with\nYour Learning Journey',
                        style: AppStyles.headingLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your mobile number to receive a 6-digit OTP verification code.',
                        style: AppStyles.bodyMedium,
                      ),

                      const SizedBox(height: 32),

                      // Phone Input Component
                      PhoneInputField(
                        controller: _phoneController,
                        errorText: _phoneError,
                        enabled: !_isLoading,
                        onChanged: (_) {
                          if (_phoneError != null) {
                            setState(() => _phoneError = null);
                          }
                        },
                        onSubmitted: (_) => _handleSendOtp(),
                      ),

                      const SizedBox(height: 28),

                      // Get OTP Action Button
                      CustomButton(
                        text: 'Get OTP',
                        icon: Icons.arrow_forward_rounded,
                        isLoading: _isLoading,
                        onPressed: _handleSendOtp,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Security Trust Badge
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '100% Secure & Confidential Student Verification',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Device Locked Bottom Sheet (shown from mobile login screen) ───────────────

class _DeviceLockedBottomSheet extends StatefulWidget {
  final String? userId;
  final AuthRepository authRepository;

  const _DeviceLockedBottomSheet({this.userId, required this.authRepository});

  @override
  State<_DeviceLockedBottomSheet> createState() => _DeviceLockedBottomSheetState();
}

class _DeviceLockedBottomSheetState extends State<_DeviceLockedBottomSheet> {
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
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.phone_locked_rounded, size: 32, color: Color(0xFFF59E0B)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Device Locked',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'This account is already logged in on another device. '
          'Submit a request to the admin to switch to this device.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OTP was NOT sent. Admin approval is required before you can login on this device.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
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
            child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
          ),
        ],
        const SizedBox(height: 24),
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
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Request Device Change',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.check_circle_rounded, size: 36, color: Color(0xFF16A34A)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Request Submitted!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your device change request has been sent. '
          'You can login once the admin approves it.',
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
