import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../domain/species.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/avatar_badge.dart';

/// "Who spotted it?" — the sheet that turns a tap into a claim.
///
/// Deliberately a bottom sheet with large targets: this is used one-handed, in
/// a moving vehicle, by someone who is still looking out of the window. Every
/// extra tap here is a tap taken away from watching the animal.
class WhoSpottedSheet extends StatelessWidget {
  const WhoSpottedSheet({required this.species, required this.card, super.key});

  final Species species;
  final Scorecard card;

  /// Returns the chosen player id, or `null` if dismissed.
  /// Returns [unclaimSentinel] when the user chose to undo an existing claim.
  static const String unclaimSentinel = '__unclaim__';

  /// Returns this when the user wants the field-guide entry instead.
  ///
  /// During a game a tap on a tile is a claim, which left no way to *look
  /// something up* — the single most common thing to want when an unfamiliar
  /// animal is standing in the road. Long-press worked, and nobody would ever
  /// have found it.
  static const String detailSentinel = '__detail__';

  static Future<String?> show({
    required BuildContext context,
    required Species species,
    required Scorecard card,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) =>
          WhoSpottedSheet(species: species, card: card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;
    final int already = card.timesClaimed(species.id);
    final int? chances = species.rarityTier.chancesPerDay;
    final bool spent = chances != null && already >= chances;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.sheet),
          boxShadow: AppColors.shadowMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.screen,
                Space.screen,
                Space.md,
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    species.commonName,
                    textAlign: TextAlign.center,
                    style: AppText.title2,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    spent
                        ? 'Already claimed today'
                        : 'Who spotted it?  ·  ${species.points} pts',
                    style: AppText.caption.copyWith(
                      color: spent ? AppColors.textMuted : style.accent,
                      fontVariations: AppFonts.weight(700),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  // Sits above the names rather than below them: "what is
                  // that?" comes before "who saw it first", and the animal is
                  // usually still in view while this sheet is open.
                  _FieldGuideButton(
                    tint: style.accent,
                    onTap: () => Navigator.of(
                      context,
                    ).pop(WhoSpottedSheet.detailSentinel),
                  ),
                ],
              ),
            ),
            if (!spent) ...<Widget>[
              const Divider(height: 1, color: AppColors.outline),
              ...card.players.map(
                (Player p) => _PlayerRow(
                  player: p,
                  points: card.pointsFor(p.id),
                  onTap: () => Navigator.of(context).pop(p.id),
                ),
              ),
            ],
            if (already > 0) ...<Widget>[
              const Divider(height: 1, color: AppColors.outline),
              // Undo lives here rather than behind a long-press: a mis-assigned
              // animal is the most common mistake in a moving car, and it
              // should never take more than one tap to reach.
              ListTile(
                onTap: () =>
                    Navigator.of(context).pop(WhoSpottedSheet.unclaimSentinel),
                leading: const Icon(
                  Icons.undo_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
                title: Text(
                  'Undo last claim',
                  style: AppText.label.copyWith(color: AppColors.danger),
                ),
              ),
            ],
            const SizedBox(height: Space.sm),
          ],
        ),
      ),
    );
  }
}

/// "What is this?" — the escape hatch out of claiming and into the field guide.
class _FieldGuideButton extends StatelessWidget {
  const _FieldGuideButton({required this.tint, required this.onTap});

  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(Radii.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.lg,
            vertical: Space.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.menu_book_rounded, size: 17, color: tint),
              const SizedBox(width: Space.sm),
              Text(
                'Open the field guide',
                style: AppText.label.copyWith(
                  color: AppColors.textPrimary,
                  fontVariations: AppFonts.weight(700),
                ),
              ),
              const SizedBox(width: Space.xs),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.points,
    required this.onTap,
  });

  final Player player;
  final int points;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.screen),
      leading: AvatarBadge(avatar: player.avatar, ring: player.isOwner),
      title: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodyStrong,
            ),
          ),
          if (player.isOwner) ...<Widget>[
            const SizedBox(width: Space.sm),
            const _YouTag(),
          ],
        ],
      ),
      trailing: Text(
        '$points',
        style: AppText.label.copyWith(fontFeatures: AppText.tabular),
      ),
    );
  }
}

/// Marks the account holder. Their claims are the ones that reach the permanent
/// collection, so it matters that the right name gets tapped.
class _YouTag extends StatelessWidget {
  const _YouTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentWash,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        'YOU',
        style: AppText.overline.copyWith(color: AppColors.accent, fontSize: 9),
      ),
    );
  }
}
