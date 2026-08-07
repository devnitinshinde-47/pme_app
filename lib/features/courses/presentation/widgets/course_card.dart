import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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

  String _getBranchLabel() {
    if (course.branches.length == 1) {
      final branchName = course.branches.first.trim();
      final lower = branchName.toLowerCase();
      if (lower == 'all' ||
          lower == 'common' ||
          lower == 'all branches' ||
          lower == 'common for all' ||
          lower == 'common to all') {
        return 'Common for all branches';
      }
      return branchName;
    }
    return 'Common for all branches';
  }

  @override
  Widget build(BuildContext context) {
    final universityName = (course.university != null && course.university!.trim().isNotEmpty)
        ? course.university!.trim()
        : 'MSBTE';

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: course.isCombo
              ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
              : AppColors.cardBorder,
          width: course.isCombo ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: course.isCombo
                ? const Color(0xFFF59E0B).withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: course.isCombo ? 12 : 8,
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
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            course.thumbnailUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildShimmerPlaceholder();
                            },
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                            cacheWidth: 720,
                            cacheHeight: 405,
                          )
                        : _buildPlaceholder(),
                  ),
                  if (course.isCombo) ...[
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.stars_rounded, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'SPECIAL COMBO OFFER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (course.originalPrice != null && course.originalPrice! > course.price)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '🔥 ${(((course.originalPrice! - course.price) / course.originalPrice!) * 100).round()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),

              // ── Course Info Section ────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header category tag / Mode badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.isCombo
                                ? 'COMBO OFFER BUNDLE'
                                : universityName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: course.isCombo ? const Color(0xFFD97706) : AppColors.primary,
                              letterSpacing: 0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (course.isCombo)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'MULTI-COURSE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          )
                        else
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

                    // Included Courses info for Combo, or Branch for single course
                    if (course.isCombo) ...[
                      if (course.includedCourses.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: course.includedCourses.take(3).map((bundled) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                ),
                                child: Text(
                                  '✓ ${bundled.name}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      else
                        Text(
                          'Includes ${course.includedCourseIds.isNotEmpty ? course.includedCourseIds.length : 2}+ Courses in 1 Package Offer',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      const SizedBox(height: 4),
                    ] else ...[
                      Text(
                        _getBranchLabel(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Expiry / Duration
                    Row(
                      children: [
                        Icon(
                          course.isCombo ? Icons.all_inclusive_rounded : Icons.schedule_rounded,
                          size: 13,
                          color: course.isCombo ? const Color(0xFFD97706) : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            course.isCombo
                                ? 'Full Access for ${course.accessDurationMonths ?? 12} Months to All Courses'
                                : _formatExpiryDate(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: course.isCombo ? FontWeight.w600 : FontWeight.w500,
                              color: course.isCombo ? AppColors.textSecondary : AppColors.textMuted,
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price (left side) with strikethrough if discounted
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (course.originalPrice != null && course.originalPrice! > course.price) ...[
                              Row(
                                children: [
                                  Text(
                                    '₹${course.originalPrice!.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMuted,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Save ₹${(course.originalPrice! - course.price).toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                            ],
                            Text(
                              course.price > 0 ? '₹${course.price.toStringAsFixed(0)}' : 'FREE',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: course.price > 0 ? AppColors.textPrimary : AppColors.success,
                              ),
                            ),
                          ],
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

  /// Animated shimmer shown while the thumbnail is downloading from the network.
  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EAF0),
      highlightColor: const Color(0xFFF5F6FA),
      period: const Duration(milliseconds: 1200),
      child: Container(color: const Color(0xFFE8EAF0)),
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