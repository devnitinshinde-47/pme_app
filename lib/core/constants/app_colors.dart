import 'package:flutter/material.dart';

/// Human-crafted premium color palette for Pawan Mate Education.
abstract class AppColors {
  // Brand Colors (Logo exact extracted colors)
  static const Color primary = Color(0xFF1B365D); // Premium Logo Navy Blue
  static const Color primaryDark = Color(0xFF10233F);
  static const Color primaryLight = Color(0xFFEFF4FA);
  
  static const Color accent = Color(0xFFF15A24); // Logo Warm Orange
  static const Color accentLight = Color(0xFFFFF2ED);

  // Surface & Neutral Shades
  static const Color background = Color(0xFFF8FAFC); // Clean Slate Neutral
  static const Color splashBackground = Colors.white;
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color inputFill = Color(0xFFF1F5F9);

  // Typography Palette
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate Header
  static const Color textSecondary = Color(0xFF475569); // Slate Body
  static const Color textMuted = Color(0xFF94A3B8); // Muted Subtitle

  // Status Indicators
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Liquid Glass Palette
  static final Color glassBackground = Colors.white.withValues(alpha: 0.65);
  static final Color glassBackgroundDark = const Color(0xFF1B365D).withValues(alpha: 0.70);
  static final Color glassBorder = Colors.white.withValues(alpha: 0.60);
  static final Color glassBorderDark = Colors.white.withValues(alpha: 0.18);
  static final Color glassActivePill = const Color(0xFF1B365D).withValues(alpha: 0.10);
  static final Color glassActiveGlow = const Color(0xFFF15A24).withValues(alpha: 0.25);
}
