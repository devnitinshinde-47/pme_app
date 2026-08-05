import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';

/// Embedded Cloudflare R2 / CDN HTML5 Video Player using webview_flutter.
/// Supports HLS master playlists, responsive 16:9 aspect ratio playback, and loading indicators.
class BunnyStreamPlayer extends StatefulWidget {
  final String videoUrlOrId;
  final String title;
  final String? duration;
  final VoidCallback? onClose;

  const BunnyStreamPlayer({
    super.key,
    required this.videoUrlOrId,
    required this.title,
    this.duration,
    this.onClose,
  });

  static String buildEmbedUrl(String rawUrlOrId) {
    return rawUrlOrId;
  }

  @override
  State<BunnyStreamPlayer> createState() => _BunnyStreamPlayerState();
}

class _BunnyStreamPlayerState extends State<BunnyStreamPlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  String _buildHlsHtml(String videoUrl) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <script src="https://cdn.jsdelivr.net/npm/hls.js@1.5.8/dist/hls.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: #000; color: #fff; }
    #playerContainer { position: relative; width: 100vw; height: 100vh; display: flex; align-items: center; justify-content: center; background: #000; overflow: hidden; }
    video { width: 100%; height: 100%; object-fit: contain; background: #000; }
    
    .center-controls {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      display: flex;
      align-items: center;
      gap: 18px;
      z-index: 30;
      transition: opacity 0.25s ease, visibility 0.25s ease;
      opacity: 1;
      visibility: visible;
    }
    .center-controls.hidden { opacity: 0; visibility: hidden; pointer-events: none; }

    .center-btn {
      background: rgba(15, 23, 42, 0.75);
      border: 1px solid rgba(255, 255, 255, 0.25);
      backdrop-filter: blur(8px);
      color: #fff;
      border-radius: 50%;
      cursor: pointer;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      width: 36px;
      height: 36px;
    }
    .center-btn.big-play {
      width: 48px;
      height: 48px;
      background: rgba(37, 99, 235, 0.9);
      border: 1.5px solid rgba(255, 255, 255, 0.4);
    }
    .center-btn.big-play svg { width: 24px; height: 24px; }
    .skip-label { font-size: 8px; font-weight: 800; }

    .buffering-spinner {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      z-index: 35;
      display: none;
      align-items: center;
      justify-content: center;
    }
    .spinner-ring {
      width: 44px;
      height: 44px;
      border: 3.5px solid rgba(255, 255, 255, 0.2);
      border-top-color: #38bdf8;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

    .controls-overlay {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      padding: 10px 14px max(10px, env(safe-area-inset-bottom));
      background: linear-gradient(to top, rgba(0,0,0,0.9), rgba(0,0,0,0.4) 70%, transparent);
      z-index: 30;
      display: flex;
      flex-direction: column;
      gap: 6px;
      transition: opacity 0.25s ease, visibility 0.25s ease;
      opacity: 1;
      visibility: visible;
    }
    .controls-overlay.hidden { opacity: 0; visibility: hidden; pointer-events: none; }

    .progress-bar-container { width: 100%; height: 12px; padding: 3px 0; cursor: pointer; display: flex; align-items: center; }
    .progress-bar-bg { width: 100%; height: 4px; background: rgba(255,255,255,0.3); border-radius: 2px; overflow: hidden; }
    .progress-bar-filled { height: 100%; background: #2563eb; border-radius: 2px; width: 0%; }
    .bottom-row { display: flex; justify-content: space-between; align-items: center; }
    .left-controls, .right-controls { display: flex; align-items: center; gap: 8px; }
    .btn { background: none; border: none; color: #fff; cursor: pointer; padding: 4px; }
    svg { width: 16px; height: 16px; fill: currentColor; }
  </style>
</head>
<body>
  <div id="playerContainer">
    <video id="videoPlayer" playsinline autoplay></video>

    <div class="center-controls" id="centerControls">
      <button class="center-btn" id="skipBackBtn"><span class="skip-label">-10s</span></button>
      <button class="center-btn big-play" id="centerPlayBtn">
        <svg id="centerPlayIcon" viewBox="0 0 24 24" style="display:block;"><path d="M8 5v14l11-7z"/></svg>
        <svg id="centerPauseIcon" viewBox="0 0 24 24" style="display:none;"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>
      </button>
      <button class="center-btn" id="skipFwdBtn"><span class="skip-label">+10s</span></button>
    </div>

    <div class="buffering-spinner" id="bufferingSpinner"><div class="spinner-ring"></div></div>

    <div class="controls-overlay" id="controlsOverlay">
      <div class="progress-bar-container" id="progressContainer">
        <div class="progress-bar-bg"><div class="progress-bar-filled" id="progressFilled"></div></div>
      </div>
      <div class="bottom-row">
        <div class="left-controls">
          <button class="btn" id="playBtn">
            <svg id="playIcon" viewBox="0 0 24 24" style="display:block;"><path d="M8 5v14l11-7z"/></svg>
            <svg id="pauseIcon" viewBox="0 0 24 24" style="display:none;"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>
          </button>
        </div>
        <div class="right-controls">
          <button class="btn" id="fullscreenBtn" title="Wide Angle / Fullscreen">
            <svg viewBox="0 0 24 24"><path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/></svg>
          </button>
        </div>
      </div>
    </div>
  </div>

  <script>
    (function() {
      var playerContainer = document.getElementById('playerContainer');
      var video = document.getElementById('videoPlayer');
      var centerControls = document.getElementById('centerControls');
      var controlsOverlay = document.getElementById('controlsOverlay');
      var playBtn = document.getElementById('playBtn');
      var playIcon = document.getElementById('playIcon');
      var pauseIcon = document.getElementById('pauseIcon');
      var centerPlayBtn = document.getElementById('centerPlayBtn');
      var centerPlayIcon = document.getElementById('centerPlayIcon');
      var centerPauseIcon = document.getElementById('centerPauseIcon');
      var skipBackBtn = document.getElementById('skipBackBtn');
      var skipFwdBtn = document.getElementById('skipFwdBtn');
      var bufferingSpinner = document.getElementById('bufferingSpinner');
      var fullscreenBtn = document.getElementById('fullscreenBtn');
      var progressContainer = document.getElementById('progressContainer');
      var progressFilled = document.getElementById('progressFilled');

      var videoUrl = "$videoUrl";
      var hideTimeout = null;

      function showControls() {
        centerControls.classList.remove('hidden');
        controlsOverlay.classList.remove('hidden');

        clearTimeout(hideTimeout);
        if (!video.paused) {
          hideTimeout = setTimeout(function() {
            centerControls.classList.add('hidden');
            controlsOverlay.classList.add('hidden');
          }, 3000);
        }
      }

      playerContainer.onclick = function(e) {
        if (e.target.closest('.center-btn') || e.target.closest('.btn') || e.target.closest('.progress-bar-container')) {
          showControls();
          return;
        }

        if (controlsOverlay.classList.contains('hidden')) {
          showControls();
        } else {
          centerControls.classList.add('hidden');
          controlsOverlay.classList.add('hidden');
        }
      };

      function togglePlay() {
        if (video.paused) { video.play(); } else { video.pause(); }
        showControls();
      }

      playBtn.onclick = function(e) { e.stopPropagation(); togglePlay(); };
      centerPlayBtn.onclick = function(e) { e.stopPropagation(); togglePlay(); };

      skipBackBtn.onclick = function(e) {
        e.stopPropagation();
        bufferingSpinner.style.display = "flex";
        video.currentTime = Math.max(0, video.currentTime - 10);
        showControls();
      };

      skipFwdBtn.onclick = function(e) {
        e.stopPropagation();
        bufferingSpinner.style.display = "flex";
        video.currentTime = Math.min(video.duration || 0, video.currentTime + 10);
        showControls();
      };

      fullscreenBtn.onclick = function(e) {
        e.stopPropagation();
        if (window.OrientationChannel && window.OrientationChannel.postMessage) {
          window.OrientationChannel.postMessage('toggleFullscreen');
        }
        showControls();
      };

      video.onseeking = function() { bufferingSpinner.style.display = "flex"; };
      video.onwaiting = function() { bufferingSpinner.style.display = "flex"; };
      video.onseeked = function() { bufferingSpinner.style.display = "none"; };
      video.onplaying = function() { bufferingSpinner.style.display = "none"; };
      video.oncanplay = function() { bufferingSpinner.style.display = "none"; };

      video.onplay = function() {
        playIcon.style.display = "none"; pauseIcon.style.display = "block";
        centerPlayIcon.style.display = "none"; centerPauseIcon.style.display = "block";
        showControls();
      };

      video.onpause = function() {
        playIcon.style.display = "block"; pauseIcon.style.display = "none";
        centerPlayIcon.style.display = "block"; centerPauseIcon.style.display = "none";
        showControls();
      };

      video.ontimeupdate = function() {
        if (video.duration) {
          progressFilled.style.width = ((video.currentTime / video.duration) * 100) + "%";
        }
      };

      progressContainer.onclick = function(e) {
        e.stopPropagation();
        var rect = progressContainer.getBoundingClientRect();
        var pos = (e.clientX - rect.left) / rect.width;
        bufferingSpinner.style.display = "flex";
        video.currentTime = pos * video.duration;
        showControls();
      };

      if (Hls.isSupported()) {
        var hls = new Hls({ enableWorker: true, lowLatencyMode: true });
        hls.loadSource(videoUrl);
        hls.attachMedia(video);
        hls.on(Hls.Events.MANIFEST_PARSED, function() { video.play().catch(function(){}); });
      } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = videoUrl;
        video.play().catch(function(){});
      } else {
        video.src = videoUrl;
      }

      showControls();
    })();
  </script>
</body>
</html>
''';
  }

  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.videoUrlOrId;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'OrientationChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'enterFullscreen') {
            _enterFullscreen();
          } else if (message.message == 'exitFullscreen') {
            _exitFullscreen();
          } else if (message.message == 'toggleFullscreen') {
            _toggleFullscreen();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
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
                _hasError = true;
              });
            }
          },
        ),
      );

    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      _controller.loadHtmlString(_buildHlsHtml(videoUrl));
    } else {
      _controller.loadHtmlString(_buildHlsHtml('https://test-streams.mux.dev/x36xhtml/x36xhtml.m3u8'));
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _enterFullscreen() {
    if (!mounted || _isFullscreen) return;
    setState(() {
      _isFullscreen = true;
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    if (!mounted) return;
    if (_isFullscreen) {
      setState(() {
        _isFullscreen = false;
      });
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppStyles.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.duration != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.duration!,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),

            // Video Player Container (16:9 aspect ratio)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  if (!_hasError)
                    WebViewWidget(controller: _controller),

                  if (_hasError)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Failed to load video stream',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _hasError = false;
                              });
                              final videoUrl = widget.videoUrlOrId;
                              if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
                                _controller.loadHtmlString(_buildHlsHtml(videoUrl));
                              } else {
                                _controller.loadHtmlString(_buildHlsHtml('https://test-streams.mux.dev/x36xhtml/x36xhtml.m3u8'));
                              }
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_isLoading && !_hasError)
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
