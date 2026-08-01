import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/blinking_live_badge.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository.dart';

/// Clean, tabbed, highly-organized Course Details Screen.
/// Categorizes course info into Overview, Deliverables, and Access/Curriculum tabs.
class CourseDetailsScreen extends StatefulWidget {
  final CourseModel course;
  final bool isEnrolled;
  final CourseRepository? repository;

  const CourseDetailsScreen({
    super.key,
    required this.course,
    this.isEnrolled = false,
    this.repository,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  late final CourseRepository _repository;
  late Future<CourseModel> _detailsFuture;
  bool _isSubmitting = false;
  bool _isAlreadyRequested = false;
  bool _isAlreadyEnrolled = false;

  @override
  void initState() {
    super.initState();
    _isAlreadyEnrolled = widget.isEnrolled;
    _repository = widget.repository ?? CourseRepository();
    _detailsFuture = _repository.getCourseById(widget.course.id);
    _checkRequestAndEnrollmentStatus();
  }

  Future<void> _checkRequestAndEnrollmentStatus() async {
    try {
      final requestedFuture = _repository.isCourseRequested(widget.course.id);
      final enrolledCoursesFuture = _repository.getMyEnrolledCourses();

      final requested = await requestedFuture;
      final enrolledCourses = await enrolledCoursesFuture;
      final enrolled = widget.isEnrolled || enrolledCourses.any((c) => c.id == widget.course.id);

      if (mounted) {
        setState(() {
          _isAlreadyRequested = requested;
          _isAlreadyEnrolled = enrolled;
        });
      }
    } catch (_) {
      if (mounted && widget.isEnrolled) {
        setState(() => _isAlreadyEnrolled = true);
      }
    }
  }

  Future<void> _handleEnrollmentRequest() async {
    if (_isAlreadyRequested || _isAlreadyEnrolled) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await _repository.submitPurchaseRequest(widget.course.id);
      if (!mounted) return;

      setState(() {
        _isAlreadyRequested = true;
      });

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Request Submitted',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your enrollment request for "${widget.course.name}" has been recorded.'),
              const SizedBox(height: 12),
              if (response.transactionRefId != null) ...[
                Text(
                  'Reference ID: ${response.transactionRefId}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
              ],
              const Text(
                'Our administration team will verify and grant access shortly.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleCancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
        title: const Text('Cancel Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel your enrollment request for "${widget.course.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No, Keep Request', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await _repository.cancelPurchaseRequest(widget.course.id);
      if (!mounted) return;

      setState(() {
        _isAlreadyRequested = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase request for "${widget.course.name}" has been cancelled.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _shareCourse(CourseModel course) {
    final isPolytechnic = course.type.toUpperCase() == 'POLYTECHNIC';
    final feeText = course.price > 0 ? '₹${course.price.toStringAsFixed(0)}' : 'FREE';

    final shareText = '''
🎓 *Pawan Mate Education*
📚 *${course.name}*

🏛 University: ${course.university ?? 'Academic'}
🎓 Level: ${isPolytechnic ? 'Diploma' : 'Degree'}
⏳ Access: ${course.accessDurationMonths ?? 12} Months
💰 Fee: $feeText

📲 Enroll now on the Pawan Mate Education App:
https://pawanmateeducation.com/courses/${course.id}
''';

    final box = context.findRenderObject() as RenderBox?;
    final shareRect = box != null && box.hasSize
        ? (box.localToGlobal(Offset.zero) & box.size)
        : const Rect.fromLTWH(0, 0, 100, 100);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.share_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Course',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Share course details with friends & classmates',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 16),

                // WhatsApp Share Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 22),
                  ),
                  title: const Text('Share via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Send course link & info directly on WhatsApp', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  onTap: () {
                    Navigator.pop(modalContext);
                    Share.share(shareText, subject: course.name, sharePositionOrigin: shareRect);
                  },
                ),

                const SizedBox(height: 8),

                // System Share Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.ios_share_rounded, color: AppColors.primary, size: 22),
                  ),
                  title: const Text('More Share Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Share using Telegram, Email, or other apps', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  onTap: () {
                    Navigator.pop(modalContext);
                    Share.share(shareText, subject: course.name, sharePositionOrigin: shareRect);
                  },
                ),

                const SizedBox(height: 8),

                // Copy Link Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.copy_rounded, color: AppColors.accent, size: 22),
                  ),
                  title: const Text('Copy Course Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Copy formatted link text to clipboard', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  onTap: () {
                    Navigator.pop(modalContext);
                    Clipboard.setData(ClipboardData(text: shareText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Course details copied to clipboard!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateDdMmYyyy(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return 'N/A';
    try {
      final parsed = DateTime.parse(dateStr);
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      return '$day/$month/${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPolytechnic = widget.course.type.toUpperCase() == 'POLYTECHNIC';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FutureBuilder<CourseModel>(
          future: _detailsFuture,
          initialData: widget.course,
          builder: (context, snapshot) {
            final course = snapshot.data ?? widget.course;

            return Column(
              children: [
                Expanded(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        // Sliver Hero Thumbnail Banner (16:9 aspect ratio)
                        SliverAppBar(
                          expandedHeight: MediaQuery.of(context).size.width * 9 / 16,
                          pinned: true,
                          backgroundColor: AppColors.surface,
                          elevation: 0,
                          leading: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.40),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          actions: [
                            Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.40),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                                tooltip: 'Share Course',
                                onPressed: () => _shareCourse(course),
                              ),
                            ),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Full image displayed without crop/zoom, centered
                                Container(
                                  color: AppColors.primaryDark,
                                  child: course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                                      ? Image.network(
                                          course.thumbnailUrl!,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.center,
                                          errorBuilder: (context, error, stackTrace) => _buildMinimalBanner(course),
                                        )
                                      : _buildMinimalBanner(course),
                                ),

                                // Subtle Top Gradient for Back Button Visibility
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.center,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.45),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Clean Title & Category Header Container
                        SliverToBoxAdapter(
                          child: Container(
                            color: AppColors.surface,
                            padding: const EdgeInsets.only(left: 18, right: 18, top: 16, bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subtitle / University & Level Line
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${course.university ?? "ACADEMIC"} • ${isPolytechnic ? "DIPLOMA" : "DEGREE"}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    CourseModeBadge(mode: course.mode),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Course Title
                                Text(
                                  course.name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),

                        // Sticky Segmented Tab Bar
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SliverTabBarDelegate(
                            TabBar(
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.textMuted,
                              indicatorColor: AppColors.primary,
                              indicatorWeight: 3,
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              tabs: const [
                                Tab(text: 'Overview'),
                                Tab(text: 'Highlights'),
                                Tab(text: 'Deliverables'),
                              ],
                            ),
                          ),
                        ),
                      ];
                    },

                    // Tab Contents
                    body: TabBarView(
                      children: [
                        _buildOverviewTab(course),
                        _buildHighlightsTab(course),
                        _buildDeliverablesTab(course),
                      ],
                    ),
                  ),
                ),

                // Fixed Bottom Action Purchase / Access Control Bar
                _buildBottomActionBar(course),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── TAB 1: OVERVIEW ─────────────────────────────────────────────────────────
  Widget _buildOverviewTab(CourseModel course) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Quick Metrics Grid
          Row(
            children: [
              _buildOverviewMetricTile(
                icon: Icons.event_available_rounded,
                iconColor: AppColors.primary,
                label: 'START DATE',
                value: _formatDateDdMmYyyy(course.startDate),
              ),
              const SizedBox(width: 10),
              _buildOverviewMetricTile(
                icon: Icons.event_busy_rounded,
                iconColor: AppColors.accent,
                label: 'EXPIRY DATE',
                value: _formatDateDdMmYyyy(course.endDate),
              ),
              const SizedBox(width: 10),
              _buildOverviewMetricTile(
                icon: Icons.timer_outlined,
                iconColor: const Color(0xFF10B981),
                label: 'VALIDITY',
                value: '${course.accessDurationMonths ?? 12} Mos',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Course Overview Box
          const Text('About This Course', style: AppStyles.headingMedium),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              course.description?.isNotEmpty == true
                  ? course.description!
                  : 'Comprehensive academic module designed according to university syllabus with structured video lectures, numerical problem solutions, and exam preparation notes.',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── TAB 2: HIGHLIGHTS & BRANCHES ───────────────────────────────────────────
  Widget _buildHighlightsTab(CourseModel course) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eligible Branches
          if (course.displayBranches.isNotEmpty) ...[
            const Text('Eligible Branches', style: AppStyles.headingMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: course.displayBranches.map((branch) {
                final isCommon = course.isCommonToAllBranches;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCommon ? AppColors.accent.withValues(alpha: 0.10) : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCommon ? AppColors.accent.withValues(alpha: 0.25) : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCommon) ...[
                        const Icon(Icons.hub_rounded, size: 13, color: AppColors.accent),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        branch,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCommon ? AppColors.accent : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Why Choose This Course Highlights
          const Text('Why Choose This Course?', style: AppStyles.headingMedium),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: const [
                _HighlightRow(icon: Icons.check_circle_rounded, text: '100% University Exam & Syllabus Aligned'),
                Divider(height: 20, color: AppColors.cardBorder),
                _HighlightRow(icon: Icons.check_circle_rounded, text: 'Simplified Concept Explanations & Solved Numericals'),
                Divider(height: 20, color: AppColors.cardBorder),
                _HighlightRow(icon: Icons.check_circle_rounded, text: 'Time-Saving Exam Hacks & Quick Revision Sheets'),
                Divider(height: 20, color: AppColors.cardBorder),
                _HighlightRow(icon: Icons.check_circle_rounded, text: 'High-Scoring Answer Writing Strategies'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOverviewMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 3: DELIVERABLES & FEATURES ──────────────────────────────────────────
  Widget _buildDeliverablesTab(CourseModel course) {
    final isLive = course.mode.toUpperCase() == 'LIVE' || course.mode.toUpperCase() == 'BOTH';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          // Included Features Grouped Master Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (isLive) ...[
                  const _CompactDeliverableTile(
                    icon: Icons.sensors_rounded,
                    iconColor: Color(0xFF10B981),
                    title: 'Interactive Live Classes',
                    subtitle: 'Real-time live sessions & instant doubt clearing',
                  ),
                  const Divider(height: 1, indent: 52, endIndent: 16, color: AppColors.cardBorder),
                  const _CompactDeliverableTile(
                    icon: Icons.video_library_rounded,
                    iconColor: Color(0xFF6C63FF),
                    title: 'Full HD Live Recordings',
                    subtitle: 'Unlimited revision access before exams',
                  ),
                  const Divider(height: 1, indent: 52, endIndent: 16, color: AppColors.cardBorder),
                ] else ...[
                  const _CompactDeliverableTile(
                    icon: Icons.play_circle_fill_rounded,
                    iconColor: AppColors.primary,
                    title: 'Structured HD Video Lectures',
                    subtitle: 'Covers complete syllabus & numerical problem solving',
                  ),
                  const Divider(height: 1, indent: 52, endIndent: 16, color: AppColors.cardBorder),
                ],

                const _CompactDeliverableTile(
                  icon: Icons.sticky_note_2_rounded,
                  iconColor: Color(0xFF8B5CF6),
                  title: 'Lecture-Wise Revision Notes',
                  subtitle: 'Short formula sheets & exam shortcut tricks',
                ),
                const Divider(height: 1, indent: 52, endIndent: 16, color: AppColors.cardBorder),

                const _CompactDeliverableTile(
                  icon: Icons.menu_book_rounded,
                  iconColor: AppColors.accent,
                  title: 'Comprehensive Study Notes & PYQs',
                  subtitle: 'Theory notes, solved numericals & university questions',
                ),
                const Divider(height: 1, indent: 52, endIndent: 16, color: AppColors.cardBorder),

                const _CompactDeliverableTile(
                  icon: Icons.support_agent_rounded,
                  iconColor: Color(0xFF00BFA5),
                  title: '24/7 Doubt Solving Support',
                  subtitle: 'Academic assistance for conceptual & numerical queries',
                ),
                const Divider(height: 1, indent: 52, endIndent: 16, color: AppColors.cardBorder),

                const _CompactDeliverableTile(
                  icon: Icons.quiz_rounded,
                  iconColor: Color(0xFFFF8C00),
                  title: 'Unit Tests & Model Exam Papers',
                  subtitle: 'Chapter test papers aligned with marking scheme',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }



  // ── FIXED BOTTOM ACTION BAR ────────────────────────────────────────────────
  Widget _buildBottomActionBar(CourseModel course) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left Status / Pricing Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isAlreadyEnrolled) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ENROLLED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Full Access Unlocked',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ] else if (_isAlreadyRequested) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.hourglass_top_rounded, size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'PENDING',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Awaiting Admin Approval',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          course.price > 0 ? '₹${course.price.toStringAsFixed(0)}' : 'FREE',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: course.price > 0 ? AppColors.textPrimary : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ total',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      '${course.accessDurationMonths ?? 12} Months Full Access',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Right Action Button
            if (_isAlreadyEnrolled)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.courseCurriculum,
                    arguments: course,
                  );
                },
                icon: const Icon(Icons.play_circle_fill_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Start Learning',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else if (_isAlreadyRequested)
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _handleCancelRequest,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                      )
                    : const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                label: Text(
                  _isSubmitting ? 'Cancelling...' : 'Cancel Request',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                  backgroundColor: AppColors.error.withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleEnrollmentRequest,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Request Access',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildMinimalBanner(CourseModel course) {
    return Container(
      color: AppColors.primaryDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_rounded, size: 48, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              course.university ?? 'Pawan Mate Education',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class _CompactDeliverableTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _CompactDeliverableTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HighlightRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
