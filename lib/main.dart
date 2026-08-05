import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';
import 'core/constants/app_colors.dart';
import 'core/routes/app_routes.dart';

import 'core/services/fcm_notification_service.dart';
import 'core/utils/app_cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Strictly disable screenshots, screen recordings, and app switcher preview leaks
  try {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageWithBlur();
  } catch (_) {
    // Unsupported platform or initialization fallback
  }

  // Configure memory and image cache limits
  AppCacheManager.instance.configureCacheLimits();

  // Configure system status bar and navigation bar to be clearly visible
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // For Android: Dark icons/text on light status bar
      statusBarBrightness: Brightness.light,     // For iOS: Dark icons/text on light status bar
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PawanMateEducationApp());

  // Do not delay the first Flutter frame for notification permissions, Firebase
  // initialization, or a network token sync. Those are not required to render
  // the launch screen and can take several seconds on a cold start.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FcmNotificationService.instance.initialize();
  });
}

class PawanMateEducationApp extends StatefulWidget {
  const PawanMateEducationApp({super.key});

  @override
  State<PawanMateEducationApp> createState() => _PawanMateEducationAppState();
}

class _PawanMateEducationAppState extends State<PawanMateEducationApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyScreenProtection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyScreenProtection();
    }
  }

  Future<void> _applyScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageWithBlur();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawan Mate Education',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
