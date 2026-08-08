import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../domain/species.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/avatar_badge.dart';
import '../codex/species_detail_screen.dart';

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
    this.onRemoveClaim,
    this.onSpotFor,
    super.key,
  });

  final Scorecard card;
  final List<Species> species;

  /// True when the board owns the screen rather than sitting in a card. Every
  /// player's haul is then open by default, because there is room for it and
  /// hiding the interesting part behind a tap is only worth doing when space is
  /// scarce.
  final bool expanded;

  /// Takes one claim back off a player. Null for a finished day — history is
  /// not editable, or it is not history.
  ///
  /// Reachable by tapping the animal's own tag, which is where a person looks
  /// when they notice the kudu went to the wrong name. The undo in the claim
  /// sheet only reverses the *most recent* claim, which is no use an hour
  /// later.
  final void Function(Player player, Species species)? onRemoveClaim;

  /// Opens the picker for this player. Live games only.
  ///
  /// Claiming starts from the person, not the animal, because that is the order
  /// it happens in a car — somebody shouts a name before anyone knows what they
  /// are looking at.
  final ValueChanged<Player>? onSpotFor;

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
            onRemove: widget.onRemoveClaim == null
                ? null
                : (Species s) => widget.onRemoveClaim!(ranked[i], s),
            onSpot: widget.onSpotFor == null
                ? null
                : () => widget.onSpotFor!(ranked[i]),
            onTap: () => setState(
              () => _open = _open == ranked[i].id ? null : ranked[i].id,
            ),
          ),
      ],
    );
  }

  /// What this player claimed today: counts and points banked, rarest first.
  ///
  /// Points come from the claims rather than from the species, because a claim
  /// stores what it was worth on the day. A tier revalued next season must not
  /// silently rewrite last winter's card.
  List<_Haul> _haulFor(String playerId) {
    final Map<String, int> counts = <String, int>{};
    final Map<String, int> points = <String, int>{};
    final Map<String, Set<String>> roads = <String, Set<String>>{};
    final Map<String, Set<String>> marks = <String, Set<String>>{};
    for (final Claim c in widget.card.claims) {
      if (c.playerId == playerId) {
        counts[c.speciesId] = (counts[c.speciesId] ?? 0) + 1;
        points[c.speciesId] = (points[c.speciesId] ?? 0) + c.points;
        if (c.road != null) {
          (roads[c.speciesId] ??= <String>{}).add(c.road!);
        }
        if (c.context.short.isNotEmpty) {
          (marks[c.speciesId] ??= <String>{}).add(c.context.short);
        }
        if (c.variant) {
          if (_lookup(c.speciesId)?.variant case final SpeciesVariant v) {
            (marks[c.speciesId] ??= <String>{}).add(v.label.toUpperCase());
          }
        }
      }
    }
    final List<_Haul> haul = <_Haul>[
      for (final MapEntry<String, int> e in counts.entries)
        if (_lookup(e.key) case final Species s)
          _Haul(
            species: s,
            count: e.value,
            points: points[e.key] ?? 0,
            roads: roads[e.key] ?? const <String>{},
            marks: marks[e.key] ?? const <String>{},
          ),
    ];
    // By what the animal is worth, not by what the stack totals — two impala
    // must not outrank a leopard.
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
  const _Haul({
    required this.species,
    required this.count,
    required this.points,
    this.roads = const <String>{},
    this.marks = const <String>{},
  });

  /// Why this stack is worth what it is: `MALE`, `ALONE`, `JAM`.
  ///
  /// Worth the space because the number on its own invites an argument. "Lion
  /// 200" reads as a mistake; "Lion · MALE · ALONE · 200" reads as a very good
  /// morning, and settles the question before anybody asks it.
  final Set<String> marks;

  /// Roads this player found it on. Empty when location was off, refused, or
  /// the species is one whose whereabouts are never recorded.
  final Set<String> roads;

  /// `S100`, or `S100 +1` when the same animal turned up in two places. The
  /// full list would not fit on a tag and is not what anybody is asking.
  String? get where {
    if (roads.isEmpty) {
      return null;
    }
    final String first = roads.first.split(' · ').first;
    return roads.length == 1 ? first : '$first +${roads.length - 1}';
  }

  final Species species;

  /// Separate sightings, in different places. Two hyena at the same kill is one
  /// claim — see the rules screen.
  final int count;

  /// What the stack is worth in total, summed from the claims.
  final int points;
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
    required this.onRemove,
    required this.onSpot,
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
  final ValueChanged<Species>? onRemove;
  final VoidCallback? onSpot;
  final VoidCallback onTap;

  /// Enough to show the day's best finds without becoming a wall. Rarest are
  /// sorted first, so the cut always falls on the least interesting end.
  static const int _cap = 6;

  /// What tapping an animal in somebody's haul does.
  ///
  /// It used to go straight to "Take it back?", which was wrong in both
  /// directions: on a finished drive there was nothing to take back and the tag
  /// was dead, and on a live one the only thing you could do to the leopard you
  /// had just found was delete it. Looking at the animal is the commoner wish
  /// by far — somebody says "what *is* a civet" and the tag is where they tap.
  ///
  /// So: a choice when both are possible, and straight to the card when removal
  /// is not. A menu with one item is not a menu.
  Future<void> _openTag(BuildContext context, _Haul haul) async {
    if (onRemove == null) {
      await SpeciesDetailScreen.open(context, haul.species);
      return;
    }
    final _TagAction? choice = await showModalBottomSheet<_TagAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          _TagSheet(haul: haul, player: player.name),
    );
    if (!context.mounted || choice == null) {
      return;
    }
    switch (choice) {
      case _TagAction.view:
        await SpeciesDetailScreen.open(context, haul.species);
      case _TagAction.remove:
        onRemove!(haul.species);
    }
  }

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
                    if (onSpot != null) ...<Widget>[
                      const SizedBox(width: Space.sm),
                      _SpotButton(onTap: onSpot!, name: player.name),
                    ],
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
                  for (final _Haul h in shown)
                    _HaulTag(haul: h, onTap: () => _openTag(context, h)),
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

/// "They spotted something." The primary action of the game, on the row of the
/// person who shouted.
///
/// An eye rather than a plus, because the verb is *spotted* and a plus reads as
/// "add a row". Binoculars would be better still and are not in the Material
/// icon font; drawing them by hand is not worth it at 17pt, where two small
/// circles read as two small circles.
///
/// Outlined rather than filled. A filled accent block on every row competed
/// with the score for attention, and the score is what people are reading.
class _SpotButton extends StatelessWidget {
  const _SpotButton({required this.onTap, required this.name});

  final VoidCallback onTap;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add a sighting for $name',
      child: Material(
        color: AppColors.accentWash,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            width: 32,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.visibility_rounded,
              size: 17,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// One species in a player's stack: what it is, how many, what it paid.
///
/// The count and the total both earn their space. Two of something is a
/// different day from one of it, and "African Wildcat ×2 · 1500" answers both
/// "what did they get" and "why are they winning" without any arithmetic.
class _HaulTag extends StatelessWidget {
  const _HaulTag({required this.haul, required this.onTap});

  final _Haul haul;

  /// Opens the animal, or the choice between opening it and taking it back.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = haul.species.rarityTier.style;

    return Material(
      color: style.fill,
      borderRadius: BorderRadius.circular(Radii.chip - 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip - 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
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
              const SizedBox(width: 6),
              Container(
                width: 1,
                height: 10,
                color: style.accent.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 6),
              Text(
                '${haul.points}',
                style: AppText.caption.copyWith(
                  fontSize: 11,
                  color: style.accent,
                  fontVariations: AppFonts.weight(600),
                  fontFeatures: AppText.tabular,
                ),
              ),
              for (final String mark in haul.marks) ...<Widget>[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: style.accent.withValues(alpha: 0.16),
                  ),
                  child: Text(
                    mark,
                    style: AppText.label.copyWith(
                      fontSize: 8.5,
                      color: style.accent,
                    ),
                  ),
                ),
              ],
              // Where it was found, when the phone could say. This is the part
              // people actually recall — "the leopard on the S100" is a memory
              // in a way that "the leopard" is not.
              if (haul.where case final String road) ...<Widget>[
                const SizedBox(width: 6),
                Container(
                  width: 1,
                  height: 10,
                  color: style.accent.withValues(alpha: 0.35),
                ),
                const SizedBox(width: 6),
                Text(
                  road,
                  style: AppText.caption.copyWith(
                    fontSize: 10.5,
                    color: style.accent.withValues(alpha: 0.8),
                    fontVariations: AppFonts.weight(600),
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

enum _TagAction { view, remove }

/// The two things worth doing to an animal sitting in somebody's haul.
///
/// Deliberately not a confirmation — removal still raises its own dialog after
/// this. A sheet row is one thumb-slip away in a moving car, and an hour of
/// scoring is not something to lose to a bump in the road.
class _TagSheet extends StatelessWidget {
  const _TagSheet({required this.haul, required this.player});

  final _Haul haul;
  final String player;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = haul.species.rarityTier.style;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.sheet),
          border: Border.all(color: AppColors.outline),
        ),
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
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: style.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          haul.species.commonName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.title3,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          <String>[
                            haul.species.rarityTier.label,
                            if (haul.count > 1) '${haul.count} sightings',
                            '${haul.points} points',
                            if (haul.where case final String road) road,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            _SheetRow(
              icon: Icons.menu_book_rounded,
              label: 'View this animal',
              onTap: () => Navigator.of(context).pop(_TagAction.view),
            ),
            const Divider(height: 1, color: AppColors.outline),
            _SheetRow(
              icon: Icons.undo_rounded,
              label: 'Take it back off $player',
              danger: true,
              onTap: () => Navigator.of(context).pop(_TagAction.remove),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color tint = danger ? AppColors.danger : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.lg,
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 19, color: tint),
            const SizedBox(width: Space.md),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                  color: tint,
                  fontVariations: AppFonts.weight(600),
                ),
              ),
            ),
          ],
        ),
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
