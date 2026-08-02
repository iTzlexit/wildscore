import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../shared/theme.dart';

/// Live standings — one row per player, bar proportional to the leader.
///
/// A bar rather than a number alone because the interesting question in a car
/// is never "how many points do I have", it is "am I winning". A bar answers
/// that at a glance from the passenger seat.
class StandingsBoard extends StatelessWidget {
  const StandingsBoard({required this.card, super.key});

  final Scorecard card;

  @override
  Widget build(BuildContext context) {
    final List<Player> ranked = card.standings;
    final int leader = ranked.isEmpty ? 0 : card.pointsFor(ranked.first.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < ranked.length; i++)
          _Row(
            rank: i + 1,
            player: ranked[i],
            points: card.pointsFor(ranked[i].id),
            // Everyone on zero gets an empty bar rather than a full one.
            fraction: leader == 0 ? 0 : card.pointsFor(ranked[i].id) / leader,
            leading: i == 0 && leader > 0,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.rank,
    required this.player,
    required this.points,
    required this.fraction,
    required this.leading,
  });

  final int rank;
  final Player player;
  final int points;
  final double fraction;
  final bool leading;

  @override
  Widget build(BuildContext context) {
    final Color bar = leading ? AppColors.accent : AppColors.outlineStrong;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 20,
                child: Text(
                  '$rank',
                  style: AppText.caption.copyWith(
                    fontFeatures: AppText.tabular,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong.copyWith(
                    fontSize: 14.5,
                    fontVariations: AppFonts.weight(leading ? 700 : 600),
                  ),
                ),
              ),
              Text(
                '$points',
                style: AppText.title3.copyWith(
                  color: leading ? AppColors.accent : AppColors.textPrimary,
                  fontFeatures: AppText.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                // Animated so a claim visibly moves the bar. That movement is
                // the feedback the game runs on.
                tween: Tween<double>(begin: 0, end: fraction.clamp(0, 1)),
                duration: const Duration(milliseconds: 420),
                curve: Motion.standard,
                builder: (BuildContext context, double value, _) =>
                    LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      backgroundColor: AppColors.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation<Color>(bar),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
