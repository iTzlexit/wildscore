import 'package:flutter/material.dart';

import '../domain/conservation_status.dart';
import '../domain/rarity_tier.dart';

/// The design system. See docs/DESIGN-DIRECTION.md.
///
/// **Light, single-typeface, green.** The previous dark-and-gold direction read
/// as generic — near-black everywhere, one warm accent, hairline borders. This
/// one follows current practice: a warm near-white ground, real elevation from
/// soft shadows rather than outlines, one typeface carrying hierarchy through
/// weight and size, and colour reserved almost entirely for rarity.

/// Warm neutrals. Never pure white for the ground — pure white is clinical and
/// makes photographs look pasted on. The page is a shade warmer than the cards
/// sitting on it, which is what lets cards read as raised without heavy shadow.
abstract final class AppColors {
  static const Color background = Color(0xFFF6F6F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEFF0EC);
  static const Color outline = Color(0xFFE2E4DE);
  static const Color outlineStrong = Color(0xFFCBCFC7);

  static const Color textPrimary = Color(0xFF151A17);
  static const Color textSecondary = Color(0xFF5C665F);
  static const Color textMuted = Color(0xFF8A938C);

  /// Deep bushveld green. Natural, current, and unmistakably not gold.
  static const Color accent = Color(0xFF1B7A54);
  static const Color accentInk = Color(0xFFFFFFFF);
  static const Color accentWash = Color(0x141B7A54);

  static const Color verified = Color(0xFF1B7A54);
  static const Color danger = Color(0xFFC0392B);

  /// Elevation on light comes from shadow, not from a lighter surface.
  static const List<BoxShadow> shadowSm = <BoxShadow>[
    BoxShadow(color: Color(0x0D151A17), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A151A17), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowMd = <BoxShadow>[
    BoxShadow(color: Color(0x14151A17), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0F151A17), blurRadius: 18, offset: Offset(0, 8)),
  ];
}

/// One family. Inter Variable is the current default for mobile UI for good
/// reason — it holds up at 10pt in sunlight, which is the real reading
/// condition here. Hierarchy comes from weight and size, not from a second
/// typeface. Dropping the display serif also removed 352 KB from the bundle.
abstract final class AppFonts {
  static const String ui = 'Inter';

  static List<FontVariation> weight(double w) => <FontVariation>[
    FontVariation('wght', w),
  ];
}

TextStyle _inter(
  double size,
  double weight,
  double height,
  Color color, {
  double? spacing,
}) {
  return TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: size,
    height: height,
    color: color,
    letterSpacing: spacing,
    fontVariations: <FontVariation>[FontVariation('wght', weight)],
  );
}

/// Type scale. Headings are deliberately much heavier than body — a 1.6x size
/// jump plus a 400-weight jump is what reads as hierarchy without a second face.
abstract final class AppText {
  static final TextStyle display = _inter(
    44,
    800,
    1.02,
    AppColors.textPrimary,
    spacing: -1.4,
  );
  static final TextStyle title1 = _inter(
    28,
    800,
    1.14,
    AppColors.textPrimary,
    spacing: -0.7,
  );
  static final TextStyle title2 = _inter(
    20,
    700,
    1.2,
    AppColors.textPrimary,
    spacing: -0.3,
  );
  static final TextStyle title3 = _inter(16, 700, 1.3, AppColors.textPrimary);
  static final TextStyle body = _inter(15, 400, 1.5, AppColors.textSecondary);
  static final TextStyle bodyStrong = _inter(
    15,
    600,
    1.5,
    AppColors.textPrimary,
  );
  static final TextStyle label = _inter(13, 500, 1.25, AppColors.textSecondary);
  static final TextStyle caption = _inter(12, 500, 1.35, AppColors.textMuted);
  static final TextStyle overline = _inter(
    10.5,
    700,
    1.2,
    AppColors.textMuted,
    spacing: 1.1,
  );

  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];
}

/// 8pt grid, with 4 available for tight pairings.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double screen = 20;
  static const double xl = 24;
  static const double section = 32;
  static const double xxl = 40;
}

abstract final class Radii {
  static const double chip = 12;
  static const double card = 20;
  static const double sheet = 32;
}

/// How one rarity tier is drawn.
///
/// **Colour and words, and nothing that changes the shape of a card.**
///
/// This used to escalate across five channels: colour, frame weight, wash,
/// glow and a notched corner. The concern behind it was sound — colour alone
/// fails for the ~8% of men with colour vision deficiency, and washes out in
/// direct sun — but the answer was wrong for a grid of two hundred
/// photographs, which came out looking like a box of assorted stationery.
///
/// The redundancy that matters survives: the tier is written out in words on
/// every tile and every card, and words beat a glow in sunlight and in
/// greyscale alike.
class RarityStyle {
  const RarityStyle({required this.accent, required this.fill});

  /// Text, badges, the header field. Tuned for contrast on near-white.
  final Color accent;

  /// Wash behind a card label.
  final Color fill;

  Color get border => accent;

  /// Detail-screen colour field. Light enough to read dark text on for the
  /// muted tiers, so the header adapts rather than forcing white everywhere.
  Color get headerTop => accent;
  Color get headerInk => Color.lerp(accent, const Color(0xFF0B0F0D), 0.28)!;
}

extension RarityTierStyling on RarityTier {
  /// Positional — tier 1 through 6 — so this survives the pending rename of the
  /// enum values themselves. See docs/DIVERGENCES.md.
  RarityStyle get style => switch (this) {
    // Hueless on purpose. Stone says "not the interesting one" better than any
    // colour, and it makes everything above it read as a step up.
    RarityTier.common => const RarityStyle(
      accent: Color(0xFF77817A),
      fill: Color(0x0F77817A),
    ),
    RarityTier.frequent => const RarityStyle(
      accent: Color(0xFF2E8B57),
      fill: Color(0x142E8B57),
    ),
    // → Notable
    RarityTier.uncommon => const RarityStyle(
      accent: Color(0xFF2372A8),
      fill: Color(0x1A2372A8),
    ),
    // → Rare
    RarityTier.scarce => const RarityStyle(
      accent: Color(0xFF6B47C0),
      fill: Color(0x1F6B47C0),
    ),
    // → Very rare. Takes the old Exceptional crimson: with one fewer tier
    // above it, this is now the last step before the top and needs to look it.
    RarityTier.rare => const RarityStyle(
      accent: Color(0xFFC0392B),
      fill: Color(0x2BC0392B),
    ),
    RarityTier.legendary => const RarityStyle(
      accent: Color(0xFF9C6B10),
      fill: Color(0x2E9C6B10),
    ),
  };
}

extension ConservationStatusStyling on ConservationStatus {
  Color get color => switch (this) {
    ConservationStatus.leastConcern => const Color(0xFF2E8B57),
    ConservationStatus.nearThreatened => const Color(0xFF6E8C1F),
    ConservationStatus.vulnerable => const Color(0xFFB8860B),
    ConservationStatus.endangered => const Color(0xFFC26A15),
    ConservationStatus.criticallyEndangered => const Color(0xFFC0392B),
  };
}

/// Interface motion is invisible; ceremony is reserved for the reveal.
abstract final class Motion {
  static const Duration press = Duration(milliseconds: 110);
  static const Duration chip = Duration(milliseconds: 180);
  static const Duration sheet = Duration(milliseconds: 240);
  static const Duration screen = Duration(milliseconds: 260);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve exit = Curves.easeOut;
}

ThemeData buildAppTheme() {
  final ColorScheme scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.accent,
        onPrimary: AppColors.accentInk,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        outline: AppColors.outline,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppFonts.ui,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.title2,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    dividerColor: AppColors.outline,
  );
}

InputDecoration nameFieldDecoration(String? errorText) {
  return InputDecoration(
    hintText: 'Your name',
    errorText: errorText,
    counterText: '',
    filled: true,
    fillColor: AppColors.surface,
    hintStyle: AppText.title2.copyWith(color: AppColors.textMuted),
    errorStyle: AppText.caption.copyWith(color: AppColors.danger),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: _fieldBorder(AppColors.outline),
    enabledBorder: _fieldBorder(AppColors.outline),
    focusedBorder: _fieldBorder(AppColors.accent, 1.8),
    errorBorder: _fieldBorder(AppColors.danger),
    focusedErrorBorder: _fieldBorder(AppColors.danger, 1.8),
  );
}

InputDecoration searchFieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    hintStyle: AppText.label.copyWith(color: AppColors.textMuted),
    prefixIcon: const Icon(
      Icons.search_rounded,
      color: AppColors.textMuted,
      size: 20,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: _fieldBorder(AppColors.outline),
    enabledBorder: _fieldBorder(AppColors.outline),
    focusedBorder: _fieldBorder(AppColors.accent, 1.6),
  );
}

OutlineInputBorder _fieldBorder(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.card),
    borderSide: BorderSide(color: color, width: width),
  );
}
