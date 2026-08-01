import 'package:flutter/material.dart';

import '../domain/conservation_status.dart';
import '../domain/rarity_tier.dart';

/// The design system. See docs/DESIGN-DIRECTION.md for the reasoning.
///
/// Governing idea: the photo is the prize, the frame is the ceremony. The
/// interface is a case for photographs and must never compete with them —
/// which is why almost all colour here is either near-black or carried by
/// rarity.

/// Bushveld palette. Near-black with a green cast, never pure black — pure
/// black makes photo edges look cut out.
abstract final class AppColors {
  static const Color background = Color(0xFF0D1110);
  static const Color surface = Color(0xFF161B18);
  static const Color surfaceRaised = Color(0xFF1E2521);
  static const Color outline = Color(0xFF2E3833);
  static const Color outlineStrong = Color(0xFF3F4A44);

  /// Warm off-white. Pure white on near-black is harsh and reads as cheap.
  static const Color textPrimary = Color(0xFFF1EFE8);
  static const Color textSecondary = Color(0xFFA6AFA2);
  static const Color textMuted = Color(0xFF6E7A70);

  /// Brass — late afternoon light. The *only* interface accent. A second
  /// accent is how dark themes start to look like dashboards.
  static const Color accent = Color(0xFFDCA84A);
  static const Color accentInk = Color(0xFF14100A);

  static const Color verified = Color(0xFF5FA96B);
  static const Color danger = Color(0xFFE0736B);
}

/// Both families are variable fonts, so weight comes from [FontVariation]
/// rather than [FontWeight]. Bundled, never fetched — `google_fonts` downloads
/// at runtime and this app has no network for days at a time.
abstract final class AppFonts {
  /// Warm editorial serif. Species names, titles, scores. It is what makes the
  /// app read as *field guide* rather than *app*.
  static const String display = 'Fraunces';

  /// Interface face. Exceptional legibility at small sizes and in bright sun,
  /// which is the actual reading condition here.
  static const String ui = 'Inter';

  static List<FontVariation> weight(double w) => <FontVariation>[
    FontVariation('wght', w),
  ];

  /// Fraunces' SOFT axis low and WONK off — characterful, not novelty.
  static List<FontVariation> displayWeight(double w) => <FontVariation>[
    FontVariation('wght', w),
    const FontVariation('SOFT', 0),
    const FontVariation('WONK', 0),
    const FontVariation('opsz', 40),
  ];
}

/// The type scale — 1.25 ratio, rounded. See DESIGN-DIRECTION.md.
abstract final class AppText {
  static const TextStyle display = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 46,
    height: 1,
    color: AppColors.textPrimary,
    fontVariations: <FontVariation>[
      FontVariation('wght', 700),
      FontVariation('SOFT', 0),
      FontVariation('WONK', 0),
    ],
  );

  static const TextStyle title1 = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 30,
    height: 1.13,
    color: AppColors.textPrimary,
    fontVariations: <FontVariation>[
      FontVariation('wght', 700),
      FontVariation('SOFT', 0),
      FontVariation('WONK', 0),
    ],
  );

  static const TextStyle title2 = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 22,
    height: 1.18,
    color: AppColors.textPrimary,
    fontVariations: <FontVariation>[
      FontVariation('wght', 600),
      FontVariation('SOFT', 0),
      FontVariation('WONK', 0),
    ],
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 15,
    height: 1.47,
    color: AppColors.textSecondary,
    fontVariations: <FontVariation>[FontVariation('wght', 400)],
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 15,
    height: 1.47,
    color: AppColors.textPrimary,
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
  );

  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 13,
    height: 1.23,
    color: AppColors.textSecondary,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 11,
    height: 1.27,
    color: AppColors.textMuted,
    fontVariations: <FontVariation>[FontVariation('wght', 500)],
  );

  static const TextStyle overline = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 10,
    height: 1.2,
    letterSpacing: 1.6,
    color: AppColors.textMuted,
    fontVariations: <FontVariation>[FontVariation('wght', 800)],
  );

  /// Tabular figures, for anything that changes. A score counting up must not
  /// jitter as digit widths shift.
  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];
}

/// 4pt base grid. These are the only permitted spacing values.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double screen = 20;
  static const double xl = 24;
  static const double section = 28;
  static const double xxl = 32;
}

abstract final class Radii {
  static const double chip = 8;
  static const double card = 14;
  static const double sheet = 20;
}

/// How one rarity tier is drawn.
///
/// Rarity escalates across **five redundant channels** — colour, border width,
/// wash, glow and frame treatment — because colour alone fails for the ~8% of
/// men with colour vision deficiency and washes out in direct sun. The tier
/// sequence is also ordered by temperature so it reads correctly in greyscale.
class RarityStyle {
  const RarityStyle({
    required this.accent,
    required this.fill,
    required this.border,
    required this.borderWidth,
    required this.glow,
    required this.notched,
    required this.foil,
  });

  final Color accent;
  final Color fill;
  final Color border;
  final double borderWidth;

  /// Only for Very rare and above. Glow is never decoration — if it appears
  /// anywhere not conveying rarity, it is wrong.
  final Color? glow;

  /// Cut corners, from Rare upward.
  final bool notched;

  /// Diagonal gloss, from Exceptional upward.
  final bool foil;

  bool get isExalted => glow != null;
}

extension RarityTierStyling on RarityTier {
  /// Styles are positional — tier 1 through 7 — so this survives the pending
  /// rename. The enum still carries the old names and values
  /// (`uncommon`, `scarce`, and the wrong point values); the migration to
  /// Common / Frequent / Notable / Rare / Very rare / Exceptional / Legendary
  /// happens with the guide's re-tiering. See docs/DIVERGENCES.md §5.
  RarityStyle get style => switch (this) {
    // Deliberately hueless. Stone says "not the interesting one" more clearly
    // than any colour, and it makes everything above read as a step up.
    RarityTier.common => const RarityStyle(
      accent: Color(0xFF8A8F86),
      fill: Color(0x00000000),
      border: Color(0xFF2E3833),
      borderWidth: 1,
      glow: null,
      notched: false,
      foil: false,
    ),
    RarityTier.frequent => const RarityStyle(
      accent: Color(0xFF5FA96B),
      fill: Color(0x145FA96B),
      border: Color(0xFF35483A),
      borderWidth: 1,
      glow: null,
      notched: false,
      foil: false,
    ),
    // → Notable
    RarityTier.uncommon => const RarityStyle(
      accent: Color(0xFF4A93C7),
      fill: Color(0x1C4A93C7),
      border: Color(0xFF3A5468),
      borderWidth: 1.4,
      glow: null,
      notched: false,
      foil: false,
    ),
    // → Rare
    RarityTier.scarce => const RarityStyle(
      accent: Color(0xFF8B72D6),
      fill: Color(0x248B72D6),
      border: Color(0xFF493C6C),
      borderWidth: 1.6,
      glow: null,
      notched: true,
      foil: false,
    ),
    // → Very rare
    RarityTier.rare => const RarityStyle(
      accent: Color(0xFFE08238),
      fill: Color(0x2BE08238),
      border: Color(0xFF7A4A22),
      borderWidth: 2,
      glow: Color(0x33E08238),
      notched: true,
      foil: false,
    ),
    // → Exceptional
    RarityTier.veryRare => const RarityStyle(
      accent: Color(0xFFE0503A),
      fill: Color(0x36E0503A),
      border: Color(0xFF8A3325),
      borderWidth: 2.2,
      glow: Color(0x4AE0503A),
      notched: true,
      foil: true,
    ),
    RarityTier.legendary => const RarityStyle(
      accent: Color(0xFFE8C15A),
      fill: Color(0x40E8C15A),
      border: Color(0xFFB08D2E),
      borderWidth: 2.6,
      glow: Color(0x5CE8C15A),
      notched: true,
      foil: true,
    ),
  };
}

extension ConservationStatusStyling on ConservationStatus {
  Color get color => switch (this) {
    ConservationStatus.leastConcern => const Color(0xFF5FA96B),
    ConservationStatus.nearThreatened => const Color(0xFF9FB25A),
    ConservationStatus.vulnerable => const Color(0xFFE0B23A),
    ConservationStatus.endangered => const Color(0xFFE08238),
    ConservationStatus.criticallyEndangered => const Color(0xFFE0503A),
  };
}

/// Interface motion is invisible; ceremony is reserved for the reveal.
/// Nothing here bounces — easeOutBack on a filter chip is a toy.
abstract final class Motion {
  static const Duration press = Duration(milliseconds: 110);
  static const Duration chip = Duration(milliseconds: 180);
  static const Duration sheet = Duration(milliseconds: 240);
  static const Duration screen = Duration(milliseconds: 260);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve exit = Curves.easeOut;
}

ThemeData buildAppTheme() {
  const ColorScheme scheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: AppColors.accentInk,
    secondary: AppColors.verified,
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
    fontFamily: AppFonts.ui,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.title2,
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
    focusedBorder: _fieldBorder(AppColors.accent, 1.6),
    errorBorder: _fieldBorder(AppColors.danger),
    focusedErrorBorder: _fieldBorder(AppColors.danger, 1.6),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: _fieldBorder(AppColors.outline),
    enabledBorder: _fieldBorder(AppColors.outline),
    focusedBorder: _fieldBorder(AppColors.accent, 1.4),
  );
}

OutlineInputBorder _fieldBorder(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.card),
    borderSide: BorderSide(color: color, width: width),
  );
}
