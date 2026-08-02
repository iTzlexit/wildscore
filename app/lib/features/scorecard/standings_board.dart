import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../domain/species.dart';
import '../../shared/theme.dart';

/// Live standings — one row per player, bar proportional to the leader.
///
/// A bar rather than a number alone because the interesting question in a car
/// is never "how many points do I have", it is "am I winning". A bar answers
/// that at a glance from the passenger seat.
class StandingsBoard extends StatefulWidget {
  const StandingsBoard({required this.card, required this.species, super.key});

  final Scorecard card;
  final List<Species> species;

  @override
  State<StandingsBoard> createState() => _StandingsBoardState();
}

class _StandingsBoardState extends State<StandingsBoard> {
  /// Which player's haul is expanded. Only one at a time — the panel is a
  /// glance, not a report.
  String? _open;

  @override
  Widget build(BuildContext context) {
    final Scorecard card = widget.card;
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
            expanded: _open == ranked[i].id,
            haul: _haulFor(ranked[i].id),
            onTap: () => setState(
              () => _open = _open == ranked[i].id ? null : ranked[i].id,
            ),
          ),
      ],
    );
  }

  /// What this player claimed today, with counts, rarest first.
  List<_Haul> _haulFor(String playerId) {
    final Map<String, int> counts = <String, int>{};
    for (final Claim c in widget.card.claims) {
      if (c.playerId == playerId) {
        counts[c.speciesId] = (counts[c.speciesId] ?? 0) + 1;
      }
    }
    final List<_Haul> haul = <_Haul>[
      for (final MapEntry<String, int> e in counts.entries)
        if (_lookup(e.key) case final Species s)
          _Haul(species: s, count: e.value),
    ];
    haul.sort((_Haul a, _Haul b) {
      final int byTier = b.species.points.compareTo(a.species.points);
      return byTier != 0
          ? byTier
          : a.species.commonName.compareTo(b.species.commonName);
    });
    return haul;
  }

  Species? _lookup(String id) {
    for (final Species s in widget.species) {
      if (s.id == id) {
        return s;
      }
    }
    return null;
  }
}

class _Haul {
  const _Haul({required this.species, required this.count});

  final Species species;
  final int count;
}

class _Row extends StatelessWidget {
  const _Row({
    required this.rank,
    required this.player,
    required this.points,
    required this.fraction,
    required this.leading,
    required this.expanded,
    required this.haul,
    required this.onTap,
  });

  final int rank;
  final Player player;
  final int points;
  final double fraction;
  final bool leading;
  final bool expanded;
  final List<_Haul> haul;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bar = leading ? AppColors.accent : AppColors.outlineStrong;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: haul.isEmpty ? null : onTap,
            borderRadius: BorderRadius.circular(Space.sm),
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
                    if (haul.isNotEmpty)
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    const SizedBox(width: Space.xs),
                    Text(
                      '$points',
                      style: AppText.title3.copyWith(
                        color: leading
                            ? AppColors.accent
                            : AppColors.textPrimary,
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
                      // Animated so a claim visibly moves the bar. That
                      // movement is the feedback the game runs on.
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
          ),
          // What they actually got, in rarity colours. This is the bragging
          // surface — "I got the leopard" is the whole point of the game.
          if (expanded && haul.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, Space.md, 0, Space.xs),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final _Haul h in haul) _HaulTag(haul: h),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HaulTag extends StatelessWidget {
  const _HaulTag({required this.haul});

  final _Haul haul;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = haul.species.rarityTier.style;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(Radii.chip - 2),
        border: Border.all(color: style.accent, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            haul.species.commonName,
            style: AppText.caption.copyWith(
              fontSize: 11.5,
              color: style.accent,
              fontVariations: AppFonts.weight(700),
            ),
          ),
          if (haul.count > 1) ...<Widget>[
            const SizedBox(width: 5),
            Text(
              '×${haul.count}',
              style: AppText.caption.copyWith(
                fontSize: 11,
                color: style.accent,
                fontVariations: AppFonts.weight(800),
                fontFeatures: AppText.tabular,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
