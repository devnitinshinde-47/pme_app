import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pawanmateeducation/features/home/presentation/screens/zoom_web_meeting_screen.dart';
import 'package:pawanmateeducation/core/constants/app_colors.dart';

/// Service that handles joining a Zoom meeting.
///
/// Priority flow:
///   1. If Zoom app is installed → launch `zoomus://` deep link directly.
///   2. If not installed → show branded install-dialog with setup steps,
///      and a "Continue in App" fallback that opens [ZoomWebMeetingScreen].
class ZoomSdkService {
  static final ZoomSdkService _instance = ZoomSdkService._internal();
  factory ZoomSdkService() => _instance;
  ZoomSdkService._internal();

  /// Legacy init stub (no-op – WebSDK / deep-link requires no native init).
  Future<bool> initZoomSdk({
    String domain = 'zoom.us',
    String? appKey,
    String? appSecret,
  }) async {
    return true;
  }

  /// Main entry point – detects Zoom app, deep-links or shows dialog.
  Future<bool> joinNativeMeeting({
    required BuildContext context,
    required String meetingId,
    required String passcode,
    required String displayName,
    String? title,
    String? zakToken,
    String? zoomAccessToken,
    String? meetingUrl,
  }) async {
    final cleanId = meetingId.replaceAll(RegExp(r'[^0-9]'), '');

    // Check whether the official Zoom app can handle zoomus:// links
    final zoomUri = Uri.parse('zoomus://zoom.us/join?confno=$cleanId&pwd=$passcode');
    final bool zoomInstalled = await canLaunchUrl(zoomUri);

    if (zoomInstalled) {
      // ── Path A: Launch official Zoom app ────────────────────────────────
      try {
        await launchUrl(zoomUri, mode: LaunchMode.externalApplication);
        return true;
      } catch (_) {
        // Fall through to dialog/web fallback
      }
    }

    // ── Path B: Zoom not installed – show branded dialog ─────────────────
    if (context.mounted) {
      await _showZoomInstallDialog(
        context: context,
        meetingId: cleanId,
        passcode: passcode,
        displayName: displayName,
        meetingUrl: meetingUrl,
        title: title,
      );
    }
    return true;
  }

  // ── Private: branded dialog ─────────────────────────────────────────────

  Future<void> _showZoomInstallDialog({
    required BuildContext context,
    required String meetingId,
    required String passcode,
    required String displayName,
    String? meetingUrl,
    String? title,
  }) async {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _ZoomInstallDialog(
        meetingId: meetingId,
        passcode: passcode,
        displayName: displayName,
        meetingUrl: meetingUrl,
        title: title,
      ),
    );
  }
}

// ── Branded Install Dialog Widget ────────────────────────────────────────────

class _ZoomInstallDialog extends StatelessWidget {
  final String meetingId;
  final String passcode;
  final String displayName;
  final String? meetingUrl;
  final String? title;

  const _ZoomInstallDialog({
    required this.meetingId,
    required this.passcode,
    required this.displayName,
    this.meetingUrl,
    this.title,
  });

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=us.zoom.videomeetings';

  static const _steps = [
    ('Install', 'Download Zoom from the Play Store.'),
    ('Sign in', 'Open Zoom and sign in or create a free account.'),
    ('Join', 'Tap "Join a Meeting", enter the Meeting ID & passcode.'),
    ('Allow', 'Grant microphone & camera access when prompted.'),
  ];

  void _openPlayStore() {
    launchUrl(Uri.parse(_playStoreUrl), mode: LaunchMode.externalApplication);
  }

  void _continueInApp(BuildContext context) {
    Navigator.of(context).pop(); // close dialog
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ZoomWebMeetingScreen(
          meetingId: meetingId,
          passcode: passcode,
          displayName: displayName,
          meetingUrl: meetingUrl,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Zoom icon placeholder with brand style
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.video_camera_front_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Zoom App Not Installed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Install the Zoom app for the best live-class experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ── Setup steps ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Setup',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._steps.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$idx',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${step.$1}  ',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextSpan(
                                    text: step.$2,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Buttons ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openPlayStore,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Install Zoom'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // ── Fallback link ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: GestureDetector(
                onTap: () => _continueInApp(context),
                child: Text(
                  'or continue in Pawan Mate Education app →',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
