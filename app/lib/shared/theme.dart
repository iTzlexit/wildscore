import 'package:flutter/material.dart';

import '../domain/conservation_status.dart';
import '../domain/rarity_tier.dart';

/// Bushveld palette. Dark by default — the app is used at dawn, at dusk and on
/// night drives, and a white screen at 5am in a game vehicle is antisocial.
abstract final class AppColors {
  static const Color background = Color(0xFF0E1210);
  static const Color surface = Color(0xFF161C19);
  static const Color surfaceRaised = Color(0xFF1E2723);
  static const Color outline = Color(0xFF2C3831);
  static const Color textPrimary = Color(0xFFEDEFEA);
  static const Color textSecondary = Color(0xFF97A398);
  static const Color textMuted = Color(0xFF64726A);
  static const Color accent = Color(0xFFD9A441);
  static const Color danger = Color(0xFFE0736B);
}

/// The visual treatment for one rarity tier.
///
/// Colours carry baked-in alpha rather than being computed with `withOpacity`
/// — that API has churned across Flutter versions and this avoids the whole
/// argument. It also means the palette is inspectable as literal values.
class RarityStyle {
  const RarityStyle({
    required this.accent,
    required this.fill,
    required this.border,
    required this.borderWidth,
    required this.glow,
  });

  /// Text, badges, the leading rail on a card.
  final Color accent;

  /// Gradient wash across the card body.
  final Color fill;

  final Color border;
  final double borderWidth;

  /// Outer shadow. Null for the ordinary tiers — glow has to mean something.
  final Color? glow;

  bool get isExalted => glow != null;
}

extension RarityTierStyling on RarityTier {
  RarityStyle get style => switch (this) {
    RarityTier.common => const RarityStyle(
      accent: Color(0xFF8FA08D),
      fill: Color(0x0F8FA08D),
      border: Color(0xFF2C3831),
      borderWidth: 1,
      glow: null,
    ),
    RarityTier.frequent => const RarityStyle(
      accent: Color(0xFF5AA46F),
      fill: Color(0x145AA46F),
      border: Color(0xFF33463A),
      borderWidth: 1,
      glow: null,
    ),
    RarityTier.uncommon => const RarityStyle(
      accent: Color(0xFF4A93C7),
      fill: Color(0x1C4A93C7),
      border: Color(0xFF3A5468),
      borderWidth: 1.2,
      glow: null,
    ),
    RarityTier.scarce => const RarityStyle(
      accent: Color(0xFF9A78D8),
      fill: Color(0x229A78D8),
      border: Color(0xFF4B3D6B),
      borderWidth: 1.4,
      glow: null,
    ),
    RarityTier.rare => const RarityStyle(
      accent: Color(0xFFE08238),
      fill: Color(0x2BE08238),
      border: Color(0xFF7A4A22),
      borderWidth: 1.6,
      glow: Color(0x33E08238),
    ),
    RarityTier.veryRare => const RarityStyle(
      accent: Color(0xFFE05A5A),
      fill: Color(0x36E05A5A),
      border: Color(0xFF8C3535),
      borderWidth: 1.8,
      glow: Color(0x47E05A5A),
    ),
    RarityTier.legendary => const RarityStyle(
      accent: Color(0xFFE8C15A),
      fill: Color(0x40E8C15A),
      border: Color(0xFFB08D2E),
      borderWidth: 2.2,
      glow: Color(0x5AE8C15A),
    ),
  };
}

extension ConservationStatusStyling on ConservationStatus {
  Color get color => switch (this) {
    ConservationStatus.leastConcern => const Color(0xFF5AA46F),
    ConservationStatus.nearThreatened => const Color(0xFF9FB25A),
    ConservationStatus.vulnerable => const Color(0xFFE0B23A),
    ConservationStatus.endangered => const Color(0xFFE08238),
    ConservationStatus.criticallyEndangered => const Color(0xFFE0503A),
  };
}

ThemeData buildAppTheme() {
  const ColorScheme scheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: Color(0xFF14100A),
    secondary: Color(0xFF5AA46F),
    onSecondary: Color(0xFF0B140E),
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.danger,
    onError: Color(0xFF1A0C0B),
    outline: AppColors.outline,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    dividerColor: AppColors.outline,
  );
}

/// Input styling, applied directly on the [TextField] rather than through
/// `ThemeData.inputDecorationTheme`.
///
/// Deliberate: `InputDecorationTheme` was deprecated in favour of
/// `InputDecorationThemeData` during 2025, and a theme-level assignment is the
/// kind of thing that stops compiling on a newer SDK. Passing decoration
/// straight to the widget works on every Flutter version there has ever been.
InputDecoration searchFieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
    prefixIcon: const Icon(
      Icons.search_rounded,
      color: AppColors.textMuted,
      size: 20,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
    ),
  );
}
