import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';

/// In-app PDF reader screen using Google Docs Viewer embedded in a WebView.
/// PDFs are streamed directly without downloading to local storage.
class PdfReaderScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String? fileSize;

  const PdfReaderScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.fileSize,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _loadPercent = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Use Google Docs viewer to render PDF inline — no download, no local storage
    final viewerUrl = _buildGoogleDocsViewerUrl(widget.pdfUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() { _isLoading = true; _hasError = false; _loadPercent = 10; });
          },
          onProgress: (progress) {
            if (mounted) setState(() => _loadPercent = progress);
          },
          onPageFinished: (url) {
            if (mounted) setState(() { _isLoading = false; _loadPercent = 100; });
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() { _isLoading = false; _hasError = true; });
            }
          },
          // Prevent any navigation away from the viewer (no external links)
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && (uri.host.contains('docs.google.com') || uri.host.contains('drive.google.com'))) {
              return NavigationDecision.navigate;
            }
            // Block all other navigations
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(viewerUrl));
  }

  String _buildGoogleDocsViewerUrl(String rawPdfUrl) {
    final encoded = Uri.encodeComponent(rawPdfUrl);
    return 'https://docs.google.com/gview?embedded=true&url=$encoded';
  }

  void _reload() {
    setState(() { _hasError = false; _isLoading = true; _loadPercent = 0; });
    _initWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.fileSize != null)
              Text(
                'PDF • ${widget.fileSize}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadPercent / 100.0,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: _hasError
          ? _buildErrorState()
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading) _buildLoadingOverlay(),
              ],
            ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading PDF...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              '$_loadPercent% loaded',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _loadPercent > 0 ? _loadPercent / 100.0 : null,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.broken_image_rounded, color: AppColors.error, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'Unable to Load PDF',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'The document could not be displayed. Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              label: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
