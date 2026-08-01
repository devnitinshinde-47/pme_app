import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

/// Settings Screen — clean, grouped, premium UI following KISS principle.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _lectureReminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── NOTIFICATIONS ────────────────────────────────────────
              _sectionHeader('NOTIFICATIONS'),
              _buildSettingsCard([
                _buildSwitchTile(
                  icon: Icons.notifications_rounded,
                  iconColor: AppColors.primary,
                  title: 'Push Notifications',
                  subtitle: 'Announcements and DPP updates',
                  value: _pushNotifications,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _pushNotifications = val);
                  },
                  showDivider: true,
                ),
                _buildSwitchTile(
                  icon: Icons.alarm_rounded,
                  iconColor: const Color(0xFFFF8C00),
                  title: 'Lecture Reminders',
                  subtitle: 'Notify 15 mins before class starts',
                  value: _lectureReminders,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _lectureReminders = val);
                  },
                  showDivider: false,
                ),
              ]),

              const SizedBox(height: 24),

              // ── GENERAL ──────────────────────────────────────────────
              _sectionHeader('GENERAL'),
              _buildSettingsCard([
                _buildNavTile(
                  icon: Icons.headset_mic_outlined,
                  iconColor: const Color(0xFF00BFA5),
                  title: 'Technical Help & Support',
                  onTap: () => _showHelpDialog(context),
                  showDivider: false,
                ),
              ]),

              const SizedBox(height: 32),

              // ── APP INFO ─────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pawan Mate Education',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: showDivider
              ? const BorderRadius.vertical(top: Radius.circular(16))
              : const BorderRadius.vertical(bottom: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
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
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
