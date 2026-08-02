import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../domain/species.dart';
import '../../domain/visit.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/avatar_badge.dart';
import '../scorecard/standings_board.dart';

/// Every day you have played, newest first.
///
/// Reached by tapping the lifetime points on the profile — because a total is
/// an answer without a story, and the story is what someone actually wants
/// months later. "Who was in the car at Satara in July, and did Sam really get
/// the wild dog" is the memory; 5,645 is only the receipt.
class VisitHistoryScreen extends StatelessWidget {
  const VisitHistoryScreen({
    required this.visits,
    required this.species,
    super.key,
  });

  final List<Visit> visits;
  final List<Species> species;

  static Future<void> open(
    BuildContext context, {
    required List<Visit> visits,
    required List<Species> species,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            VisitHistoryScreen(visits: visits, species: species),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int total = visits.fold(0, (int s, Visit v) => s + v.ownerPoints);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your drives', style: AppText.title2),
        backgroundColor: AppColors.background,
      ),
      body: visits.isEmpty
          ? const _Empty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.xs,
                Space.screen,
                Space.xxl,
              ),
              children: <Widget>[
                Text(
                  '${visits.length} ${visits.length == 1 ? 'drive' : 'drives'} '
                  '· $total points',
                  style: AppText.label,
                ),
                const SizedBox(height: Space.lg),
                for (final Visit visit in visits)
                  _VisitCard(visit: visit, species: species),
              ],
            ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.species});

  final Visit visit;
  final List<Species> species;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Container(
        padding: const EdgeInsets.all(Space.screen),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: AppColors.outline),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _formatDate(visit.endedAt),
                    style: AppText.title3,
                  ),
                ),
                Text(
                  '+${visit.ownerPoints}',
                  style: AppText.title3.copyWith(
                    color: AppColors.accent,
                    fontFeatures: AppText.tabular,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              visit.wasSolo
                  ? 'Solo · ${visit.claims.length} claimed'
                  : '${visit.players.length} in the car · '
                        '${visit.claims.length} claimed',
              style: AppText.caption,
            ),
            if (!visit.wasSolo) ...<Widget>[
              const SizedBox(height: Space.md),
              // Who was with you, faces and all. This is the part of a trip
              // people actually reminisce about.
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
            ],
            const SizedBox(height: Space.lg),
            const Divider(height: 1, color: AppColors.outline),
            const SizedBox(height: Space.md),
            StandingsBoard(
              card: visit.asScorecard,
              species: species,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }

  /// "2 August 2026". No package for this — one format, one locale for now,
  /// and `intl` is 600 KB to save nine lines.
  static String _formatDate(DateTime date) {
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
