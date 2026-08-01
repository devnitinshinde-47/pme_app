import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/liquid_glass_container.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../courses/data/models/course_progress_model.dart';
import '../../../courses/data/repositories/course_repository.dart';

/// Clean, high-UX My Progress & Analytics Screen for enrolled students.
/// Presents overall completion metrics, horizontal visual chart representations,
/// and per-course learning progress breakdown following the KISS principle.
class MyProgressScreen extends StatefulWidget {
  final CourseRepository? courseRepository;

  const MyProgressScreen({
    super.key,
    this.courseRepository,
  });

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  late final CourseRepository _repository;
  bool _isLoading = true;
  String? _errorMessage;

  List<CourseModel> _enrolledCourses = [];
  Map<String, CourseProgressModel> _coursesProgress = {};

  @override
  void initState() {
    super.initState();
    _repository = widget.courseRepository ?? CourseRepository();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final coursesFuture = _repository.getMyEnrolledCourses();
      final progressFuture = _repository.getAllCoursesProgress();

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

  double get _overallPercentage {
    if (_enrolledCourses.isEmpty) return 0.0;
    double total = 0.0;
    for (var c in _enrolledCourses) {
      total += _coursesProgress[c.id]?.progressPercentage ?? 0.0;
    }
    return total / _enrolledCourses.length;
  }

  int get _totalCompletedLectures {
    int total = 0;
    for (var p in _coursesProgress.values) {
      total += p.completedVideos;
    }
    return total;
  }

  int get _totalLectures {
    int total = 0;
    for (var p in _coursesProgress.values) {
      total += p.totalVideos;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final overallPct = _overallPercentage;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Learning Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: _loadData,
            tooltip: 'Refresh Progress',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18.0),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
                : _errorMessage != null
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppStyles.cardDecoration,
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: AppStyles.bodyMedium, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text('Retry', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _enrolledCourses.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: AppStyles.cardDecoration,
                            child: Column(
                              children: [
                                const Icon(Icons.donut_large_rounded, size: 54, color: AppColors.primary),
                                const SizedBox(height: 16),
                                const Text('No Course Progress Yet', style: AppStyles.headingMedium),
                                const SizedBox(height: 8),
                                const Text('Enroll in courses to start tracking your video lecture completion stats.', style: AppStyles.bodyMedium, textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Executive Analytics Banner
                              _buildOverallSummaryCard(overallPct),

                              const SizedBox(height: 20),

                              // Course Progress Chart Section
                              const Text(
                                'COURSE PROGRESS CHART',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                              ),

                              const SizedBox(height: 10),

                              _buildProgressChart(),

                              const SizedBox(height: 24),

                              // Per-Course Breakdown Header
                              const Text(
                                'ENROLLED COURSES BREAKDOWN',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
                              ),

                              const SizedBox(height: 12),

                              ..._enrolledCourses.map((course) => _buildCourseProgressItem(course)),
                            ],
                          ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallSummaryCard(double overallPct) {
    return LiquidGlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Row(
            children: [
              // Circular Progress Ring Indicator
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: (overallPct / 100.0).clamp(0.0, 1.0),
                      strokeWidth: 7,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        overallPct >= 100.0 ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${overallPct.toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: overallPct >= 100.0 ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              // Overview Metrics Right Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Learning Progress',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_enrolledCourses.length} Enrolled Courses • $_totalCompletedLectures of ${_totalLectures > 0 ? _totalLectures : "N/A"} Lectures Done',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),

          // Mini Metric Chips Row
          Row(
            children: [
              _buildMiniMetricChip('Courses Enrolled', '${_enrolledCourses.length}', Icons.school_rounded, AppColors.primary),
              const SizedBox(width: 10),
              _buildMiniMetricChip('Lectures Done', '$_totalCompletedLectures', Icons.check_circle_rounded, AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetricChip(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Minimalist, industry-standard horizontal bar chart representation of course progress
  Widget _buildProgressChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppStyles.softShadow,
      ),
      child: Column(
        children: _enrolledCourses.map((course) {
          final prog = _coursesProgress[course.id];
          final pct = prog?.progressPercentage ?? 0.0;
          final completed = prog?.completedVideos ?? 0;
          final total = prog?.totalVideos ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.name,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (pct >= 100.0 ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pct.toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: pct >= 100.0 ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (pct / 100.0).clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: pct >= 100.0
                                ? [AppColors.success, AppColors.success]
                                : [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  total > 0 ? '$completed of $total video lectures completed' : 'Enrolled',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCourseProgressItem(CourseModel course) {
    final prog = _coursesProgress[course.id];
    final pct = prog?.progressPercentage ?? 0.0;
    final completed = prog?.completedVideos ?? 0;
    final total = prog?.totalVideos ?? 0;
    final isCompleted = pct >= 100.0;
    final isStarted = completed > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppStyles.softShadow,
      ),
      child: Row(
        children: [
          // Course Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success.withValues(alpha: 0.12)
                  : isStarted
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.textMuted.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : isStarted
                      ? Icons.play_circle_fill_rounded
                      : Icons.school_rounded,
              color: isCompleted
                  ? AppColors.success
                  : isStarted
                      ? AppColors.primary
                      : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Course Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.success.withValues(alpha: 0.12)
                            : isStarted
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCompleted ? 'COMPLETED' : (isStarted ? 'IN PROGRESS' : 'NOT STARTED'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? AppColors.success
                              : isStarted
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      total > 0 ? '$completed/$total Lectures' : 'Subscribed',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Continue Button
          OutlinedButton(
            onPressed: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.courseCurriculum,
                arguments: course,
              );
              _loadData();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
