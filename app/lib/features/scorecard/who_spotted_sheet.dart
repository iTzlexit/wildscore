import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../domain/species.dart';
import '../../shared/theme.dart';

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
                ],
              ),
            ),
            if (!spent)
              ...card.players.map(
                (Player p) => _PlayerRow(
                  player: p,
                  points: card.pointsFor(p.id),
                  onTap: () => Navigator.of(context).pop(p.id),
                ),
              ),
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
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.accentWash,
          shape: BoxShape.circle,
        ),
        child: Text(
          player.initial,
          style: AppText.title3.copyWith(color: AppColors.accent),
        ),
      ),
      title: Text(player.name, style: AppText.bodyStrong),
      trailing: Text(
        '$points',
        style: AppText.label.copyWith(fontFeatures: AppText.tabular),
      ),
    );
  }
}
