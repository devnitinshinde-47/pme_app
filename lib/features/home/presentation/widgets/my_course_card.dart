import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../courses/data/models/course_progress_model.dart';

/// Professional, state-of-the-art, high-UX My Course Card for enrolled students.
/// Features left thumbnail with subtle play overlay, clean university pill badge,
/// smooth progress bar, lesson metrics, and an active resume action chip.
class MyCourseCard extends StatelessWidget {
  final CourseModel course;
  final CourseProgressModel? progress;
  final VoidCallback? onTap;

  const MyCourseCard({
    super.key,
    required this.course,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage = progress?.progressPercentage ?? 0.0;
    final int completedCount = progress?.completedVideos ?? 0;
    final int totalCount = progress?.totalVideos ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap ??
              () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.courseCurriculum,
                  arguments: course,
                );
              },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Clean 80x80 Course Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            course.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
                const SizedBox(width: 12),

                // Course Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.university ?? "University Course",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (course.isCombo)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'COMBO BUNDLE',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        course.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Sleek Progress Bar & Ratio
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalCount > 0
                                    ? (completedCount / totalCount).clamp(0.0, 1.0)
                                    : (percentage / 100.0).clamp(0.0, 1.0),
                                backgroundColor: AppColors.cardBorder.withValues(alpha: 0.6),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percentage >= 100.0 ? AppColors.success : AppColors.primary,
                                ),
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${percentage.toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: percentage >= 100.0 ? AppColors.success : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Lessons Metric & Resume Chip
                      Row(
                        children: [
                          Icon(
                            completedCount > 0 ? Icons.check_circle_outline_rounded : Icons.play_circle_outline_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              totalCount > 0 ? '$completedCount of $totalCount Lessons' : 'Enrolled Access',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  completedCount > 0 ? 'Resume' : 'Start',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
      ),
    );
  }
}
