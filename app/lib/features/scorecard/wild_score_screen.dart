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
    this.onQuizFor,
    this.onOpenHistory,
    super.key,
  });

  final List<Species> species;
  final Scorecard? card;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final VoidCallback? onRestart;
  final void Function(Player player, Species species)? onRemoveClaim;
  final ValueChanged<Player>? onSpotFor;
  final ValueChanged<Player>? onQuizFor;

  /// Past drives. They live on this tab because they are the game's history,
  /// not the player's — the profile is one person's record and a list of days
  /// spent with other people in a car is not that.
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final Scorecard? live = card;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            AppHeader(
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (onOpenHistory != null)
                    IconButton(
                      onPressed: onOpenHistory,
                      icon: const Icon(Icons.history_rounded),
                      color: AppColors.textSecondary,
                      tooltip: 'Past drives',
                    ),
                  IconButton(
                    onPressed: () => RulesScreen.open(context),
                    icon: const Icon(Icons.help_outline_rounded),
                    color: AppColors.textSecondary,
                    tooltip: 'Rules',
                  ),
                ],
              ),
            ),
            Expanded(
              child: live == null
                  ? _Invitation(onStart: onStart, onOpenHistory: onOpenHistory)
                  : _LiveGame(
                      card: live,
                      species: species,
                      onEnd: onEnd,
                      onRestart: onRestart,
                      onRemoveClaim: onRemoveClaim,
                      onSpotFor: onSpotFor,
                      onQuizFor: onQuizFor,
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
  const _Invitation({this.onStart, this.onOpenHistory});

  final VoidCallback? onStart;
  final VoidCallback? onOpenHistory;

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
          'Add everyone in the car, then tap a name whenever somebody spots '
          'something. Rare animals pay more.',
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
        if (onOpenHistory != null) ...<Widget>[
          const SizedBox(height: Space.md),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onOpenHistory,
              icon: const Icon(Icons.history_rounded, size: 19),
              label: Text(
                'Past drives',
                style: AppText.bodyStrong.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.outlineStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.card),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: Space.section),
        // The four-step walkthrough used to sit here. It also sits on the
        // rules screen and on the second slide of the intro tour — three
        // copies of the same four steps in three slightly different wordings,
        // which is three places to keep in step and two more than anybody
        // needs. The tour teaches the game, the rules screen is the reference,
        // and this screen's one job is to start a drive.
        Center(
          child: TextButton.icon(
            onPressed: () => RulesScreen.open(context),
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: Text(
              'Rules',
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
    this.onQuizFor,
  });

  final Scorecard card;
  final List<Species> species;
  final VoidCallback? onEnd;
  final VoidCallback? onRestart;
  final void Function(Player player, Species species)? onRemoveClaim;
  final ValueChanged<Player>? onSpotFor;
  final ValueChanged<Player>? onQuizFor;

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
          onQuizFor: onQuizFor,
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
                  'Tap the eye to add a sighting. Tap an animal to take it '
                  'back.',
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
        // No empty state under the standings. There used to be a card saying
        // "nothing yet, tap the eye" — which is a whole panel telling a car
        // that has been playing for four minutes that it has not scored yet.
        // The line above the board already says what the eye does.
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
        // What ending a day does is said in the dialog that ending a day
        // opens, which is where somebody is actually deciding. A paragraph
        // under the button explained it to everybody else all day long.
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
