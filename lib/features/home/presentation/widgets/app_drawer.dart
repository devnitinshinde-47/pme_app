import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../auth/data/models/user_model.dart';

/// Professional, UI/UX-friendly Left Navigation Drawer for Pawan Mate Education.
/// Follows the KISS principle with grouped menu sections, elegant profile header,
/// and smooth interactive touch targets.
class AppDrawer extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final studentName = user?.name?.isNotEmpty == true ? user!.name! : 'Student';
    final mobileNumber = user?.mobileNumber.isNotEmpty == true ? '+91 ${user!.mobileNumber}' : '+91 9876543210';

    return Drawer(
      backgroundColor: AppColors.surface,
      elevation: 4,
      child: Column(
        children: [
          // Elegant Header Area (Profile & App Branding)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 56, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'PAWAN MATE EDUCATION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Student Profile Row
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.profile, arguments: user);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      // Profile Avatar
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: Text(
                            studentName.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Name & Phone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mobileNumber,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Menu Body List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: LEARNING & ANALYTICS
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, top: 8.0, bottom: 6.0),
                    child: Text(
                      'LEARNING & ANALYTICS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  _buildDrawerTile(
                    context,
                    icon: Icons.donut_large_rounded,
                    title: 'My Progress',
                    subtitle: 'Completion stats & charts',
                    iconColor: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.myProgress);
                    },
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, indent: 8, endIndent: 8),
                  const SizedBox(height: 14),

                  // SECTION 2: ACCOUNT & PREFERENCES
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 6.0),
                    child: Text(
                      'ACCOUNT & PREFERENCES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  _buildDrawerTile(
                    context,
                    icon: Icons.person_outline_rounded,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.profile, arguments: user);
                    },
                  ),

                  _buildDrawerTile(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                  ),

                  _buildDrawerTile(
                    context,
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.pop(context);
                      launchUrl(
                        Uri.parse('https://www.pawanmateeducation.tech/privacy-policy'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),

                  _buildDrawerTile(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () {
                      Navigator.pop(context);
                      launchUrl(
                        Uri.parse('https://www.pawanmateeducation.tech/terms-conditions'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, indent: 8, endIndent: 8),
                  const SizedBox(height: 14),

                  // SECTION 3: SUPPORT
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 6.0),
                    child: Text(
                      'SUPPORT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),

                  _buildDrawerTile(
                    context,
                    icon: Icons.headset_mic_outlined,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Footer Logout Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Pawan Mate Education • v1.0.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final color = iconColor ?? AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
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
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.headset_mic_outlined, color: Color(0xFF00BFA5), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Technical Help & Support',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For any technical issues, bugs, or app-related assistance, contact our developer:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            // WhatsApp contact
            InkWell(
              onTap: () async {
                final message = Uri.encodeComponent(
                  'Hello Nitin, I need technical help with the Pawan Mate Education app.',
                );
                final whatsappUri = Uri.parse('https://wa.me/919834525980?text=$message');
                await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nitin Shinde', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          SizedBox(height: 2),
                          Text('WhatsApp: 9834525980', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Email contact
            InkWell(
              onTap: () async {
                final emailUri = Uri.parse('mailto:devnitinshinde@gmail.com?subject=Pawan Mate Education App - Technical Support');
                await launchUrl(emailUri, mode: LaunchMode.externalApplication);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          SizedBox(height: 2),
                          Text('devnitinshinde@gmail.com', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'WhatsApp messages only • Response within 24 hours',
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
