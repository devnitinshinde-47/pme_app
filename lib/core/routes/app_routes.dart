import 'package:flutter/material.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/presentation/screens/mobile_login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/courses/data/models/course_model.dart';
import '../../features/courses/presentation/screens/course_details_screen.dart';
import '../../features/home/presentation/screens/my_progress_screen.dart';
import '../../features/home/presentation/screens/timetable_screen.dart';
import '../../features/home/presentation/screens/zoom_web_meeting_screen.dart';
import '../../features/privacy/presentation/screens/legal_webview_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

import '../../features/courses/presentation/screens/course_curriculum_screen.dart';

import '../../features/courses/presentation/screens/bunny_video_player_screen.dart';
import '../../features/courses/presentation/screens/pdf_reader_screen.dart';
import '../constants/app_colors.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';

/// Centralized route configuration and custom smooth page transitions.
abstract class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Global helper to clear session and redirect user to Login activity on token expiration
  static Future<void> redirectToLogin([String? message]) async {
    try {
      final localDataSource = AuthLocalDataSource();
      await localDataSource.clearSession();
    } catch (_) {}

    final context = navigatorKey.currentContext;
    if (context != null && message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  static const String splash = '/';
  static const String login = '/login';
  static const String otpVerification = '/otp-verification';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsConditions = '/terms-conditions';
  static const String myProgress = '/my-progress';
  static const String notifications = '/notifications';
  static const String courseDetails = '/course-details';
  static const String courseCurriculum = '/course-curriculum';
  static const String videoPlayer = '/video-player';
  static const String pdfReader = '/pdf-reader';
  static const String timetable = '/timetable';
  static const String zoomMeeting = '/zoom-meeting';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: routeSettings,
        );

      case videoPlayer:
        final args = routeSettings.arguments as Map<String, dynamic>;
        final lecture = args['lecture'] as LectureModel;
        final courseName = args['courseName'] as String? ?? 'Pawan Mate Education';
        final courseId = args['courseId'] as String?;

        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => BunnyVideoPlayerScreen(
            lecture: lecture,
            courseName: courseName,
            courseId: courseId,
          ),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
          settings: routeSettings,
        );

      case courseDetails:
        CourseModel course;
        bool isEnrolled = false;
        if (routeSettings.arguments is Map<String, dynamic>) {
          final args = routeSettings.arguments as Map<String, dynamic>;
          course = args['course'] as CourseModel;
          isEnrolled = args['isEnrolled'] as bool? ?? false;
        } else {
          course = routeSettings.arguments as CourseModel;
        }
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CourseDetailsScreen(
            course: course,
            isEnrolled: isEnrolled,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            final curve = Curves.easeOutCubic;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          settings: routeSettings,
        );

      case courseCurriculum:
        final course = routeSettings.arguments as CourseModel;
        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => CourseCurriculumScreen(course: course),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final curve = Curves.easeOutCubic;
            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          settings: routeSettings,
        );

      case login:
        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => const MobileLoginScreen(),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
          settings: routeSettings,
        );

      case otpVerification:
        final mobileNumber = routeSettings.arguments as String? ?? '';
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
          settings: routeSettings,
        );

      case home:
        final user = routeSettings.arguments as UserModel?;
        return PageRouteBuilder(
          pageBuilder: (_, animation, secondaryAnimation) => HomeScreen(user: user),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
          settings: routeSettings,
        );

      case profile:
        final user = routeSettings.arguments as UserModel?;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(user: user),
          settings: routeSettings,
        );

      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: routeSettings,
        );

      case privacyPolicy:
        return MaterialPageRoute(
          builder: (_) => const LegalWebviewScreen(
            url: 'https://www.pawanmateeducation.tech/privacy-policy',
            title: 'Privacy Policy',
          ),
          settings: routeSettings,
        );

      case termsConditions:
        return MaterialPageRoute(
          builder: (_) => const LegalWebviewScreen(
            url: 'https://www.pawanmateeducation.tech/terms-conditions',
            title: 'Terms & Conditions',
          ),
          settings: routeSettings,
        );

      case myProgress:
        return MaterialPageRoute(
          builder: (_) => const MyProgressScreen(),
          settings: routeSettings,
        );

      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
          settings: routeSettings,
        );

      case timetable:
        return MaterialPageRoute(
          builder: (_) => const TimetableScreen(),
          settings: routeSettings,
        );

      case zoomMeeting:
        final zoomArgs = routeSettings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ZoomWebMeetingScreen(
            meetingId: zoomArgs['meetingId'] as String? ?? '',
            passcode: zoomArgs['passcode'] as String? ?? '',
            displayName: zoomArgs['studentName'] as String? ?? 'Student',
            meetingUrl: zoomArgs['meetingUrl'] as String?,
            title: zoomArgs['title'] as String?,
          ),
          settings: routeSettings,
        );

      case pdfReader:
        final pdfArgs = routeSettings.arguments as Map<String, dynamic>;
        final rawUrl = (pdfArgs['pdfUrl'] ?? pdfArgs['url']) as String? ?? '';
        return PageRouteBuilder(
          pageBuilder: (context, animation, _) => PdfReaderScreen(
            pdfUrl: rawUrl,
            title: pdfArgs['title'] as String? ?? 'Study Note',
            fileSize: pdfArgs['fileSize'] as String?,
          ),
          transitionsBuilder: (context, animation, _, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          transitionDuration: const Duration(milliseconds: 350),
          settings: routeSettings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}
