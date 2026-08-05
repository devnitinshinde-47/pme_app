import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../../../core/widgets/liquid_glass_bottom_nav.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../courses/data/repositories/course_repository.dart';
import '../widgets/app_drawer.dart';
import 'discover_screen.dart';
import 'home_tab.dart';
import 'my_courses_screen.dart';

import '../../../../core/services/system_config_service.dart';
import '../../../../core/widgets/under_maintenance_dialog.dart';
import '../../../../core/widgets/app_update_modal.dart';
import '../../../../core/widgets/popup_ad_modal.dart';

/// Main Shell Screen hosting Left Navigation Drawer and Liquid Glass Bottom Navigation Bar.
class HomeScreen extends StatefulWidget {
  final UserModel? user;

  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authRepository = AuthRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;
  late UserModel? _currentUser;
  bool _isPromptingName = false;
  /// Initial category filter to pass to DiscoverScreen when navigating from Quick Access.
  String? _discoverInitialFilter;

  /// Tracks whether the user already pressed back once on the Home tab.
  DateTime? _lastBackPressTime;

  static bool _hasShownPopupAdThisSession = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
      _checkSystemConfig();
      _checkAndPromptName();
    });
  }

  Future<void> _checkSystemConfig() async {
    try {
      final config = await SystemConfigService().fetchSystemConfig();
      if (!mounted || config == null) return;

      // 1. Check Under Maintenance Mode
      if (config.maintenanceEnabled) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UnderMaintenanceDialog(
            config: config,
            onRetry: () {
              Navigator.pop(context);
              _checkSystemConfig();
            },
          ),
        );
        return;
      }

      // 2. Check App Version Update Config
      if (config.appUpdateEnabled) {
        AppUpdateModal.show(context, config);
        return;
      }

      // 3. Check Popup Ad Banner
      if (config.popupAdEnabled && !_hasShownPopupAdThisSession) {
        _hasShownPopupAdThisSession = true;
        PopupAdModal.show(context, config);
      }
    } catch (_) {}
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
      await FcmNotificationService.instance.syncTokenWithBackend();
    } catch (_) {}
  }

  bool get _needsNamePrompt {
    if (_currentUser == null) return true;
    final name = _currentUser?.name?.trim();
    return name == null || name.isEmpty || name == 'Student' || name == 'User';
  }

  Future<void> _checkAndPromptName() async {
    // If user object is null, try loading from local session first
    if (_currentUser == null) {
      final savedUser = await _authRepository.getStoredUser();
      if (mounted && savedUser != null) {
        setState(() => _currentUser = savedUser);
      }
    }

    if (!mounted) return;

    if (_needsNamePrompt && !_isPromptingName) {
      _showEnterNameModal();
    } else {
      _checkAndShowMarketingOfferModal();
    }
  }

  Future<void> _checkAndShowMarketingOfferModal() async {
    try {
      final enrolled = await CourseRepository().getMyEnrolledCourses();
      if (mounted && enrolled.isEmpty) {
        _showSpecialOfferDialog();
      }
    } catch (_) {}
  }

  void _showSpecialOfferDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          color: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Banner Gradient Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '🔥 SPECIAL ADMISSION OFFER',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Boost Your Engineering & Diploma Scores! 🚀',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Unlock 100% syllabus coverage, live & recorded lectures, handwritten notes, and solved PYQ papers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                    ),
                    const SizedBox(height: 16),

                    // Feature checklist
                    const _OfferCheckRow(text: 'Complete MSBTE, SPPU & DBATU syllabus'),
                    const SizedBox(height: 8),
                    const _OfferCheckRow(text: 'Previous 5 Years Solved Question Papers'),
                    const SizedBox(height: 8),
                    const _OfferCheckRow(text: '24/7 Live Doubt Resolution & Practice Tests'),

                    const SizedBox(height: 20),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          setState(() => _currentIndex = 2); // Switch to Discover tab
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Explore & Purchase Courses →',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Remind Me Later', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
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

  void _showEnterNameModal() {
    _isPromptingName = true;
    final nameController = TextEditingController();
    String? errorText;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return PopScope(
              canPop: false, // Require name entry
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.all(24),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 36),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title & Subtitle
                    const Center(
                      child: Text(
                        'Welcome to PME! 🎓',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please enter your full name to complete your student profile and get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                    ),

                    const SizedBox(height: 20),

                    // Name Input Field
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                        errorText: errorText,
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      onChanged: (_) {
                        if (errorText != null) {
                          setModalState(() => errorText = null);
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final inputName = nameController.text.trim();
                                if (inputName.isEmpty || inputName.length < 2) {
                                  setModalState(() => errorText = 'Please enter a valid full name');
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  final updatedUser = await _authRepository.updateProfileName(inputName);

                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }

                                  _isPromptingName = false;

                                  if (mounted) {
                                    setState(() {
                                      _currentUser = updatedUser;
                                    });

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Welcome, $inputName! Your profile is set up.'),
                                        backgroundColor: AppColors.primary,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    _checkAndShowMarketingOfferModal();
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isSubmitting = false;
                                    errorText = 'Failed to save name. Please try again.';
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Save & Continue →',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<bool> _onWillPop() async {
    // If on Discover or My Courses tab, navigate back to Home tab
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false; // Prevent default back action
    }

    // On Home tab: show toast on first press, exit on second press within 2 seconds
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Press back again to exit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return false; // Prevent exit on first press
    }

    return true; // Allow exit on second press
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeTab(
        user: _currentUser,
        onOpenDrawer: _openDrawer,
        onLogout: () => _handleLogout(context),
        onNavigateToDiscover: ({String? filter}) => setState(() {
          _discoverInitialFilter = filter;
          _currentIndex = 2;
        }),
        onNavigateToMyCourses: () => setState(() => _currentIndex = 1),
      ),
      MyCoursesScreen(
        onOpenDrawer: _openDrawer,
        onNavigateToDiscover: () => setState(() => _currentIndex = 2),
      ),
      DiscoverScreen(
        key: ValueKey(_discoverInitialFilter),
        onOpenDrawer: _openDrawer,
        onNavigateToMyCourses: () => setState(() => _currentIndex = 1),
        initialCategoryPill: _discoverInitialFilter,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          SystemNavigator.pop(); // Properly exits the app on Android
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          backgroundColor: AppColors.background,
          drawer: AppDrawer(
            user: _currentUser,
            onLogout: () => _handleLogout(context),
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: LiquidGlassBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              LiquidGlassNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              LiquidGlassNavItem(
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book_rounded,
                label: 'My Courses',
              ),
              LiquidGlassNavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'Discover',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out from Pawan Mate Education?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _authRepository.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCheckRow extends StatelessWidget {
  final String text;
  const _OfferCheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
