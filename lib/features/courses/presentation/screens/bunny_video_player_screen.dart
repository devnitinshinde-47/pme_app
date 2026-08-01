import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository.dart';

/// Fullscreen Dedicated Video Player Screen.
/// Plays video lectures and automatically fetches attached lecture PDF notes by videoId.
class BunnyVideoPlayerScreen extends StatefulWidget {
  final LectureModel lecture;
  final String courseName;
  final String? courseId;
  final CourseRepository? repository;

  const BunnyVideoPlayerScreen({
    super.key,
    required this.lecture,
    required this.courseName,
    this.courseId,
    this.repository,
  });

  @override
  State<BunnyVideoPlayerScreen> createState() => _BunnyVideoPlayerScreenState();
}

class _BunnyVideoPlayerScreenState extends State<BunnyVideoPlayerScreen> {
  late final WebViewController _controller;
  late final CourseRepository _repository;

  bool _isLoading = true;
  bool _hasError = false;
  NoteModel? _attachedNote;
  bool _isLoadingNote = false;
  bool _isCompleted = false;
  bool _isTogglingProgress = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CourseRepository();
    _attachedNote = widget.lecture.note;
    _isCompleted = widget.lecture.isCompleted;
    _checkVideoProgress();

    final rawVideoUrl = widget.lecture.videoUrl ?? '';
    final thumbnailUrl = widget.lecture.thumbnailUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
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

    if (rawVideoUrl.startsWith('http://') || rawVideoUrl.startsWith('https://')) {
      _controller.loadHtmlString(_buildHlsPlayerHtml(rawVideoUrl, thumbnailUrl));
    } else {
      _controller.loadHtmlString(_buildHlsPlayerHtml('https://test-streams.mux.dev/x36xhtml/x36xhtml.m3u8', thumbnailUrl));
    }

    // Fetch note by videoId if not already attached directly
    if (_attachedNote == null && widget.courseId != null && widget.courseId!.isNotEmpty) {
      _fetchAttachedNoteByVideoId();
    }
  }

  Future<void> _checkVideoProgress() async {
    if (widget.courseId != null && widget.courseId!.isNotEmpty) {
      final progress = await _repository.getCourseProgress(widget.courseId!);
      if (progress != null && mounted) {
        setState(() {
          _isCompleted = progress.completedVideoIds.contains(widget.lecture.id) || widget.lecture.isCompleted;
        });
      }
    }
  }

  Future<void> _toggleCompletion() async {
    setState(() => _isTogglingProgress = true);
    final newStatus = !_isCompleted;

    if (widget.courseId == null || widget.courseId!.isEmpty) {
      setState(() {
        _isCompleted = newStatus;
        _isTogglingProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isCompleted ? 'Lecture marked as completed! 🎉' : 'Lecture marked as incomplete.'),
          backgroundColor: _isCompleted ? AppColors.success : AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updated = await _repository.toggleVideoProgress(
      widget.courseId!,
      widget.lecture.id,
      newStatus,
    );

    if (mounted) {
      setState(() {
        _isCompleted = updated != null
            ? updated.completedVideoIds.contains(widget.lecture.id)
            : newStatus;
        _isTogglingProgress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isCompleted ? 'Lecture marked as completed! 🎉' : 'Lecture marked as incomplete.'),
          backgroundColor: _isCompleted ? AppColors.success : AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchAttachedNoteByVideoId() async {
    setState(() => _isLoadingNote = true);
    try {
      final note = await _repository.getNoteForVideo(widget.courseId!, widget.lecture.id);
      if (!mounted) return;
      setState(() {
        _attachedNote = note;
        _isLoadingNote = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingNote = false);
    }
  }

  String _buildHlsPlayerHtml(String videoUrl, String? posterUrl) {
    final poster = posterUrl ?? '';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Cloudflare R2 Adaptive HLS Player</title>
  <script src="https://cdn.jsdelivr.net/npm/hls.js@1.5.8/dist/hls.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: #000; color: #fff; }
    #playerContainer { position: relative; width: 100vw; height: 100vh; display: flex; align-items: center; justify-content: center; background: #000; overflow: hidden; }
    video { width: 100%; height: 100%; object-fit: contain; background: #000; }
    
    /* Top Bar */
    .top-bar {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      padding: 12px 16px max(12px, env(safe-area-inset-top));
      background: linear-gradient(to bottom, rgba(0,0,0,0.85), transparent);
      display: flex;
      justify-content: space-between;
      align-items: center;
      z-index: 30;
      transition: opacity 0.25s ease, visibility 0.25s ease;
      opacity: 1;
      visibility: visible;
    }
    .top-bar.hidden { opacity: 0; visibility: hidden; pointer-events: none; }
    .video-title { font-size: 13px; font-weight: 600; color: #fff; text-shadow: 0 1px 3px rgba(0,0,0,0.8); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 85%; }

    /* Compact Center Controls Overlay */
    .center-controls {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      display: flex;
      align-items: center;
      gap: 20px;
      z-index: 30;
      pointer-events: auto;
      transition: opacity 0.25s ease, visibility 0.25s ease;
      opacity: 1;
      visibility: visible;
    }
    .center-controls.hidden { opacity: 0; visibility: hidden; pointer-events: none; }

    .center-btn {
      background: rgba(15, 23, 42, 0.75);
      border: 1px solid rgba(255, 255, 255, 0.25);
      backdrop-filter: blur(10px);
      color: #fff;
      border-radius: 50%;
      cursor: pointer;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      transition: all 0.2s ease;
      width: 38px;
      height: 38px;
    }
    .center-btn.big-play {
      width: 52px;
      height: 52px;
      background: rgba(37, 99, 235, 0.9);
      border: 1.5px solid rgba(255, 255, 255, 0.4);
      box-shadow: 0 0 16px rgba(37, 99, 235, 0.6);
    }
    .center-btn.big-play svg {
      width: 26px;
      height: 26px;
    }
    .center-btn:hover {
      transform: scale(1.1);
      background: rgba(37, 99, 235, 1);
    }
    .skip-label {
      font-size: 8px;
      font-weight: 800;
      margin-top: -1px;
    }

    /* Buffering Spinner */
    .buffering-spinner {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      z-index: 35;
      display: none;
      align-items: center;
      justify-content: center;
      pointer-events: none;
    }
    .spinner-ring {
      width: 46px;
      height: 46px;
      border: 3.5px solid rgba(255, 255, 255, 0.2);
      border-top-color: #38bdf8;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

    /* Bottom Controls Overlay (Fixed for Vertical & Fullscreen Mode) */
    .controls-overlay {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      padding: 12px 16px max(12px, env(safe-area-inset-bottom));
      background: linear-gradient(to top, rgba(0,0,0,0.9), rgba(0,0,0,0.4) 70%, transparent);
      z-index: 30;
      display: flex;
      flex-direction: column;
      gap: 8px;
      transition: opacity 0.25s ease, visibility 0.25s ease;
      opacity: 1;
      visibility: visible;
    }
    .controls-overlay.hidden { opacity: 0; visibility: hidden; pointer-events: none; }
    
    .progress-bar-container {
      width: 100%;
      height: 14px;
      padding: 4px 0;
      cursor: pointer;
      position: relative;
      display: flex;
      align-items: center;
    }
    .progress-bar-bg {
      width: 100%;
      height: 5px;
      background: rgba(255,255,255,0.3);
      border-radius: 3px;
      position: relative;
      overflow: hidden;
    }
    .progress-bar-filled {
      height: 100%;
      background: #2563eb;
      border-radius: 3px;
      width: 0%;
      transition: width 0.1s linear;
    }

    .bottom-row { display: flex; justify-content: space-between; align-items: center; }
    .left-controls { display: flex; align-items: center; gap: 10px; }
    .right-controls { display: flex; align-items: center; gap: 10px; }

    .btn { background: none; border: none; color: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; padding: 6px; border-radius: 50%; font-size: 13px; }
    .btn:hover { background: rgba(255,255,255,0.2); }
    .time-text { font-size: 11.5px; font-weight: 500; color: #e2e8f0; }

    .menu-popup { position: absolute; bottom: 56px; right: 16px; background: rgba(15, 23, 42, 0.95); border: 1px solid rgba(255,255,255,0.15); backdrop-filter: blur(10px); border-radius: 12px; padding: 8px; width: 210px; display: none; flex-direction: column; gap: 4px; z-index: 40; box-shadow: 0 10px 25px rgba(0,0,0,0.5); max-height: 240px; overflow-y: auto; }
    .menu-title { font-size: 10.5px; font-weight: 700; color: #94a3b8; text-transform: uppercase; padding: 6px 8px; border-bottom: 1px solid rgba(255,255,255,0.1); margin-bottom: 4px; }
    .menu-item { font-size: 12.5px; font-weight: 600; padding: 7px 10px; border-radius: 6px; color: #cbd5e1; cursor: pointer; display: flex; justify-content: space-between; align-items: center; }
    .menu-item:hover { background: rgba(255,255,255,0.1); color: #fff; }
    .menu-item.active { color: #38bdf8; background: rgba(56, 189, 248, 0.15); }

    svg { width: 18px; height: 18px; fill: currentColor; }
  </style>
</head>
<body>
  <div id="playerContainer">
    <video id="videoPlayer" playsinline poster="$poster" autoplay></video>

    <!-- Compact Center Play/Pause & -10s / +10s Controls -->
    <div class="center-controls" id="centerControls">
      <button class="center-btn" id="skipBackBtn" title="Rewind 10s">
        <svg viewBox="0 0 24 24"><path d="M11 18V6l-8.5 6 8.5 6zm.5-6l8.5 6V6l-8.5 6z"/></svg>
        <span class="skip-label">-10s</span>
      </button>
      
      <button class="center-btn big-play" id="centerPlayBtn" title="Play / Pause">
        <svg id="centerPlayIcon" viewBox="0 0 24 24" style="display:block;"><path d="M8 5v14l11-7z"/></svg>
        <svg id="centerPauseIcon" viewBox="0 0 24 24" style="display:none;"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>
      </button>

      <button class="center-btn" id="skipFwdBtn" title="Forward 10s">
        <svg viewBox="0 0 24 24"><path d="M4 18l8.5-6L4 6v12zm9-12v12l8.5-6-8.5-6z"/></svg>
        <span class="skip-label">+10s</span>
      </button>
    </div>

    <!-- Buffering Spinner -->
    <div class="buffering-spinner" id="bufferingSpinner">
      <div class="spinner-ring"></div>
    </div>

    <!-- Bottom Controls Overlay (Always Visible in Vertical/Landscape) -->
    <div class="controls-overlay" id="controlsOverlay">
      <div class="progress-bar-container" id="progressContainer">
        <div class="progress-bar-bg">
          <div class="progress-bar-filled" id="progressFilled"></div>
        </div>
      </div>
      <div class="bottom-row">
        <div class="left-controls">
          <button class="btn" id="playBtn">
            <svg id="playIcon" viewBox="0 0 24 24" style="display:block;"><path d="M8 5v14l11-7z"/></svg>
            <svg id="pauseIcon" viewBox="0 0 24 24" style="display:none;"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>
          </button>
          <span class="time-text"><span id="currTime">00:00</span> / <span id="durTime">00:00</span></span>
        </div>
        <div class="right-controls">
          <button class="btn" id="speedBtn" title="Playback Speed" style="font-size:11px; font-weight:700;">1x</button>
          <button class="btn" id="qualityBtn" title="Video Quality">
            <svg viewBox="0 0 24 24"><path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/></svg>
          </button>
          <button class="btn" id="fullscreenBtn" title="Wide Angle / Fullscreen">
            <svg viewBox="0 0 24 24"><path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/></svg>
          </button>
        </div>
      </div>
    </div>

    <div class="menu-popup" id="qualityMenu">
      <div class="menu-title">Quality Control</div>
      <div id="qualityList"></div>
    </div>

    <div class="menu-popup" id="speedMenu">
      <div class="menu-title">Playback Speed</div>
      <div class="menu-item" data-speed="0.5">0.5x</div>
      <div class="menu-item" data-speed="0.75">0.75x</div>
      <div class="menu-item active" data-speed="1.0">1.0x (Normal)</div>
      <div class="menu-item" data-speed="1.25">1.25x</div>
      <div class="menu-item" data-speed="1.5">1.5x</div>
      <div class="menu-item" data-speed="2.0">2.0x</div>
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
      var currTime = document.getElementById('currTime');
      var durTime = document.getElementById('durTime');
      var speedBtn = document.getElementById('speedBtn');
      var qualityBtn = document.getElementById('qualityBtn');
      var qualityMenu = document.getElementById('qualityMenu');
      var speedMenu = document.getElementById('speedMenu');
      var qualityList = document.getElementById('qualityList');

      var hls = null;
      var videoUrl = "$videoUrl";
      var hideTimeout = null;

      function showControls() {
        centerControls.classList.remove('hidden');
        controlsOverlay.classList.remove('hidden');

        clearTimeout(hideTimeout);
        if (!video.paused) {
          hideTimeout = setTimeout(function() {
            if (qualityMenu.style.display !== "flex" && speedMenu.style.display !== "flex") {
              centerControls.classList.add('hidden');
              controlsOverlay.classList.add('hidden');
            }
          }, 3000);
        }
      }

      playerContainer.onclick = function(e) {
        if (e.target.closest('.center-btn') || e.target.closest('.btn') || e.target.closest('.menu-popup') || e.target.closest('.progress-bar-container')) {
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

      function fmtTime(sec) {
        if (isNaN(sec)) return "00:00";
        var m = Math.floor(sec / 60);
        var s = Math.floor(sec % 60);
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
      }

      function togglePlay() {
        if (video.paused) {
          video.play();
        } else {
          video.pause();
        }
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
        if (!document.fullscreenElement && !document.webkitFullscreenElement) {
          if (playerContainer.requestFullscreen) { playerContainer.requestFullscreen(); }
          else if (playerContainer.webkitRequestFullscreen) { playerContainer.webkitRequestFullscreen(); }
        } else {
          if (document.exitFullscreen) { document.exitFullscreen(); }
          else if (document.webkitExitFullscreen) { document.webkitExitFullscreen(); }
        }
        showControls();
      };

      video.onseeking = function() { bufferingSpinner.style.display = "flex"; };
      video.onwaiting = function() { bufferingSpinner.style.display = "flex"; };
      video.onseeked = function() { bufferingSpinner.style.display = "none"; };
      video.onplaying = function() { bufferingSpinner.style.display = "none"; };
      video.oncanplay = function() { bufferingSpinner.style.display = "none"; };

      video.onplay = function() {
        playIcon.style.display = "none";
        pauseIcon.style.display = "block";
        centerPlayIcon.style.display = "none";
        centerPauseIcon.style.display = "block";
        showControls();
      };

      video.onpause = function() {
        playIcon.style.display = "block";
        pauseIcon.style.display = "none";
        centerPlayIcon.style.display = "block";
        centerPauseIcon.style.display = "none";
        showControls();
      };

      video.ontimeupdate = function() {
        currTime.innerText = fmtTime(video.currentTime);
        durTime.innerText = fmtTime(video.duration);
        if (video.duration) {
          var pct = (video.currentTime / video.duration) * 100;
          progressFilled.style.width = pct + "%";
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

      qualityBtn.onclick = function(e) {
        e.stopPropagation();
        speedMenu.style.display = "none";
        qualityMenu.style.display = qualityMenu.style.display === "flex" ? "none" : "flex";
        showControls();
      };

      speedBtn.onclick = function(e) {
        e.stopPropagation();
        qualityMenu.style.display = "none";
        speedMenu.style.display = speedMenu.style.display === "flex" ? "none" : "flex";
        showControls();
      };

      speedMenu.querySelectorAll('.menu-item').forEach(function(item) {
        item.onclick = function(e) {
          e.stopPropagation();
          var spd = parseFloat(item.getAttribute('data-speed'));
          video.playbackRate = spd;
          speedBtn.innerText = spd + "x";
          speedMenu.querySelectorAll('.menu-item').forEach(function(i) { i.classList.remove('active'); });
          item.classList.add('active');
          speedMenu.style.display = "none";
          showControls();
        };
      });

      if (Hls.isSupported()) {
        hls = new Hls({ enableWorker: true, lowLatencyMode: true });
        hls.loadSource(videoUrl);
        hls.attachMedia(video);

        hls.on(Hls.Events.MANIFEST_PARSED, function(event, data) {
          renderQualityOptions(data.levels);
          video.play().catch(function(){});
        });

        function renderQualityOptions(levels) {
          qualityList.innerHTML = "";
          var autoItem = document.createElement('div');
          autoItem.className = "menu-item active";
          autoItem.innerText = "Auto";
          autoItem.onclick = function(e) {
            e.stopPropagation();
            hls.currentLevel = -1;
            updateQualityActive(autoItem);
          };
          qualityList.appendChild(autoItem);

          levels.forEach(function(lvl, idx) {
            var item = document.createElement('div');
            item.className = "menu-item";
            var resName = lvl.height ? lvl.height + "p" : "SD";
            item.innerText = resName;
            item.onclick = function(e) {
              e.stopPropagation();
              hls.currentLevel = idx;
              updateQualityActive(item);
            };
            qualityList.appendChild(item);
          });
        }

        function updateQualityActive(selected) {
          qualityList.querySelectorAll('.menu-item').forEach(function(i) { i.classList.remove('active'); });
          selected.classList.add('active');
          qualityMenu.style.display = "none";
          showControls();
        }
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

  void _onOpenPdfNote(NoteModel note) {
    if (note.pdfUrl == null || note.pdfUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF not available for this note.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.pdfReader,
      arguments: {
        'pdfUrl': note.pdfUrl!,
        'title': note.title,
        'fileSize': note.fileSize,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Curriculum',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lecture.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.courseName} • ${widget.lecture.duration ?? "45 mins"}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Container (16:9 Aspect Ratio)
            Container(
              color: Colors.black,
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    if (!_hasError) WebViewWidget(controller: _controller),

                    if (_isLoading)
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              CircularProgressIndicator(color: AppColors.primary),
                              SizedBox(height: 12),
                              Text(
                                'Loading Lecture Video...',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_hasError)
                      Container(
                        color: Colors.black,
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam_off_rounded, size: 48, color: AppColors.error),
                              const SizedBox(height: 10),
                              const Text(
                                'Unable to load video lecture.',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _hasError = false;
                                    _isLoading = true;
                                  });
                                  _controller.reload();
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                                label: const Text('Retry Stream', style: TextStyle(color: Colors.white, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Details Surface & Attached Note Section
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Consolidated Lecture Details & Completion Action Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.lecture.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.school_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${widget.courseName} • ${widget.lecture.duration ?? "45 mins"}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: _isTogglingProgress ? null : _toggleCompletion,
                                icon: _isTogglingProgress
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Icon(
                                        _isCompleted ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                label: Text(
                                  _isCompleted ? 'Completed' : 'Mark Lecture as Completed',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isCompleted ? AppColors.success : AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Attached Study Note Card (Only shown if note exists)
                      if (_isLoadingNote)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        )
                      else if (_attachedNote != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _attachedNote!.title,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PDF Study Note • ${_attachedNote!.fileSize ?? "2.4 MB"}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _onOpenPdfNote(_attachedNote!),
                                icon: const Icon(Icons.visibility_rounded, size: 14, color: Colors.white),
                                label: const Text('Read Note', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
