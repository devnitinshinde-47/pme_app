import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
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
