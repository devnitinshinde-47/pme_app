import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';

/// Privacy Policy Screen displaying student data privacy guidelines.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: AppStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Privacy & Student Data Safety',
                  style: AppStyles.headingMedium,
                ),
                SizedBox(height: 12),
                Text(
                  'Pawan Mate Education is committed to protecting the privacy of all students and users.',
                  style: AppStyles.bodyMedium,
                ),
                SizedBox(height: 16),
                Text(
                  '1. Mobile Number & Verification',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Your mobile number is solely used for authenticating your student account and delivering 6-digit OTP verification codes.',
                  style: AppStyles.bodyMedium,
                ),
                SizedBox(height: 14),
                Text(
                  '2. Data Protection',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'We do not sell, rent, or share student personal data with third-party advertising companies.',
                  style: AppStyles.bodyMedium,
                ),
                SizedBox(height: 20),
                Text(
                  'Last Updated: August 2026',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
