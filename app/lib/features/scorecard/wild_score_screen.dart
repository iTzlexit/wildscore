import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../domain/species.dart';
import '../../shared/date_format.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/app_header.dart';
import 'rules_screen.dart';
import 'standings_board.dart';

/// The game, on its own tab.
///
/// It was a panel on the Profile, which was wrong twice over. It crowded the
/// screen — a car of five with a good morning between them produces more tags
/// than a card can hold — and it mixed two different things: the day belongs to
/// the vehicle, the profile belongs to one person. Splitting them means neither
/// has to apologise for the other's space.
class WildScoreScreen extends StatelessWidget {
  const WildScoreScreen({
    required this.species,
    this.card,
    this.onStart,
    this.onEnd,
    this.onRestart,
    this.onRemoveClaim,
    this.onSpotFor,
    super.key,
  });

  final List<Species> species;
  final Scorecard? card;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final VoidCallback? onRestart;
  final void Function(Player player, Species species)? onRemoveClaim;
  final ValueChanged<Player>? onSpotFor;

  @override
  Widget build(BuildContext context) {
    final Scorecard? live = card;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            AppHeader(
              trailing: IconButton(
                onPressed: () => RulesScreen.open(context),
                icon: const Icon(Icons.help_outline_rounded),
                color: AppColors.textSecondary,
                tooltip: 'How to play',
              ),
            ),
            Expanded(
              child: live == null
                  ? _Invitation(onStart: onStart)
                  : _LiveGame(
                      card: live,
                      species: species,
                      onEnd: onEnd,
                      onRestart: onRestart,
                      onRemoveClaim: onRemoveClaim,
                      onSpotFor: onSpotFor,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// No drive running.
class _Invitation extends StatelessWidget {
  const _Invitation({this.onStart});

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.lg,
        Space.screen,
        120,
      ),
      children: <Widget>[
        Text('Wild Score', style: AppText.title1),
        const SizedBox(height: Space.sm),
        Text(
          'The scorecard game. Play it on your own, or hand the phone around '
          'the car and settle who really found the leopard.',
          style: AppText.body.copyWith(height: 1.55),
        ),
        const SizedBox(height: Space.xl),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: Text(
              'Start a drive',
              style: AppText.title3.copyWith(color: AppColors.accentInk),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.accentInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.card),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        Center(
          child: Text(
            'You are always in the drive. Add others if there are any.',
            style: AppText.caption,
          ),
        ),
        const SizedBox(height: Space.xl),
        // The honest alternative, said out loud. Somebody who only wants a life
        // list should not have to start and end a game to get one, and burying
        // that fact would make the app feel heavier than it is.
        Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Just keeping a list?',
                      style: AppText.label.copyWith(
                        color: AppColors.textPrimary,
                        fontVariations: AppFonts.weight(700),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mark animals in the Animal Dex as you see them. No '
                      'drive, no points, no scores to settle — they just join '
                      'your collection.',
                      style: AppText.caption.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.section),
        const _HowItWorks(),
        const SizedBox(height: Space.lg),
        Center(
          child: TextButton.icon(
            onPressed: () => RulesScreen.open(context),
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: Text(
              'Read the rules',
              style: AppText.label.copyWith(
                color: AppColors.accent,
                fontVariations: AppFonts.weight(700),
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.screen),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Step(
            number: '1',
            title: 'Start a drive',
            body: 'On your own, or add whoever else is in the car.',
          ),
          _Step(
            number: '2',
            title: 'Someone shouts',
            body:
                'Tap the animal in the Animal Dex, tap who called it. The '
                'rarer it is, the more it pays.',
          ),
          _Step(
            number: '3',
            title: 'End the day',
            body:
                'The drive is saved to your history, and your own points join '
                'your lifetime total.',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    this.last = false,
  });

  final String number;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : Space.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: AppColors.accentInk,
                fontSize: 12.5,
                fontFamily: AppFonts.ui,
                fontVariations: AppFonts.weight(800),
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppText.bodyStrong),
                const SizedBox(height: 2),
                Text(body, style: AppText.caption.copyWith(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A drive in progress. This is the whole screen, which is the point of moving
/// it off the profile — the standings can breathe, and a long haul list is no
/// longer competing with a progress bar for the same 200 points of height.
class _LiveGame extends StatelessWidget {
  const _LiveGame({
    required this.card,
    required this.species,
    this.onEnd,
    this.onRestart,
    this.onRemoveClaim,
    this.onSpotFor,
  });

  final Scorecard card;
  final List<Species> species;
  final VoidCallback? onEnd;
  final VoidCallback? onRestart;
  final void Function(Player player, Species species)? onRemoveClaim;
  final ValueChanged<Player>? onSpotFor;

  @override
  Widget build(BuildContext context) {
    final bool solo = card.players.length <= 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        Space.xs,
        Space.screen,
        120,
      ),
      children: <Widget>[
        _LiveHeader(card: card, solo: solo),
        const SizedBox(height: Space.lg),
        StandingsBoard(
          card: card,
          species: species,
          expanded: true,
          onRemoveClaim: onRemoveClaim,
          onSpotFor: onSpotFor,
        ),
        if (card.claims.isNotEmpty) ...<Widget>[
          const SizedBox(height: Space.xs),
          Row(
            children: <Widget>[
              const Icon(
                Icons.touch_app_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tap + to add a sighting. Tap an animal to take it back.',
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: Space.sm),
        if (card.claims.isEmpty)
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    'Nothing claimed yet. Tap the + next to whoever shouted '
                    'first.',
                    style: AppText.caption.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: Space.xl),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(
                  'Restart',
                  style: AppText.label.copyWith(
                    color: AppColors.textSecondary,
                    fontVariations: AppFonts.weight(700),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.outlineStrong),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: onEnd,
                icon: const Icon(Icons.flag_rounded, size: 18),
                label: Text(
                  'End the day',
                  style: AppText.label.copyWith(
                    color: AppColors.accentInk,
                    fontVariations: AppFonts.weight(700),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        Text(
          // Says what the button does before it is pressed. Ending a day is the
          // only moment points become permanent, and nobody should discover
          // that afterwards.
          'Ending saves the drive to your history and adds your own points to '
          'your lifetime total.',
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _LiveHeader extends StatelessWidget {
  const _LiveHeader({required this.card, required this.solo});

  final Scorecard card;
  final bool solo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.screen),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.accent, width: 1.5),
        boxShadow: AppColors.shadowSm,
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
                  solo ? 'DRIVE IN PLAY · SOLO' : 'DRIVE IN PLAY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.overline.copyWith(color: AppColors.accent),
                ),
              ),
              // The date, because a drive can outlive the day it started on —
              // someone opens the app the next morning with yesterday still
              // running, and the card should say so rather than imply today.
              Text(
                formatLongDate(card.startedAt),
                style: AppText.caption.copyWith(
                  fontVariations: AppFonts.weight(600),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${card.totalPoints}',
                style: AppText.display.copyWith(
                  fontSize: 38,
                  color: AppColors.accent,
                  fontFeatures: AppText.tabular,
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(
                    solo ? 'POINTS TODAY' : 'POINTS IN THE CAR',
                    style: AppText.overline,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  '${card.claims.length} claimed',
                  style: AppText.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
