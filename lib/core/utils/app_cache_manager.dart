import 'dart:io';
import 'package:flutter/widgets.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';

/// Centralized Cache & Memory Manager for Flutter App.
/// Controls image cache memory caps, temp file cleanup, and logout purge operations.
class AppCacheManager {
  static final AppCacheManager _instance = AppCacheManager._internal();
  static AppCacheManager get instance => _instance;

  final AuthLocalDataSource _authLocalDataSource;

  AppCacheManager({AuthLocalDataSource? authLocalDataSource})
      : _authLocalDataSource = authLocalDataSource ?? AuthLocalDataSource();

  AppCacheManager._internal() : _authLocalDataSource = AuthLocalDataSource();

  /// Configure bounds on Flutter ImageCache to prevent high RAM memory usage.
  /// Sets max memory size to 50 MB and max image count to 100 entries.
  void configureCacheLimits() {
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB
    PaintingBinding.instance.imageCache.maximumSize = 100; // 100 images
  }

  /// Clears in-memory image cache and temporary directory files.
  Future<void> clearTemporaryCache() async {
    // 1. Evict Flutter image memory cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // 2. Clear temp directory files if accessible
    try {
      final tempDir = Directory.systemTemp;
      if (tempDir.existsSync()) {
        final entities = tempDir.listSync();
        for (final entity in entities) {
          try {
            if (entity is File) {
              entity.deleteSync();
            } else if (entity is Directory) {
              entity.deleteSync(recursive: true);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Complete cache purge on User Logout.
  /// Removes all stored session credentials, temporary cache, and image memory buffers.
  Future<void> clearOnLogout() async {
    await clearTemporaryCache();
    await _authLocalDataSource.clearSession();
  }
}
