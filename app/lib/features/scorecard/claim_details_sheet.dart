import 'package:flutter/material.dart';

import '../../domain/sighting_context.dart';
import '../../domain/species.dart';
import '../../shared/theme.dart';

/// What the claim was worth, decided by the two questions worth asking.
class ClaimDetails {
  const ClaimDetails({required this.context, required this.variant});

  static const ClaimDetails ordinary = ClaimDetails(
    context: SightingContext.normal,
    variant: false,
  );

  final SightingContext context;
  final bool variant;
}

/// Asked immediately after the animal is picked, and only when the answer
/// changes something.
///
/// Two questions at most, both a single tap, both on one screen. The whole
/// claim has to stay fast enough to do while the animal is still there — this
/// sits between "who spotted it" and the points landing, and if it ever grows
/// a third question it has gone too far.
///
/// Returns null if dismissed, which the caller treats as cancelling the claim
/// rather than as an ordinary sighting. Backing out of a half-finished claim
/// should not silently score one.
class ClaimDetailsSheet extends StatefulWidget {
  const ClaimDetailsSheet({required this.species, super.key});

  final Species species;

  /// True when this species has anything worth asking about. Checked by the
  /// caller so that the common claim — an impala, a zebra — never sees a sheet
  /// at all.
  static bool needed(Species species) =>
      species.crowdMatters || species.variant != null;

  static Future<ClaimDetails?> ask(BuildContext context, Species species) {
    if (!needed(species)) {
      return Future<ClaimDetails?>.value(ClaimDetails.ordinary);
    }
    return showModalBottomSheet<ClaimDetails>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => ClaimDetailsSheet(species: species),
    );
  }

  @override
  State<ClaimDetailsSheet> createState() => _ClaimDetailsSheetState();
}

class _ClaimDetailsSheetState extends State<ClaimDetailsSheet> {
  SightingContext _context = SightingContext.normal;
  bool _variant = false;

  @override
  Widget build(BuildContext context) {
    final Species species = widget.species;
    final RarityStyle style = species.rarityTier.style;
    final int points = species.scoreFor(
      variantApplied: _variant,
      context: _context,
    );

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.sheet),
          border: Border.all(color: AppColors.outline),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.lg,
                  Space.lg,
                  Space.md,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        species.commonName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title2,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    // Live, because watching the number move as you answer is
                    // what teaches the rule. Nobody reads a rules screen.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        '$points',
                        key: ValueKey<int>(points),
                        style: AppText.title1.copyWith(
                          fontSize: 30,
                          color: style.accent,
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (species.variant
                  case final SpeciesVariant variant) ...<Widget>[
                const Divider(height: 1, color: AppColors.outline),
                _Question(label: variant.question),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    0,
                    Space.lg,
                    Space.lg,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _Choice(
                          label: 'Yes — ${variant.label.toLowerCase()}',
                          detail: '+${variant.bonus}',
                          selected: _variant,
                          onTap: () => setState(() => _variant = true),
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: _Choice(
                          label: 'No',
                          selected: !_variant,
                          onTap: () => setState(() => _variant = false),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (species.crowdMatters) ...<Widget>[
                const Divider(height: 1, color: AppColors.outline),
                const _Question(label: 'Who else was there?'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.lg,
                    0,
                    Space.lg,
                    Space.lg,
                  ),
                  child: Column(
                    children: <Widget>[
                      for (final SightingContext c in SightingContext.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Space.sm),
                          child: _Choice(
                            label: c.label,
                            detail: switch (c) {
                              SightingContext.alone => 'Double',
                              SightingContext.normal => null,
                              SightingContext.jam => 'Half',
                            },
                            selected: _context == c,
                            wide: true,
                            onTap: () => setState(() => _context = c),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  0,
                  Space.lg,
                  Space.lg,
                ),
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(ClaimDetails(context: _context, variant: _variant)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.accentInk,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.card),
                      ),
                    ),
                    child: Text(
                      'Claim it',
                      style: AppText.bodyStrong.copyWith(
                        color: AppColors.accentInk,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.lg,
        Space.lg,
        Space.md,
      ),
      child: Text(label, style: AppText.label),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
    this.wide = false,
  });

  final String label;

  /// "Double", "Half", "+60". What the answer does, said in words rather than
  /// left for people to work out from the total.
  final String? detail;

  final bool selected;
  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentWash : AppColors.surface,
      borderRadius: BorderRadius.circular(Radii.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.chip),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.outlineStrong,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: wide
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: wide ? TextAlign.start : TextAlign.center,
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    color: selected ? AppColors.accent : AppColors.textPrimary,
                    fontVariations: AppFonts.weight(selected ? 700 : 500),
                  ),
                ),
              ),
              if (detail case final String d) ...<Widget>[
                if (wide) const Spacer() else const SizedBox(width: 6),
                Text(
                  d,
                  style: AppText.caption.copyWith(
                    color: selected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontVariations: AppFonts.weight(700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
