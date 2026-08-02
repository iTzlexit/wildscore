import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../domain/species.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/avatar_badge.dart';

/// Live standings — one row per player, bar proportional to the leader.
///
/// A bar rather than a number alone because the interesting question in a car
/// is never "how many points do I have", it is "am I winning". A bar answers
/// that at a glance from the passenger seat.
class StandingsBoard extends StatefulWidget {
  const StandingsBoard({
    required this.card,
    required this.species,
    this.expanded = false,
    super.key,
  });

  final Scorecard card;
  final List<Species> species;

  /// True when the board owns the screen rather than sitting in a card. Every
  /// player's haul is then open by default, because there is room for it and
  /// hiding the interesting part behind a tap is only worth doing when space is
  /// scarce.
  final bool expanded;

  @override
  State<StandingsBoard> createState() => _StandingsBoardState();
}

class _StandingsBoardState extends State<StandingsBoard> {
  /// Which player's haul is open. In the cramped layout only one at a time.
  String? _open;

  /// Players whose full haul has been asked for. A good day produces more tags
  /// than anyone reads at a glance, so the list is capped until asked.
  final Set<String> _showAll = <String>{};

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
            expanded: widget.expanded || _open == ranked[i].id,
            roomy: widget.expanded,
            showAll: _showAll.contains(ranked[i].id),
            haul: _haulFor(ranked[i].id),
            onShowAll: () => setState(() => _showAll.add(ranked[i].id)),
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
    required this.roomy,
    required this.showAll,
    required this.haul,
    required this.onShowAll,
    required this.onTap,
  });

  final int rank;
  final Player player;
  final int points;
  final double fraction;
  final bool leading;
  final bool expanded;
  final bool roomy;
  final bool showAll;
  final List<_Haul> haul;
  final VoidCallback onShowAll;
  final VoidCallback onTap;

  /// Enough to show the day's best finds without becoming a wall. Rarest are
  /// sorted first, so the cut always falls on the least interesting end.
  static const int _cap = 6;

  @override
  Widget build(BuildContext context) {
    final Color bar = leading ? AppColors.accent : AppColors.outlineStrong;
    final int cap = roomy ? _cap * 2 : _cap;
    final bool trimmed = !showAll && haul.length > cap;
    final List<_Haul> shown = trimmed ? haul.sublist(0, cap) : haul;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: haul.isEmpty || roomy ? null : onTap,
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
                    AvatarBadge(
                      avatar: player.avatar,
                      size: 30,
                      ring: player.isOwner,
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        player.isOwner ? '${player.name} (you)' : player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong.copyWith(
                          fontSize: 14.5,
                          fontVariations: AppFonts.weight(leading ? 700 : 600),
                        ),
                      ),
                    ),
                    if (haul.isNotEmpty && !roomy)
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
                  // Rank column + avatar + gap, so the bar starts under the
                  // name rather than under the face.
                  padding: const EdgeInsets.only(left: 58),
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
              padding: const EdgeInsets.fromLTRB(58, Space.md, 0, Space.xs),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final _Haul h in shown) _HaulTag(haul: h),
                  if (trimmed)
                    _MoreTag(count: haul.length - cap, onTap: onShowAll),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The rest of a long haul, one tap away. Rarest are shown first, so what is
/// hidden behind this is always the ordinary end of someone's day.
class _MoreTag extends StatelessWidget {
  const _MoreTag({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(Radii.chip - 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip - 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.chip - 2),
            border: Border.all(color: AppColors.outlineStrong, width: 1.2),
          ),
          child: Text(
            '+$count more',
            style: AppText.caption.copyWith(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontVariations: AppFonts.weight(700),
            ),
          ),
        ),
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
