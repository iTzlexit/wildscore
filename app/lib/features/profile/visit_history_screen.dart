import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../domain/species.dart';
import '../../domain/visit.dart';
import '../../shared/date_format.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/avatar_badge.dart';
import '../scorecard/standings_board.dart';

/// Every day you have played, newest first.
///
/// Reached by tapping the lifetime points on the profile — because a total is
/// an answer without a story, and the story is what someone actually wants
/// months later. "Who was in the car at Satara in July, and did Sam really get
/// the wild dog" is the memory; 5,645 is only the receipt.
///
/// **Nothing is ever aged out.** A cap would be deleting the exact thing that
/// makes someone renew a season pass — a two-year-old drive is worth *more*
/// than last week's, not less. Long histories are handled by filtering and by
/// loading a page at a time, and anything a person genuinely does not want is
/// theirs to delete.
class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({
    required this.visits,
    required this.species,
    this.live,
    this.onDelete,
    super.key,
  });

  final List<Visit> visits;
  final List<Species> species;

  /// A drive still running. Shown at the top, unbanked and clearly marked.
  final Scorecard? live;

  /// Null when history cannot be edited. Returns the remaining visits.
  final Future<void> Function(Visit visit)? onDelete;

  static Future<void> open(
    BuildContext context, {
    required List<Visit> visits,
    required List<Species> species,
    Scorecard? live,
    Future<void> Function(Visit visit)? onDelete,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => VisitHistoryScreen(
          visits: visits,
          species: species,
          live: live,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  /// Drives rendered before "Show more". Each card is tall — a season of them
  /// built at once is a visibly slow screen on the phones this has to run on.
  static const int _page = 12;

  int? _year;
  int? _month;
  int _shown = _page;
  late List<Visit> _visits = widget.visits;

  List<int> get _years {
    final Set<int> years = <int>{for (final Visit v in _visits) v.endedAt.year};
    return years.toList()..sort((int a, int b) => b.compareTo(a));
  }

  /// Months that actually contain a drive in the chosen year. Offering all
  /// twelve when only three have anything in them is a filter that mostly
  /// returns nothing.
  List<int> get _months {
    final Set<int> months = <int>{
      for (final Visit v in _visits)
        if (_year == null || v.endedAt.year == _year) v.endedAt.month,
    };
    return months.toList()..sort((int a, int b) => b.compareTo(a));
  }

  List<Visit> get _filtered => <Visit>[
    for (final Visit v in _visits)
      if ((_year == null || v.endedAt.year == _year) &&
          (_month == null || v.endedAt.month == _month))
        v,
  ];

  Future<void> _delete(Visit visit) async {
    final bool ok =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Delete this drive?', style: AppText.title3),
            content: Text(
              // Said out loud, because the total is derived from the days. A
              // number that survived the deletion of its own evidence would be
              // worse than losing the points.
              'The day is removed, along with the ${visit.ownerPoints} points '
              'it added to your lifetime total. Species you spotted stay in '
              'your collection.',
              style: AppText.body,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: AppText.label),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: AppText.label.copyWith(
                    color: AppColors.danger,
                    fontVariations: AppFonts.weight(700),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) {
      return;
    }
    await widget.onDelete!(visit);
    if (mounted) {
      setState(() {
        _visits = <Visit>[
          for (final Visit v in _visits)
            if (v.endedAt != visit.endedAt) v,
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Visit> filtered = _filtered;
    final List<Visit> visible = filtered.take(_shown).toList();
    final int points = filtered.fold(0, (int s, Visit v) => s + v.ownerPoints);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your drives', style: AppText.title2),
        backgroundColor: AppColors.background,
      ),
      body: _visits.isEmpty && widget.live == null
          ? const _Empty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.xs,
                Space.screen,
                Space.xxl,
              ),
              children: <Widget>[
                if (widget.live != null) ...<Widget>[
                  _LiveCard(card: widget.live!, species: widget.species),
                  const SizedBox(height: Space.lg),
                ],
                if (_years.length > 1 || _months.length > 1) ...<Widget>[
                  _Filters(
                    years: _years,
                    months: _months,
                    year: _year,
                    month: _month,
                    onYear: (int? y) => setState(() {
                      _year = y;
                      _month = null;
                      _shown = _page;
                    }),
                    onMonth: (int? m) => setState(() {
                      _month = m;
                      _shown = _page;
                    }),
                  ),
                  const SizedBox(height: Space.md),
                ],
                Text(
                  '${filtered.length} '
                  '${filtered.length == 1 ? 'drive' : 'drives'} · $points '
                  'points',
                  style: AppText.label,
                ),
                const SizedBox(height: Space.lg),
                for (final Visit visit in visible)
                  _VisitCard(
                    visit: visit,
                    species: widget.species,
                    onDelete: widget.onDelete == null
                        ? null
                        : () => _delete(visit),
                  ),
                if (filtered.length > visible.length)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _shown += _page),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: AppColors.outlineStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.chip),
                        ),
                      ),
                      child: Text(
                        'Show ${filtered.length - visible.length} older '
                        '${filtered.length - visible.length == 1 ? 'drive' : 'drives'}',
                        style: AppText.label.copyWith(
                          color: AppColors.accent,
                          fontVariations: AppFonts.weight(700),
                        ),
                      ),
                    ),
                  ),
                // No "nothing here" state, because the filters cannot produce
                // one: only months that contain a drive are offered, and
                // choosing a year re-derives them.
              ],
            ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.years,
    required this.months,
    required this.year,
    required this.month,
    required this.onYear,
    required this.onMonth,
  });

  final List<int> years;
  final List<int> months;
  final int? year;
  final int? month;
  final ValueChanged<int?> onYear;
  final ValueChanged<int?> onMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (years.length > 1) ...<Widget>[
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _Chip(
                  label: 'All time',
                  selected: year == null,
                  onTap: () => onYear(null),
                ),
                for (final int y in years)
                  _Chip(
                    label: '$y',
                    selected: year == y,
                    onTap: () => onYear(year == y ? null : y),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
        ],
        if (months.length > 1)
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _Chip(
                  label: 'Any month',
                  selected: month == null,
                  onTap: () => onMonth(null),
                ),
                for (final int m in months)
                  _Chip(
                    label: monthName(m),
                    selected: month == m,
                    onTap: () => onMonth(month == m ? null : m),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.outline,
              ),
            ),
            child: Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 12,
                color: selected ? AppColors.accentInk : AppColors.textSecondary,
                fontVariations: AppFonts.weight(selected ? 700 : 500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Today's drive, still running. It belongs at the top of this list — someone
/// checking their drives mid-trip is looking for the one they are on.
class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.card, required this.species});

  final Scorecard card;
  final List<Species> species;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.screen),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  formatLongDate(card.startedAt),
                  style: AppText.title3,
                ),
              ),
              Text(
                'IN PLAY',
                style: AppText.overline.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Not banked yet — end the day on the Wild Score tab.',
            style: AppText.caption,
          ),
          const SizedBox(height: Space.md),
          StandingsBoard(card: card, species: species, expanded: true),
        ],
      ),
    );
  }
}

/// One finished drive, collapsed to a header until asked.
///
/// A season of expanded cards is a very long screen to scroll past to reach
/// last March. The header carries what identifies a day - when, who, what it
/// was worth - and the standings unfold underneath on a tap.
class _VisitCard extends StatefulWidget {
  const _VisitCard({required this.visit, required this.species, this.onDelete});

  final Visit visit;
  final List<Species> species;
  final VoidCallback? onDelete;

  @override
  State<_VisitCard> createState() => _VisitCardState();
}

class _VisitCardState extends State<_VisitCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final Visit visit = widget.visit;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: AppColors.outline),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                borderRadius: BorderRadius.circular(Radii.card),
                child: Padding(
                  padding: const EdgeInsets.all(Space.screen),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              formatLongDate(visit.endedAt),
                              style: AppText.title3,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              visit.wasSolo
                                  ? 'On your own · ${visit.claims.length} claimed'
                                  : '${visit.players.length} played · ${visit.claims.length} claimed',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${visit.ownerPoints}',
                        style: AppText.title3.copyWith(
                          color: AppColors.accent,
                          fontFeatures: AppText.tabular,
                        ),
                      ),
                      const SizedBox(width: Space.sm),
                      Icon(
                        _open
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.screen,
                  0,
                  Space.screen,
                  Space.screen,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (!visit.wasSolo) ...<Widget>[
                      Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.sm,
                        children: <Widget>[
                          for (final Player p in visit.asScorecard.standings)
                            _Passenger(
                              player: p,
                              points: visit.pointsFor(p.id),
                              won: p.id == visit.asScorecard.standings.first.id,
                            ),
                        ],
                      ),
                      const SizedBox(height: Space.lg),
                    ],
                    const Divider(height: 1, color: AppColors.outline),
                    const SizedBox(height: Space.md),
                    StandingsBoard(
                      card: visit.asScorecard,
                      species: widget.species,
                      expanded: true,
                    ),
                    if (widget.onDelete != null) ...<Widget>[
                      const SizedBox(height: Space.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: widget.onDelete,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                          ),
                          label: Text(
                            'Delete this drive',
                            style: AppText.label.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Passenger extends StatelessWidget {
  const _Passenger({
    required this.player,
    required this.points,
    required this.won,
  });

  final Player player;
  final int points;
  final bool won;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: won ? AppColors.accentWash : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.chip + 4),
        border: Border.all(
          color: won
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AvatarBadge(avatar: player.avatar, size: 24),
          const SizedBox(width: 6),
          Text(
            player.isOwner ? 'You' : player.name,
            style: AppText.caption.copyWith(
              color: AppColors.textPrimary,
              fontVariations: AppFonts.weight(won ? 700 : 600),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$points',
            style: AppText.caption.copyWith(
              color: won ? AppColors.accent : AppColors.textMuted,
              fontFeatures: AppText.tabular,
              fontVariations: AppFonts.weight(700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.route_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: Space.lg),
            Text('No drives yet', style: AppText.title3),
            const SizedBox(height: Space.sm),
            Text(
              'Start one on the Wild Score tab. When you end the day it is '
              'saved here, with everyone who was in the car.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
