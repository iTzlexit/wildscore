import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../domain/sighting_context.dart';
import '../../domain/species.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/avatar_badge.dart';
import '../codex/species_detail_screen.dart';

/// Live standings — one row per player, each with a tally of their day.
///
/// A bar rather than a number alone because the interesting question in a car
/// is never "how many points do I have", it is "am I winning". A bar answers
/// that at a glance from the passenger seat.
///
/// It was drawn as a fraction of the leader's score, which meant the leader was
/// always exactly full — one impala to nothing looked like a finished game. It
/// is now a tally against a benchmark: see [_TallyBar] and `_benchmark`.
class StandingsBoard extends StatefulWidget {
  const StandingsBoard({
    required this.card,
    required this.species,
    this.expanded = false,
    this.onRemoveClaim,
    this.onSpotFor,
    this.onQuizFor,
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

  /// Opens the question this player has unlocked.
  final ValueChanged<Player>? onQuizFor;

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

    // What a full bar means.
    //
    // It used to mean "whoever is winning", so the first impala of the day
    // filled somebody's bar completely and the game looked over before it
    // started. Alex spotted that immediately.
    //
    // Two changes. There is a floor, so an early lead is a small bar on a long
    // road rather than a finished one; and the leader is held at about 87% of
    // the track, so the bar always reads as *still climbing*. Nobody is ever
    // full, which is the honest picture of a day that has not ended.
    final double benchmark = _benchmark(leader);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < ranked.length; i++)
          _Row(
            rank: i + 1,
            player: ranked[i],
            points: card.pointsFor(ranked[i].id),
            fraction: card.pointsFor(ranked[i].id) / benchmark,
            tally: _tallyFor(ranked[i].id),
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
            // A question is earned per *unique* animal this player has found,
            // plus their share of the ones handed out for time passing.
            onQuiz:
                widget.onQuizFor == null ||
                    !card.trivia.hasWaiting(
                      ranked[i].id,
                      card.uniqueSpotsFor(ranked[i].id),
                      timed: card.timedQuestionsFor(ranked[i].id),
                    )
                ? null
                : () => widget.onQuizFor!(ranked[i]),
            onTap: () => setState(
              () => _open = _open == ranked[i].id ? null : ranked[i].id,
            ),
          ),
      ],
    );
  }

  /// How long the road is, in points.
  ///
  /// A floor of 600 — about a lion and a couple of good antelope, which is a
  /// respectable morning — so the first sighting of the day moves the bar a
  /// little rather than filling it. Past that the leader sets the pace, held
  /// short of the end so there is always somewhere left to go.
  static double _benchmark(int leader) =>
      leader * 1.15 < 600 ? 600 : leader * 1.15;

  /// Every sighting this player has made, in the order they made them.
  ///
  /// **The bar is a tally, not a percentage.** Alex asked for a score that
  /// visibly adds up, and this is the honest way to draw it: each spot is its
  /// own block, as wide as it was worth and coloured by what it was, so a
  /// morning of impala looks like a morning of impala and one leopard looks
  /// like one leopard.
  List<_Tally> _tallyFor(String playerId) {
    final Map<String, Species> byId = <String, Species>{
      for (final Species s in widget.species) s.id: s,
    };
    return <_Tally>[
      for (final Claim c in widget.card.claims)
        if (c.playerId == playerId)
          _Tally(
            points: c.points,
            colour:
                byId[c.speciesId]?.rarityTier.style.accent ?? AppColors.accent,
          ),
    ];
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
        for (final String v in c.variants) {
          (marks[c.speciesId] ??= <String>{}).add(v.toUpperCase());
        }
        for (final SightingExtra e in c.extras) {
          (marks[c.speciesId] ??= <String>{}).add(e.short);
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

/// One sighting, as it appears on the tally bar.
class _Tally {
  const _Tally({required this.points, required this.colour});

  final int points;
  final Color colour;
}

/// The day, drawn as blocks.
///
/// **Replaces a plain progress bar that read "whoever is winning is finished".**
/// It filled completely for the leader, so the first impala of the morning gave
/// somebody a full bar — which is both wrong and deflating, and Alex called it
/// out on the first drive.
///
/// What it draws now is a tally: one block per sighting, as wide as that
/// sighting was worth, coloured by what the animal was. A morning of impala is
/// a row of small grey-green blocks; one leopard is a single wide gold one. You
/// can see the shape of somebody's day from across the car without reading a
/// number, which is the thing a scorecard is for.
class _TallyBar extends StatelessWidget {
  const _TallyBar({
    required this.tally,
    required this.fraction,
    required this.fallback,
  });

  final List<_Tally> tally;

  /// How far along the road they are — see `_StandingsBoardState._benchmark`.
  final double fraction;

  /// Used when there is nothing to draw blocks from yet.
  final Color fallback;

  /// Past this many, the gaps between blocks cost more than they say.
  ///
  /// A good day is thirty-plus sightings and a one-pixel gap between each is
  /// visual noise, so a long day merges into bands of colour instead.
  static const int _maxBlocks = 18;

  @override
  Widget build(BuildContext context) {
    final int total = tally.fold(0, (int sum, _Tally t) => sum + t.points);

    return SizedBox(
      height: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: <Widget>[
            // The road, full width, and it has to be visible or the blocks
            // look like they are floating on the card with nothing to run
            // along. `surfaceAlt` on white is not a colour anybody can see.
            const Positioned.fill(child: ColoredBox(color: AppColors.outline)),
            TweenAnimationBuilder<double>(
              // Animated so a claim visibly moves the bar. That movement is
              // the feedback the game runs on.
              tween: Tween<double>(end: fraction.clamp(0, 1)),
              duration: const Duration(milliseconds: 650),
              curve: Motion.standard,
              builder: (BuildContext context, double value, _) =>
                  FractionallySizedBox(
                    widthFactor: value == 0 ? 0.0001 : value,
                    // Both factors. Without `heightFactor` the box takes its
                    // height from the child, and a `ColoredBox` has no size of
                    // its own — so every block painted eight pixels of
                    // nothing, which is exactly as visible as it sounds.
                    heightFactor: 1,
                    child: total <= 0
                        ? ColoredBox(color: fallback)
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _blocks(total),
                          ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _blocks(int total) {
    final bool separate = tally.length <= _maxBlocks;
    return <Widget>[
      for (int i = 0; i < tally.length; i++) ...<Widget>[
        Expanded(
          // Flex has to be an int, so points are the flex — which is exactly
          // the proportion wanted. A five-point warthog next to a 250-point
          // leopard is a sliver next to a slab, and that is the truth of it.
          flex: tally[i].points < 1 ? 1 : tally[i].points,
          child: ColoredBox(color: tally[i].colour),
        ),
        if (separate && i != tally.length - 1)
          const SizedBox(width: 1.5, child: ColoredBox(color: Colors.white)),
      ],
    ];
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.rank,
    required this.player,
    required this.points,
    required this.fraction,
    required this.tally,
    required this.leading,
    required this.expanded,
    required this.roomy,
    required this.showAll,
    required this.haul,
    required this.onShowAll,
    required this.onRemove,
    required this.onSpot,
    required this.onQuiz,
    required this.onTap,
  });

  final int rank;
  final Player player;
  final int points;
  final double fraction;

  /// Each sighting, oldest first. Drawn as its own block on the bar.
  final List<_Tally> tally;
  final bool leading;
  final bool expanded;
  final bool roomy;
  final bool showAll;
  final List<_Haul> haul;
  final VoidCallback onShowAll;
  final ValueChanged<Species>? onRemove;
  final VoidCallback? onSpot;

  /// A question waiting for this player. Null when they have not earned one.
  final VoidCallback? onQuiz;
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
                    // Counts up rather than jumping.
                    //
                    // Alex asked for a score that is visibly *tallied* after
                    // each spot, and this is the half of it people feel: a
                    // leopard is 250 points arriving one at a time, which is
                    // worth watching. It reads from the previous value on its
                    // own — TweenAnimationBuilder animates from wherever it
                    // had got to when the end changes.
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: points.toDouble()),
                      duration: const Duration(milliseconds: 650),
                      curve: Motion.standard,
                      builder: (BuildContext context, double value, _) => Text(
                        '${value.round()}',
                        style: AppText.title3.copyWith(
                          color: leading
                              ? AppColors.accent
                              : AppColors.textPrimary,
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                    ),
                    if (onQuiz != null) ...<Widget>[
                      const SizedBox(width: Space.sm),
                      _QuizButton(onTap: onQuiz!, name: player.name),
                    ],
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
                  child: _TallyBar(
                    tally: tally,
                    fraction: fraction,
                    fallback: bar,
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
/// A question waiting on this player's row.
///
/// Only rendered when there is one, which is the whole design: the badge is
/// the notification. A greyed-out quiz button on every row all morning would
/// be four permanent advertisements for something nobody has earned yet.
///
/// **It says QUIZ and it pulses.** A lone question mark was not enough — Alex's
/// note, and watching somebody use it makes it obvious: a small "?" beside a
/// name reads as a help button, not as *you have something to claim*. A word
/// and a slow pulse say it from across the car.
class _QuizButton extends StatefulWidget {
  const _QuizButton({required this.onTap, required this.name});

  final VoidCallback onTap;
  final String name;

  @override
  State<_QuizButton> createState() => _QuizButtonState();
}

class _QuizButtonState extends State<_QuizButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'A question is waiting for ${widget.name}',
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (BuildContext context, Widget? child) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.accent.withValues(
                  alpha: 0.20 + 0.35 * _pulse.value,
                ),
                blurRadius: 6 + 10 * _pulse.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
        child: Material(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 28,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.quiz_rounded,
                    size: 13,
                    color: AppColors.accentInk,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'QUIZ',
                    style: AppText.overline.copyWith(
                      color: AppColors.accentInk,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
              label: 'Remove from $player',
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
