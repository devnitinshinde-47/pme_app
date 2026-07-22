import 'package:flutter/material.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/presentation/screens/mobile_login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

/// Centralized route configuration and custom smooth page transitions.
abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otpVerification = '/otp-verification';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case login:
        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => const MobileLoginScreen(),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
          settings: settings,
        );

      case otpVerification:
        final mobileNumber = settings.arguments as String? ?? '';
        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => OtpVerificationScreen(
            mobileNumber: mobileNumber,
          ),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final curve = Curves.easeInOut;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          settings: settings,
        );

      case home:
        final user = settings.arguments as UserModel?;
        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => HomeScreen(user: user),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
