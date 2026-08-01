import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../../../core/constants/app_colors.dart';

/// Theme-aligned In-App Zoom Web Meeting Screen for Pawan Mate Education.
/// Renders Zoom live lectures with brand theme styling (Navy & Orange)
/// with full microphone & camera permissions enabled inside the WebView.
class ZoomWebMeetingScreen extends StatefulWidget {
  final String meetingId;
  final String passcode;
  final String displayName;
  final String? meetingUrl;
  final String? title;

  const ZoomWebMeetingScreen({
    super.key,
    required this.meetingId,
    required this.passcode,
    required this.displayName,
    this.meetingUrl,
    this.title,
  });

  @override
  State<ZoomWebMeetingScreen> createState() => _ZoomWebMeetingScreenState();
}

class _ZoomWebMeetingScreenState extends State<ZoomWebMeetingScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  String? _errorMessage;
  late String _resolvedUrl;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = _buildCanonicalZoomUrl(widget.meetingId, widget.passcode, widget.displayName, widget.meetingUrl);
    _requestMediaPermissions();
    _initWebViewController();
  }

  /// Request runtime camera and microphone permissions for the Android device
  Future<void> _requestMediaPermissions() async {
    try {
      await [
        Permission.microphone,
        Permission.camera,
      ].request();
    } catch (_) {}
  }

  /// Builds a canonical, rock-solid public Zoom Web Client URL
  static String _buildCanonicalZoomUrl(
    String rawMeetingId,
    String rawPasscode,
    String rawDisplayName,
    String? rawMeetingUrl,
  ) {
    final cleanId = rawMeetingId.replaceAll(RegExp(r'[^0-9]'), '');
    final nameEncoded = Uri.encodeComponent(
      rawDisplayName.isNotEmpty ? rawDisplayName : 'Student',
    );

    // Extract passcode from rawPasscode or meetingUrl query params if missing
    String passcode = rawPasscode.trim();
    if (passcode.isEmpty && rawMeetingUrl != null && rawMeetingUrl.contains('pwd=')) {
      try {
        final uri = Uri.parse(rawMeetingUrl);
        passcode = uri.queryParameters['pwd'] ?? '';
      } catch (_) {}
    }

    // Standard public Zoom Web Client join endpoint
    if (cleanId.isNotEmpty) {
      if (passcode.isNotEmpty) {
        return 'https://zoom.us/wc/join/$cleanId?pwd=$passcode&dn=$nameEncoded';
      }
      return 'https://zoom.us/wc/join/$cleanId?dn=$nameEncoded';
    }

    // Fallback if meetingId is missing but meetingUrl exists
    if (rawMeetingUrl != null && rawMeetingUrl.isNotEmpty) {
      String url = rawMeetingUrl;
      // Convert internal/subdomain hosts like us05web.zoom.us/j/... to public zoom.us/wc/join/...
      if (url.contains('zoom.us')) {
        url = url.replaceAll(RegExp(r'https://[a-zA-Z0-9_-]+\.zoom\.us/j/'), 'https://zoom.us/wc/join/');
        url = url.replaceAll(RegExp(r'https://[a-zA-Z0-9_-]+\.zoom\.us/wc/join/'), 'https://zoom.us/wc/join/');
        if (!url.contains('dn=')) {
          url += (url.contains('?') ? '&' : '?') + 'dn=$nameEncoded';
        }
      }
      return url;
    }

    return 'https://zoom.us/wc/join/$cleanId?dn=$nameEncoded';
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.primaryDark)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                _errorMessage = _getFriendlyErrorMessage(error.description);
              });
            }
          },
        ),
      );

    // Grant Android WebView microphone and camera permission requests automatically
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController).setOnPlatformPermissionRequest(
        (request) {
          request.grant();
        },
      );
    }

    _controller.loadRequest(Uri.parse(_resolvedUrl));
  }

  String _getFriendlyErrorMessage(String rawDescription) {
    if (rawDescription.contains('ERR_NAME_NOT_RESOLVED') || rawDescription.contains('ERR_INTERNET_DISCONNECTED')) {
      return 'Unable to reach Zoom servers. Please check your internet connection and try again.';
    }
    if (rawDescription.contains('ERR_CONNECTION_REFUSED') || rawDescription.contains('ERR_TIMED_OUT')) {
      return 'Connection timed out while joining the live class. Please tap retry below.';
    }
    return 'Could not load live class ($rawDescription).';
  }

  void _retryLoading() {
    setState(() {
      _retryCount++;
      _isLoading = true;
      _errorMessage = null;
      if (_retryCount > 1 && widget.meetingId.isNotEmpty) {
        final cleanId = widget.meetingId.replaceAll(RegExp(r'[^0-9]'), '');
        _resolvedUrl = 'https://zoom.us/j/$cleanId?pwd=${widget.passcode}';
      }
    });
    _controller.loadRequest(Uri.parse(_resolvedUrl));
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.title ?? 'Live Lecture Class';

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shadowColor: AppColors.primaryDark.withValues(alpha: 0.5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          tooltip: 'Exit Live Class',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    displayTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'ID: ${widget.meetingId}  •  Pawan Mate Education',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            tooltip: 'Reload Class',
            onPressed: _retryLoading,
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3.0),
                child: LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress : null,
                  backgroundColor: AppColors.primaryDark,
                  color: AppColors.accent,
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_errorMessage != null)
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.video_camera_front_rounded,
                          color: AppColors.accent,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _retryLoading,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
