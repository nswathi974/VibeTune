import 'package:flutter/material.dart';

export 'app_palette.dart';

class AppColors {
  // Backwards-compatible Dark defaults
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF111724);
  static const Color surfaceLight = Color(0xFF182236);
  static const Color surfaceHover = Color(0xFF202C45);
  static const Color border = Color(0xFF1E293B);

  // Brand Accents
  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color secondary = Color(0xFF8B5CF6); // Vibrant Violet
  static const Color accent = Color(0xFFFF2A85); // Electric Pink

  // Karaoke Gold / Amber
  static const Color karaokeAccent = Color(0xFFFFB703); // Golden Karaoke Glow
  static const Color karaokeOrange = Color(0xFFFB8500);

  // Feedback & Functional
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Text colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient karaokeGradient = LinearGradient(
    colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purplePinkGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFFF2A85)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF141C2A), Color(0xFF0E1420)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
