import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/scorecard.dart';
import '../../domain/trivia.dart';
import '../../shared/theme.dart';

/// One question, four answers, and whatever the question is worth.
///
/// **No second guess.** A quiz you can retry is a quiz everybody scores full
/// marks on, and the whole reason this pays anything is that getting it wrong
/// costs you the points.
///
/// **Closing it, on the other hand, costs nothing.** It used to: the question
/// was recorded as asked the moment the sheet opened, so pressing back burned
/// it and the badge disappeared. The question is now held as *pending* and
/// handed straight back next time, which stops anybody shopping for an easier
/// one without punishing a mis-tap.
class TriviaSheet extends StatefulWidget {
  const TriviaSheet({required this.player, required this.question, super.key});

  final Player player;
  final TriviaQuestion question;

  /// The points won — zero for a wrong answer.
  ///
  /// **Null means they closed it without answering**, which is a different
  /// thing entirely: the question goes back in the pocket rather than being
  /// spent. Returning zero for both was the bug Alex found in about a minute.
  static Future<int?> ask(
    BuildContext context, {
    required Player player,
    required TriviaQuestion question,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) =>
          TriviaSheet(player: player, question: question),
    );
  }

  @override
  State<TriviaSheet> createState() => _TriviaSheetState();
}

class _TriviaSheetState extends State<TriviaSheet> {
  /// Shuffled once, here, and never again.
  ///
  /// The bank stores the right answer first in every question, because that is
  /// far easier to write and to check. Without this the game would be "always
  /// tap the top one", which is not a game.
  ///
  /// Seeded from the question id so the order is stable for a given question —
  /// it must not reshuffle under somebody's thumb on a rebuild.
  late final List<int> _order = <int>[
    for (int i = 0; i < widget.question.answers.length; i++) i,
  ]..shuffle(Random(widget.question.id.hashCode));

  int? _chosen;

  @override
  Widget build(BuildContext context) {
    final TriviaQuestion q = widget.question;
    final bool answered = _chosen != null;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(Space.sm),
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.sheet),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.quiz_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    // Difficulty is named, because a hard question pays more
                    // and somebody who gets one should know they earned it.
                    '${widget.player.name} · ${q.difficulty.label.toUpperCase()}'
                    ' · ${q.reward} POINTS',
                    style: AppText.overline.copyWith(color: AppColors.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            Text(q.question, style: AppText.title3),
            const SizedBox(height: Space.lg),

            for (final int i in _order) ...<Widget>[
              _Answer(
                label: q.answers[i],
                state: !answered
                    ? _AnswerState.idle
                    : i == q.correct
                    ? _AnswerState.right
                    : i == _chosen
                    ? _AnswerState.wrong
                    : _AnswerState.idle,
                onTap: answered ? null : () => setState(() => _chosen = i),
              ),
              const SizedBox(height: Space.sm),
            ],

            if (answered) ...<Widget>[
              const SizedBox(height: Space.sm),
              Text(
                q.isCorrect(_chosen!)
                    ? 'Right — ${q.reward} points to ${widget.player.name}.'
                    : 'Not this time. It was ${q.answer}.',
                style: AppText.body.copyWith(
                  color: q.isCorrect(_chosen!)
                      ? AppColors.verified
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: Space.md),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(q.isCorrect(_chosen!) ? q.reward : 0),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                    ),
                  ),
                  child: const Text('Back to the drive'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _AnswerState { idle, right, wrong }

class _Answer extends StatelessWidget {
  const _Answer({required this.label, required this.state, this.onTap});

  final String label;
  final _AnswerState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = switch (state) {
      _AnswerState.right => AppColors.verified,
      _AnswerState.wrong => AppColors.danger,
      _AnswerState.idle => AppColors.outlineStrong,
    };

    return Material(
      color: state == _AnswerState.idle
          ? AppColors.surface
          : border.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(Radii.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.chip),
            border: Border.all(
              color: border,
              width: state == _AnswerState.idle ? 1 : 1.6,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(label, style: AppText.body)),
              if (state == _AnswerState.right)
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.verified,
                )
              else if (state == _AnswerState.wrong)
                const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
