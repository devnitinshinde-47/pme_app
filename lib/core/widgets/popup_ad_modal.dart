import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/system_config_model.dart';

class PopupAdModal extends StatelessWidget {
  final SystemConfigModel config;

  const PopupAdModal({super.key, required this.config});

  static void show(BuildContext context, SystemConfigModel config) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PopupAdModal(config: config),
    );
  }

  Future<void> _handleAction(BuildContext context) async {
    final actionUrl = config.popupAdActionUrl;
    if (actionUrl != null && actionUrl.trim().isNotEmpty) {
      try {
        final uri = Uri.parse(actionUrl.trim());
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = config.popupAdImageUrl;
    final title = config.popupAdTitle;
    final buttonText = config.popupAdButtonText ?? 'Claim Offer';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner Image
                if (imageUrl != null && imageUrl.trim().isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      imageUrl.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primaryLight,
                        child: const Center(
                          child: Icon(Icons.campaign_rounded, size: 48, color: AppColors.primary),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 120,
                    color: AppColors.primaryLight,
                    child: const Center(
                      child: Icon(Icons.campaign_rounded, size: 56, color: AppColors.primary),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (title != null && title.trim().isNotEmpty) ...[
                        Text(
                          title.trim(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => _handleAction(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cancel / Close X Button on Top Right
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
