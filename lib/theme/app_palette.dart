import 'package:flutter/material.dart';

/// Semantic, adaptive color palette conforming to Material 3 ThemeExtension.
/// Provides consistent design tokens for both Dark (Obsidian/Slate) and Light (Platinum/Slate) modes.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceHover;
  final Color surfaceGlass;
  final Color border;
  final Color borderSubtle;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color primary;
  final Color primaryVariant;
  final Color secondary;
  final Color accent;

  final Color karaokeAccent;
  final Color karaokeOrange;

  final Color success;
  final Color warning;
  final Color error;

  final bool isDark;

  final LinearGradient primaryGradient;
  final LinearGradient karaokeGradient;
  final LinearGradient cardGradient;
  final LinearGradient glassGradient;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHover,
    required this.surfaceGlass,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.primaryVariant,
    required this.secondary,
    required this.accent,
    required this.karaokeAccent,
    required this.karaokeOrange,
    required this.success,
    required this.warning,
    required this.error,
    required this.isDark,
    required this.primaryGradient,
    required this.karaokeGradient,
    required this.cardGradient,
    required this.glassGradient,
  });

  /// The default Obsidian / Midnight Slate dark palette
  static const AppPalette dark = AppPalette(
    background: Color(0xFF090D16),
    surface: Color(0xFF111724),
    surfaceElevated: Color(0xFF182236),
    surfaceHover: Color(0xFF202C45),
    surfaceGlass: Color(0xB8111724),
    border: Color(0xFF1E293B),
    borderSubtle: Color(0x1AFFFFFF),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    primary: Color(0xFF00E5FF),
    primaryVariant: Color(0xFF00B4D8),
    secondary: Color(0xFF8B5CF6),
    accent: Color(0xFFFF2A85),
    karaokeAccent: Color(0xFFFFB703),
    karaokeOrange: Color(0xFFFB8500),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    isDark: true,
    primaryGradient: LinearGradient(
      colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    karaokeGradient: LinearGradient(
      colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF141C2A), Color(0xFF0E1420)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glassGradient: LinearGradient(
      colors: [Color(0x33FFFFFF), Color(0x0DFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// The clean Platinum / Slate light palette
  static const AppPalette light = AppPalette(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF1F5F9),
    surfaceHover: Color(0xFFE2E8F0),
    surfaceGlass: Color(0xD9FFFFFF),
    border: Color(0xFFE2E8F0),
    borderSubtle: Color(0x14000000),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    primary: Color(0xFF0284C7),
    primaryVariant: Color(0xFF0369A1),
    secondary: Color(0xFF7C3AED),
    accent: Color(0xFFE11D48),
    karaokeAccent: Color(0xFFD97706),
    karaokeOrange: Color(0xFFC2410C),
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    isDark: false,
    primaryGradient: LinearGradient(
      colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    karaokeGradient: LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glassGradient: LinearGradient(
      colors: [Color(0x80FFFFFF), Color(0x33FFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Helper to access current palette from BuildContext
  static AppPalette of(BuildContext context) {
    final ext = Theme.of(context).extension<AppPalette>();
    if (ext != null) return ext;
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceHover,
    Color? surfaceGlass,
    Color? border,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? primaryVariant,
    Color? secondary,
    Color? accent,
    Color? karaokeAccent,
    Color? karaokeOrange,
    Color? success,
    Color? warning,
    Color? error,
    bool? isDark,
    LinearGradient? primaryGradient,
    LinearGradient? karaokeGradient,
    LinearGradient? cardGradient,
    LinearGradient? glassGradient,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      karaokeAccent: karaokeAccent ?? this.karaokeAccent,
      karaokeOrange: karaokeOrange ?? this.karaokeOrange,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      isDark: isDark ?? this.isDark,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      karaokeGradient: karaokeGradient ?? this.karaokeGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      glassGradient: glassGradient ?? this.glassGradient,
    );
  }

  @override
  ThemeExtension<AppPalette> lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryVariant: Color.lerp(primaryVariant, other.primaryVariant, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      karaokeAccent: Color.lerp(karaokeAccent, other.karaokeAccent, t)!,
      karaokeOrange: Color.lerp(karaokeOrange, other.karaokeOrange, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      karaokeGradient: LinearGradient.lerp(karaokeGradient, other.karaokeGradient, t)!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
      glassGradient: LinearGradient.lerp(glassGradient, other.glassGradient, t)!,
    );
  }
}

/// Extension for convenient access via context
extension BuildContextPaletteX on BuildContext {
  AppPalette get palette => AppPalette.of(this);
}

