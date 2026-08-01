import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'core/routes/app_routes.dart';

import 'core/services/fcm_notification_service.dart';
import 'core/utils/app_cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class PawanMateEducationApp extends StatelessWidget {
  const PawanMateEducationApp({super.key});

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
