import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/course_model.dart';

/// Clean, vertical, industry-standard Course Card for student course discovery.
/// Features a full-width rectangular image banner on top with course info below.
class CourseCard extends StatelessWidget {
  final CourseModel course;
  final bool isRequested;
  final bool isEnrolled;
  final VoidCallback onTap;
  final VoidCallback onEnrollTap;
  final VoidCallback? onCancelTap;
  final VoidCallback? onGoToMyCoursesTap;

  const CourseCard({
    super.key,
    required this.course,
    this.isRequested = false,
    this.isEnrolled = false,
    required this.onTap,
    required this.onEnrollTap,
    this.onCancelTap,
    this.onGoToMyCoursesTap,
  });

  String _formatExpiryDate() {
    DateTime? expiry;

    if (course.endDate != null && course.endDate!.isNotEmpty) {
      try {
        expiry = DateTime.parse(course.endDate!);
      } catch (_) {}
    }

    if (expiry == null && course.startDate != null && course.startDate!.isNotEmpty) {
      try {
        final start = DateTime.parse(course.startDate!);
        final months = course.accessDurationMonths ?? 12;
        expiry = DateTime(start.year, start.month + months, start.day);
      } catch (_) {}
    }

    expiry ??= DateTime.now().add(Duration(days: (course.accessDurationMonths ?? 12) * 30));

    final day = expiry.day.toString().padLeft(2, '0');
    final month = expiry.month.toString().padLeft(2, '0');
    final year = expiry.year;

    return 'Expires: $day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final isPolytechnic = course.type.toUpperCase() == 'POLYTECHNIC';

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Full-Width Rectangular Image Banner (16:9) ─────────
              AspectRatio(
                aspectRatio: 16 / 9,
                child: course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                    ? Image.network(
                        course.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),

              // ── Course Info Section ────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // University & Level line + Mode badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${course.university ?? "ACADEMIC"} • ${isPolytechnic ? "Diploma" : "Degree"}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildModeBadge(course.mode),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Course Title
                    Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Expiry Date
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatExpiryDate(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Price + Action Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price (left side)
                        Text(
                          course.price > 0 ? '₹${course.price.toStringAsFixed(0)}' : 'FREE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: course.price > 0 ? AppColors.textPrimary : AppColors.success,
                          ),
                        ),
                        _buildActionButton(),
                      ],
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

  Widget _buildActionButton() {
    if (isEnrolled) {
      return ElevatedButton.icon(
        onPressed: onGoToMyCoursesTap ?? onTap,
        icon: const Icon(Icons.play_circle_fill_rounded, size: 15, color: Colors.white),
        label: const Text('Access', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          elevation: 0,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    if (isRequested) {
      return OutlinedButton(
        onPressed: onCancelTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
          backgroundColor: AppColors.error.withValues(alpha: 0.05),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Cancel',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onEnrollTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        'Enroll Now',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.school_rounded, size: 48, color: AppColors.primary),
      ),
    );
  }

  Widget _buildModeBadge(String mode) {
    final upper = mode.trim().toUpperCase();
    if (upper == 'BOTH' || upper == 'LIVE_RECORDED' || upper == 'LIVE + RECORDED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFFCA5A5), width: 0.5),
        ),
        child: const Text(
          'LIVE + RECORDED',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFDC2626),
            letterSpacing: 0.2,
          ),
        ),
      );
    } else if (upper == 'LIVE') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFFCA5A5), width: 0.5),
        ),
        child: const Text(
          'LIVE BATCH',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFDC2626),
            letterSpacing: 0.2,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: const Text(
          'RECORDED',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      );
    }
  }
}