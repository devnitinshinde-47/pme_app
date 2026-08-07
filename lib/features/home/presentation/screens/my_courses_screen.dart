import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../courses/data/models/course_progress_model.dart';
import '../../../courses/data/repositories/course_repository.dart';
import '../widgets/my_course_card.dart';

/// Clean, high-UX My Courses Screen for enrolled students,
/// featuring active batch progress metrics, category filter pills,
/// and direct access to curriculum lessons & study materials.
class MyCoursesScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onNavigateToDiscover;
  final CourseRepository? courseRepository;

  const MyCoursesScreen({
    super.key,
    this.onOpenDrawer,
    this.onNavigateToDiscover,
    this.courseRepository,
  });

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  late final CourseRepository _courseRepository;
  bool _isLoading = true;
  String? _errorMessage;
  List<CourseModel> _enrolledCourses = [];
  Map<String, CourseProgressModel> _coursesProgress = {};

  @override
  void initState() {
    super.initState();
    _courseRepository = widget.courseRepository ?? CourseRepository();
    _loadEnrolledCourses();
  }

  Future<void> _loadEnrolledCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final coursesFuture = _courseRepository.getMyEnrolledCourses();
      final progressFuture = _courseRepository.getAllCoursesProgress();

      final courses = await coursesFuture;
      final progressMap = await progressFuture;

      if (!mounted) return;
      setState(() {
        _enrolledCourses = courses;
        _coursesProgress = progressMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<CourseModel> get _filteredCourses {
    final list = _enrolledCourses.where((c) => !c.isCombo).toList();
    list.sort((a, b) {
      final progA = _coursesProgress[a.id]?.progressPercentage ?? 0.0;
      final progB = _coursesProgress[b.id]?.progressPercentage ?? 0.0;
      if (progA != progB) {
        return progB.compareTo(progA);
      }

      final countA = _coursesProgress[a.id]?.completedVideos ?? 0;
      final countB = _coursesProgress[b.id]?.completedVideos ?? 0;
      if (countA != countB) {
        return countB.compareTo(countA);
      }

      return 0;
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.notes_rounded, color: AppColors.textPrimary, size: 26),
          tooltip: 'Open Menu',
          onPressed: () {
            if (widget.onOpenDrawer != null) {
              widget.onOpenDrawer!();
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
        title: const Text(
          'My Courses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEnrolledCourses,
          color: AppColors.primary,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: AppStyles.cardDecoration,
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.error),
                const SizedBox(height: 10),
                Text(_errorMessage!, textAlign: TextAlign.center, style: AppStyles.bodyMedium),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _loadEnrolledCourses,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_enrolledCourses.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32.0),
            decoration: AppStyles.cardDecoration,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Active Courses Yet',
                  style: AppStyles.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Browse university courses in the Discover catalog and request enrollment to start learning.',
                  style: AppStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onNavigateToDiscover != null) {
                      widget.onNavigateToDiscover!();
                    }
                  },
                  icon: const Icon(Icons.explore_rounded, color: Colors.white, size: 18),
                  label: const Text('Explore Discover Catalog', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 90.0),
      itemCount: _filteredCourses.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummaryHeader();
        }
        final course = _filteredCourses[index - 1];
        return MyCourseCard(
          course: course,
          progress: _coursesProgress[course.id],
          onTap: () async {
            await Navigator.pushNamed(
              context,
              AppRoutes.courseCurriculum,
              arguments: course,
            );
            _loadEnrolledCourses();
          },
        );
      },
    );
  }

  Widget _buildSummaryHeader() {
    final count = _enrolledCourses.length;
    double avgProgress = 0.0;
    if (count > 0) {
      double total = 0.0;
      for (final c in _enrolledCourses) {
        total += _coursesProgress[c.id]?.progressPercentage ?? 0.0;
      }
      avgProgress = total / count;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? "ACTIVE COURSE" : "ACTIVE COURSES"}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Continue Learning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.show_chart_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${avgProgress.toInt()}% Average Completion',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}
