import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/liquid_glass_container.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../courses/data/models/course_progress_model.dart';
import '../../../courses/data/repositories/course_repository.dart';
import '../../data/models/student_live_lecture_model.dart';
import '../../data/repositories/live_lecture_repository.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../services/zoom_sdk_service.dart';

/// DTO for holding active/upcoming live lecture occurrence on Home Tab.
class ActiveLiveLectureOccurrence {
  final StudentLiveLecture lecture;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isOngoing;

  ActiveLiveLectureOccurrence({
    required this.lecture,
    required this.startDateTime,
    required this.endDateTime,
    required this.isOngoing,
  });

  String get timeRangeStr {
    final startFormatted = _formatTime(startDateTime.hour, startDateTime.minute);
    final endFormatted = _formatTime(endDateTime.hour, endDateTime.minute);
    return '$startFormatted - $endFormatted';
  }

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m $period';
  }
}

/// Home Tab — swipeable Continue Watching + Live Lecture hero banner + Quick Access grid.
class HomeTab extends StatefulWidget {
  final UserModel? user;
  final VoidCallback? onOpenDrawer;
  final VoidCallback onLogout;
  final void Function({String? filter})? onNavigateToDiscover;
  final VoidCallback? onNavigateToMyCourses;

  const HomeTab({
    super.key,
    this.user,
    this.onOpenDrawer,
    required this.onLogout,
    this.onNavigateToDiscover,
    this.onNavigateToMyCourses,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _repository = CourseRepository();
  final _liveLectureRepository = LiveLectureRepository();
  final _notificationRepository = NotificationRepository();
  final _pageController = PageController();
  int _currentPage = 0;

  List<CourseModel> _enrolledCourses = [];
  Map<String, CourseProgressModel> _progressMap = {};
  List<StudentLiveLecture> _fetchedLiveLectures = [];
  int _unreadNotificationCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final courses = await _repository.getMyEnrolledCourses();
      final progress = await _repository.getAllCoursesProgress();

      List<StudentLiveLecture> liveLectures = [];
      try {
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, now.day);
        final endDate = startDate.add(const Duration(days: 7));
        liveLectures = await _liveLectureRepository.getLiveLecturesCalendar(
          start: startDate,
          end: endDate,
        );
      } catch (_) {}

      int unreadCount = 0;
      try {
        unreadCount = await _notificationRepository.getUnreadNotificationsCount();
      } catch (_) {}

      if (!mounted) return;

      // Sort by progress descending (most-recently-watched first)
      final sorted = List<CourseModel>.from(courses)
        ..sort((a, b) {
          final pa = progress[a.id]?.progressPercentage ?? 0;
          final pb = progress[b.id]?.progressPercentage ?? 0;
          return pb.compareTo(pa);
        });

      setState(() {
        _enrolledCourses = sorted;
        _progressMap = progress;
        _fetchedLiveLectures = liveLectures;
        _unreadNotificationCount = unreadCount;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  ActiveLiveLectureOccurrence? _getActiveLiveLecture() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final occurrences = <ActiveLiveLectureOccurrence>[];

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      for (final lecture in _fetchedLiveLectures) {
        if (!lecture.occursOnDate(date)) continue;

        final rawStart = lecture.startDateTime;
        final startDt = rawStart != null
            ? DateTime(date.year, date.month, date.day, rawStart.hour, rawStart.minute)
            : DateTime(date.year, date.month, date.day, 9, 0);
        final endDt = startDt.add(const Duration(minutes: 60));

        final isOngoing = now.isAfter(startDt) && now.isBefore(endDt);
        final isUpcoming = now.isBefore(startDt);

        if (isOngoing || isUpcoming) {
          occurrences.add(
            ActiveLiveLectureOccurrence(
              lecture: lecture,
              startDateTime: startDt,
              endDateTime: endDt,
              isOngoing: isOngoing,
            ),
          );
        }
      }
    }

    if (occurrences.isEmpty) return null;

    // Prioritize ongoing lectures first, then earliest start time
    occurrences.sort((a, b) {
      if (a.isOngoing && !b.isOngoing) return -1;
      if (!a.isOngoing && b.isOngoing) return 1;
      return a.startDateTime.compareTo(b.startDateTime);
    });

    return occurrences.first;
  }

  Future<void> _handleJoinMeeting(BuildContext context, ActiveLiveLectureOccurrence active) async {
    final raw = active.lecture;

    String meetingId = raw.zoomMeetingId;
    String passcode = raw.zoomPasscode;
    if (meetingId.isEmpty) {
      meetingId = '81234567890';
    }
    if (passcode.isEmpty) {
      passcode = '123456';
    }

    final user = await AuthLocalDataSource().getUser();
    final studentName = user?.name ?? 'Student';

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Launching Native Zoom Meeting SDK for ${raw.title}...')),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    await ZoomSdkService().joinNativeMeeting(
      context: context,
      meetingId: meetingId,
      passcode: passcode,
      displayName: studentName,
      title: raw.title,
      zakToken: raw.zakToken,
      zoomAccessToken: raw.zoomAccessToken,
      meetingUrl: raw.meetingUrl,
    );
  }

  void _showPurchaseRequiredModal(String featureName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Unlock $featureName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'To access $featureName, enroll in a course today and get full access to live classes, DPPs, test series, and handwritten notes!',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (widget.onNavigateToDiscover != null) {
                widget.onNavigateToDiscover!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Explore Courses →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showComboOffersDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final screenSize = MediaQuery.of(dialogContext).size;
        final isSmallScreen = screenSize.height < 600;
        final isLandscape = screenSize.width > screenSize.height;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 24,
            vertical: isSmallScreen ? 8 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: screenSize.height * (isLandscape ? 0.9 : 0.85),
            ),
            child: Container(
              decoration: AppStyles.cardDecoration,
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Gradient Header Banner ─────────────────────────────
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      isSmallScreen ? 16 : 22,
                      20,
                      isSmallScreen ? 14 : 18,
                    ),
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
                          width: isSmallScreen ? 48 : 56,
                          height: isSmallScreen ? 48 : 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.all_inclusive_rounded,
                            color: Colors.white,
                            size: isSmallScreen ? 26 : 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Combo Offers 🎁',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 17 : 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buy more · Save more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Body Content (scrollable for small screens) ──────
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Discount highlight card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: AppStyles.borderRadiusMedium,
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.local_offer_rounded,
                                  color: AppColors.accent,
                                  size: 22,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'If you are purchasing more than 1 course, then you will get a special discount on your purchase! 🎉',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Contact Pawan Sir with the courses you want to purchase:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Contact card — Pawan Sir (Liquid glass style)
                          LiquidGlassContainer(
                            padding: const EdgeInsets.all(14),
                            borderRadius: AppStyles.borderRadiusMedium,
                            backgroundColor: AppColors.glassBackground,
                            borderColor: AppColors.glassBorder,
                            blur: 8,
                            boxShadow: AppStyles.softShadow,
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [AppColors.primaryDark, AppColors.primary],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'PS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Pawan Sir',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        '9075554662',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // WhatsApp CTA button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final message = Uri.encodeComponent(
                                  'Hello Pawan Sir, I am interested in combo course offers. I would like to know the discount on the courses I want to purchase.',
                                );
                                final whatsappUri = Uri.parse('https://wa.me/919075554662?text=$message');
                                await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(Icons.chat_rounded, size: 18),
                              label: const Text(
                                'Chat on WhatsApp',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppStyles.borderRadiusMedium,
                                ),
                                elevation: 2,
                                shadowColor: const Color(0xFF25D366).withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Close button centered
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textMuted,
                              ),
                              child: const Text('Not Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTestSeriesDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.text_snippet_rounded, color: Color(0xFFF59E0B), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Test Series Coming Soon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Test Series is currently being updated and will be available soon. Stay tuned for chapter-wise practice tests, solved PYQs & detailed performance analysis!',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.user?.name?.isNotEmpty == true
        ? widget.user!.name!
        : 'Student';

    // Build cards for the swipeable hero area
    final heroPanels = <Widget>[];
    final activeLive = _getActiveLiveLecture();

    if (_isLoading) {
      heroPanels.add(_LoadingHeroCard());
    } else {
      // 1. If user has an active (ongoing or upcoming) live lecture, present Live Lecture Card first
      if (activeLive != null) {
        heroPanels.add(
          _LiveLectureCard(
            occurrence: activeLive,
            onJoinTap: () => _handleJoinMeeting(context, activeLive),
          ),
        );
      }

      // 2. Continue watching card — last watched course
      if (_enrolledCourses.isNotEmpty) {
        final topCourse = _enrolledCourses.first;
        final topProgress = _progressMap[topCourse.id];
        heroPanels.add(
          _ContinueWatchingCard(
            course: topCourse,
            progress: topProgress,
            onTap: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.courseCurriculum,
                arguments: topCourse,
              );
              _loadData();
            },
          ),
        );
      }
    }

    // If no enrolled courses and no active live lecture — show Explore Courses marketing card
    if (heroPanels.isEmpty) {
      heroPanels.add(
        _ExploreCoursesCard(
          studentName: studentName,
          onExploreTap: () {
            if (widget.onNavigateToDiscover != null) {
              widget.onNavigateToDiscover!();
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.notes_rounded,
              color: AppColors.textPrimary, size: 26),
          tooltip: 'Open Menu',
          onPressed: () {
            if (widget.onOpenDrawer != null) {
              widget.onOpenDrawer!();
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $studentName 👋',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Pawan Mate Education',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: AppColors.textPrimary),
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRoutes.notifications);
                  _loadData();
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
                left: 18, right: 18, top: 20, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Swipeable Hero Banner ─────────────────────────────
                SizedBox(
                  height: 170,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: heroPanels.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 0),
                      child: heroPanels[i],
                    ),
                  ),
                ),

                // Page indicator dots (only when multiple cards)
                if (heroPanels.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(heroPanels.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == i ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.cardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Quick Access ──────────────────────────────────────
                const Text('Quick Access', style: AppStyles.headingMedium),
                const SizedBox(height: 14),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.25,
                  children: [
                    _FeatureTile(
                      icon: Icons.calendar_month_rounded,
                      title: 'Timetable',
                      subtitle: 'Weekly Class Schedule',
                      badgeColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        if (_enrolledCourses.isEmpty) {
                          _showPurchaseRequiredModal('Timetable');
                        } else {
                          Navigator.pushNamed(context, AppRoutes.timetable);
                        }
                      },
                    ),
                    _FeatureTile(
                      icon: Icons.live_tv_rounded,
                      title: 'Live Courses',
                      subtitle: 'Live Classes + Recordings',
                      badgeColor: const Color(0xFFEF4444),
                      onTap: () {
                        if (widget.onNavigateToDiscover != null) {
                          widget.onNavigateToDiscover!(filter: 'LIVE');
                        }
                      },
                    ),
                    _FeatureTile(
                      icon: Icons.play_circle_fill_rounded,
                      title: 'Video Courses',
                      subtitle: 'Pre-Recorded Videos',
                      badgeColor: const Color(0xFF3B82F6),
                      onTap: () {
                        if (widget.onNavigateToDiscover != null) {
                          widget.onNavigateToDiscover!(filter: 'RECORDED');
                        }
                      },
                    ),
                    _FeatureTile(
                      icon: Icons.all_inclusive_rounded,
                      title: 'Combo Courses',
                      subtitle: 'Bundles with offers & discounts',
                      badgeColor: const Color(0xFF8B5CF6),
                      onTap: () => _showComboOffersDialog(),
                    ),
                    _FeatureTile(
                      icon: Icons.school_rounded,
                      title: 'Demo Courses',
                      subtitle: 'Free Trial Lessons',
                      badgeColor: const Color(0xFF10B981),
                      onTap: () {
                        if (widget.onNavigateToDiscover != null) {
                          widget.onNavigateToDiscover!(filter: 'DEMO');
                        }
                      },
                    ),
                    _FeatureTile(
                      icon: Icons.text_snippet_rounded,
                      title: 'Test Series',
                      subtitle: 'Practice Tests & PYQs',
                      badgeColor: const Color(0xFFF59E0B),
                      onTap: () => _showTestSeriesDialog(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Continue Watching Card ────────────────────────────────────────────────────

class _ContinueWatchingCard extends StatelessWidget {
  final CourseModel course;
  final CourseProgressModel? progress;
  final VoidCallback? onTap;

  const _ContinueWatchingCard({required this.course, this.progress, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = progress?.progressPercentage ?? 0.0;
    final completed = progress?.completedVideos ?? 0;
    final total = progress?.totalVideos ?? 0;
    final isStarted = completed > 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap ??
              () => Navigator.pushNamed(
                    context,
                    AppRoutes.courseCurriculum,
                    arguments: course,
                  ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 13),
                          SizedBox(width: 3),
                          Text(
                            'CONTINUE WATCHING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${pct.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Course title
                Text(
                  course.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0
                        ? (completed / total).clamp(0.0, 1.0)
                        : (pct / 100.0).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 5,
                  ),
                ),

                const SizedBox(height: 8),

                // Lessons count + button
                Row(
                  children: [
                    Text(
                      total > 0
                          ? '$completed / $total lessons'
                          : 'Access granted',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isStarted ? 'Resume →' : 'Start →',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Live Lecture Card ─────────────────────────────────────────────────────────

class _LiveLectureCard extends StatelessWidget {
  final ActiveLiveLectureOccurrence occurrence;
  final VoidCallback onJoinTap;

  const _LiveLectureCard({
    required this.occurrence,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    final lecture = occurrence.lecture;
    final isOngoing = occurrence.isOngoing;
    final now = DateTime.now();

    final isSameDay = occurrence.startDateTime.year == now.year &&
        occurrence.startDateTime.month == now.month &&
        occurrence.startDateTime.day == now.day;

    final isTomorrow = occurrence.startDateTime.year == now.year &&
        occurrence.startDateTime.month == now.month &&
        occurrence.startDateTime.day == now.day + 1;

    String scheduleSubtitle;
    if (isOngoing) {
      scheduleSubtitle = 'In progress · Ends at ${ActiveLiveLectureOccurrence._formatTime(occurrence.endDateTime.hour, occurrence.endDateTime.minute)}';
    } else if (isSameDay) {
      scheduleSubtitle = 'Today at ${ActiveLiveLectureOccurrence._formatTime(occurrence.startDateTime.hour, occurrence.startDateTime.minute)}';
    } else if (isTomorrow) {
      scheduleSubtitle = 'Tomorrow at ${ActiveLiveLectureOccurrence._formatTime(occurrence.startDateTime.hour, occurrence.startDateTime.minute)}';
    } else {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = days[occurrence.startDateTime.weekday - 1];
      scheduleSubtitle = '$dayName, ${occurrence.startDateTime.day}/${occurrence.startDateTime.month} at ${ActiveLiveLectureOccurrence._formatTime(occurrence.startDateTime.hour, occurrence.startDateTime.minute)}';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.surface,
        border: Border.all(
          color: isOngoing
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOngoing
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOngoing
                              ? const Color(0xFF10B981)
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOngoing ? 'LIVE NOW' : 'UPCOMING LIVE',
                        style: TextStyle(
                          color: isOngoing
                              ? const Color(0xFF10B981)
                              : AppColors.primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.video_call_rounded, color: AppColors.primary, size: 22),
              ],
            ),

            const Spacer(),

            // Course Name
            Text(
              lecture.subjectCode != null && lecture.subjectCode!.isNotEmpty
                  ? '${lecture.courseName} (${lecture.subjectCode})'
                  : lecture.courseName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Lecture Title
            Text(
              lecture.title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    scheduleSubtitle,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onJoinTap,
                icon: const Icon(
                  Icons.live_tv_rounded,
                  size: 16,
                ),
                label: const Text(
                  'Join Live Class',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOngoing
                      ? const Color(0xFF10B981)
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Explore Courses Marketing Card (no enrollments) ─────────────────────────

class _ExploreCoursesCard extends StatelessWidget {
  final String studentName;
  final VoidCallback? onExploreTap;

  const _ExploreCoursesCard({
    required this.studentName,
    this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onExploreTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Tag Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'START YOUR JOURNEY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Catchy Title & Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $studentName! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Master Engineering & Diploma exams with live classes, handwritten notes & solved PYQs.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Action Row
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Explore Courses',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Loading Card ──────────────────────────────────────────────────────────────

class _LoadingHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

// ── Feature Tile ──────────────────────────────────────────────────────────────

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.all(16.0),
      borderRadius: AppStyles.borderRadiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: badgeColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
