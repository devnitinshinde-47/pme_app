import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../widgets/animated_logo.dart';

/// Minimalist animated splash screen with auto-login token refresh routing.
class SplashScreen extends StatefulWidget {
  final AuthRepository? authRepository;

  const SplashScreen({super.key, this.authRepository});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AuthRepository _authRepository;
  UserModel? _authenticatedUser;
  bool _isCheckCompleted = false;

  static const Duration _minimumSplashDuration = Duration(milliseconds: 900);
  static const Duration _birthdaySplashDuration = Duration(milliseconds: 3500);
  static const Duration _autoLoginTimeout = Duration(seconds: 2);

  /// Returns true if today is August 2nd (Pawan Sir's birthday).
  static bool get _isPawansBirthday {
    final today = DateTime.now();
    return today.month == 8 && today.day == 2;
  }

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepository();
    _initAnimationAndAutoLogin();
  }

  Future<void> _initAnimationAndAutoLogin() async {
    // On birthday, extend the animation duration to show the full birthday animation
    final animationDuration = _isPawansBirthday
        ? const Duration(milliseconds: 2500)
        : const Duration(milliseconds: 800);

    _animationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );
    _animationController.forward();

    final startTime = DateTime.now();

    try {
      _authenticatedUser = await _authRepository
          .tryAutoLogin()
          .timeout(_autoLoginTimeout);
    } catch (_) {
      _authenticatedUser = null;
    } finally {
      _isCheckCompleted = true;
    }

    final elapsed = DateTime.now().difference(startTime);
    final targetDuration = _isPawansBirthday ? _birthdaySplashDuration : _minimumSplashDuration;
    final remainingTime = targetDuration - elapsed;

    if (remainingTime > Duration.zero) {
      await Future.delayed(remainingTime);
    }

    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    if (_isCheckCompleted && _authenticatedUser != null) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.home,
        arguments: _authenticatedUser,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        backgroundColor: AppColors.splashBackground,
        body: SafeArea(
          child: Stack(
            children: [
              // Ambient soft background glowing shapes
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -60,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentLight.withValues(alpha: 0.6),
                  ),
                ),
              ),

              Column(
                children: [
                  const Spacer(),

                  // Animated Brand Logo & Teacher Photo
                  Center(
                    child: AnimatedLogo(
                      controller: _animationController,
                      isBirthday: _isPawansBirthday,
                    ),
                  ),

                  const Spacer(),

                  // Bottom Minimal Footer
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Empowering Student Learning',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
