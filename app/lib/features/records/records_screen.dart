import 'package:flutter/material.dart';

import '../../domain/records.dart';
import '../../domain/species.dart';
import '../../domain/visit.dart';
import '../../shared/date_format.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/avatar_badge.dart';

/// Personal bests, and the running score against the people you play with.
///
/// This tab was a locked "leaderboard coming soon" placeholder. With no server
/// in the plan it was never going to arrive, and a permanently locked tab in a
/// paid app is worse than one fewer tab.
///
/// What replaced it suits the game better anyway. The person you want to beat
/// in Kruger is not a stranger on a global board — it is your brother, and he
/// was sitting next to you.
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({required this.visits, required this.species, super.key});

  final List<Visit> visits;
  final List<Species> species;

  @override
  Widget build(BuildContext context) {
    final Records records = Records.from(visits, species);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const AppHeader(),
            Expanded(
              child: records.isEmpty
                  ? const _Empty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        Space.screen,
                        Space.sm,
                        Space.screen,
                        110,
                      ),
                      children: <Widget>[
                        Text('Records', style: AppText.title1),
                        const SizedBox(height: Space.lg),
                        _Totals(records: records),
                        const SizedBox(height: Space.xl),
                        if (records.bestDrive != null) ...<Widget>[
                          const _SectionLabel('YOUR BEST DAY'),
                          const SizedBox(height: Space.md),
                          _BestDrive(visit: records.bestDrive!),
                          const SizedBox(height: Space.xl),
                        ],
                        if (records.rarest != null) ...<Widget>[
                          const _SectionLabel('RAREST THING YOU HAVE CALLED'),
                          const SizedBox(height: Space.md),
                          _Rarest(find: records.rarest!),
                          const SizedBox(height: Space.xl),
                        ],
                        if (records.rivals.isNotEmpty) ...<Widget>[
                          const _SectionLabel('HOW IT STANDS'),
                          const SizedBox(height: Space.xs),
                          Text(
                            'Everyone you have shared a car with, and who has '
                            'won more days.',
                            style: AppText.caption.copyWith(height: 1.45),
                          ),
                          const SizedBox(height: Space.md),
                          for (final Rival rival in records.rivals)
                            _RivalRow(rival: rival),
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

class _Totals extends StatelessWidget {
  const _Totals({required this.records});

  final Records records;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _Stat(
            value: '${records.drivesPlayed}',
            label: records.drivesPlayed == 1 ? 'DRIVE' : 'DRIVES',
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: _Stat(value: '${records.sightings}', label: 'CALLED'),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: _Stat(value: '${records.lifetimePoints}', label: 'POINTS'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: AppText.title1.copyWith(
              fontSize: 24,
              color: AppColors.accent,
              fontFeatures: AppText.tabular,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.overline.copyWith(fontSize: 8.5, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _BestDrive extends StatelessWidget {
  const _BestDrive({required this.visit});

  final Visit visit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.screen),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.accent, width: 1.5),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(formatLongDate(visit.endedAt), style: AppText.title3),
                const SizedBox(height: 2),
                Text(
                  visit.wasSolo
                      ? 'On your own'
                      : '${visit.players.length} in the car',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Text(
            '${visit.ownerPoints}',
            style: AppText.display.copyWith(
              fontSize: 38,
              color: AppColors.accent,
              fontFeatures: AppText.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _Rarest extends StatelessWidget {
  const _Rarest({required this.find});

  final RarestFind find;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = find.species.rarityTier.style;

    return Container(
      padding: const EdgeInsets.all(Space.screen),
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: style.accent, width: style.borderWidth),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  find.species.rarityTier.label.toUpperCase(),
                  style: AppText.overline.copyWith(color: style.accent),
                ),
                const SizedBox(height: 3),
                Text(find.species.commonName, style: AppText.title2),
                const SizedBox(height: 2),
                Text(formatLongDate(find.on), style: AppText.caption),
              ],
            ),
          ),
          Text(
            '${find.species.points}',
            style: AppText.title1.copyWith(
              fontSize: 28,
              color: style.accent,
              fontFeatures: AppText.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// One person, and the head-to-head.
///
/// The wording matters more than the numbers. "You are ahead" is a sentence
/// somebody reads out loud in a car, which is the entire reason this screen
/// exists.
class _RivalRow extends StatelessWidget {
  const _RivalRow({required this.rival});

  final Rival rival;

  @override
  Widget build(BuildContext context) {
    final Color tint = rival.level
        ? AppColors.textSecondary
        : rival.ahead
        ? AppColors.accent
        : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: <Widget>[
            AvatarBadge(avatar: rival.avatar, size: 38),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(rival.name, style: AppText.bodyStrong),
                  const SizedBox(height: 2),
                  Text(
                    rival.level
                        ? 'All square over ${rival.drives} '
                              '${rival.drives == 1 ? 'drive' : 'drives'}'
                        : rival.ahead
                        ? 'You are ahead'
                        : '${rival.name} is ahead',
                    style: AppText.caption.copyWith(
                      color: tint,
                      fontVariations: AppFonts.weight(700),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${rival.wins} — ${rival.losses}',
                  style: AppText.title3.copyWith(
                    color: tint,
                    fontFeatures: AppText.tabular,
                  ),
                ),
                Text(
                  rival.draws == 0
                      ? '${rival.drives} together'
                      : '${rival.draws} drawn',
                  style: AppText.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.overline);
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
              Icons.emoji_events_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: Space.lg),
            Text('No records yet', style: AppText.title3),
            const SizedBox(height: Space.sm),
            Text(
              'Finish a drive and this fills up — your best day, the rarest '
              'thing you have called, and how you stand against everyone you '
              'play with.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
