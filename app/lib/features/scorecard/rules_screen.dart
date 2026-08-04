import 'package:flutter/material.dart';

import '../../domain/rarity_tier.dart';
import '../../shared/theme.dart';
import '../onboarding/intro_tour.dart';

/// What this is, and how to play it.
///
/// Source of truth is docs/HOW-TO-PLAY.md — keep them in step.
///
/// Four questions in the order a newcomer asks them: **what is this, which way
/// do I want to use it, how do I play, what are the rules.** The points table
/// is reference and sits last.
///
/// The previous version had a "handy to know" section, which was a junk drawer:
/// a rule that changes how you play sat next to help for a button, in identical
/// cards. Everything in it has been folded into the step or the rule it belongs
/// to. **One card style means one kind of thing** — here, a rule.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const RulesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('How to play', style: AppText.title2),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          Space.sm,
          Space.screen,
          Space.xxl,
        ),
        children: <Widget>[
          Text(
            'A game for long drives in the park. Find out who is actually any '
            'good at spotting.',
            style: AppText.body.copyWith(height: 1.55),
          ),
          const SizedBox(height: Space.lg),
          // For everybody who skipped the tour at the gate, and for the person
          // handing the phone to somebody who has never seen the app.
          OutlinedButton.icon(
            onPressed: () => IntroTour.open(context),
            icon: const Icon(Icons.slideshow_rounded, size: 17),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.outlineStrong),
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
            ),
            label: const Text('Show me the quick tour'),
          ),
          const SizedBox(height: Space.xl),

          const _Section('HOW IT IS PLAYED'),
          const _Step(
            number: 1,
            title: 'Enter the players',
            body:
                'Everyone in the car who wants to play. First names only — no '
                'accounts, no sign-ups. On your own works too.',
          ),
          const _Step(
            number: 2,
            title: 'Every animal has a scarcity level',
            body:
                'From Common up to Legendary, based on how hard it is to find '
                'in Kruger. An impala is 5 points. A pangolin is 2,000.',
          ),
          const _Step(
            number: 3,
            title: 'Points go to whoever spots it first',
            body:
                'Tap the eye beside their name, then tap the animal. Tap the '
                'animal again later to take it back off them.',
            icon: Icons.visibility_rounded,
          ),
          const _Step(
            number: 4,
            title: 'Tally up at the end of the drive',
            body:
                'Highest score takes the bragging rights. Tomorrow everyone '
                'starts level again.',
            last: true,
          ),
          const SizedBox(height: Space.xl),

          const _Section('OR DO NOT PLAY AT ALL'),
          const _Way(
            icon: Icons.menu_book_rounded,
            title: 'Just keep a list',
            body:
                'Tick animals off in the Animal Dex as you find them. No game, '
                'no scores, nobody keeping count — your collection fills up '
                'all the same.',
            last: true,
          ),
          const SizedBox(height: Space.xl),

          const _Section('THE RULES'),
          const _Rule(
            icon: Icons.fence_rounded,
            title: 'Inside the park only',
            body:
                'The gate is the line. That kudu on the way in was lovely, '
                'and it does not count.',
          ),
          const _Rule(
            icon: Icons.u_turn_left_rounded,
            title: 'One sighting, one claim',
            body:
                'Reverse back for another look by all means. It is still the '
                'same leopard.',
          ),
          const _Rule(
            icon: Icons.groups_rounded,
            title: 'A pride is one lion',
            body: 'Twelve lions at a kill is one claim, not twelve. Sorry.',
          ),
          const _Rule(
            icon: Icons.no_transfer_rounded,
            title: 'No asking at a jam',
            body:
                'Cars stopped ahead means something good. No winding down a '
                'window to ask what it is. Find it yourself — that is the fun.',
          ),
          const _Rule(
            icon: Icons.bolt_rounded,
            title: 'The first one is worth more',
            body:
                'Impala, zebra, giraffe and wildebeest pay 50 for the first '
                'sighting instead of 5. After that they are worth what they '
                'have always been worth. The impala bonus comes once a trip; '
                'the others reset every morning.',
          ),
          const _Rule(
            icon: Icons.lock_clock_rounded,
            title: 'The common ones run out',
            body:
                'Impala and friends: once a day. Middling ones: three times. '
                'Anything rare stays open all day — every leopard counts.',
          ),
          const SizedBox(height: Space.lg),

          const SpiritOfTheGame(),
          const SizedBox(height: Space.xl),

          const _Section('WHAT EVERYTHING IS WORTH'),
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              children: <Widget>[
                for (final RarityTier tier in RarityTier.values.reversed)
                  _PointRow(tier: tier),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Text(
            'Not how impressive an animal is — how hard it is to find. Sweep '
            'up every common animal in the park in one day and a single '
            'pangolin still beats the lot of you.',
            style: AppText.caption.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// One of the two ways in. Deliberately styled differently from a rule card:
/// this is a choice, and a choice should not look like an instruction.
class _Way extends StatelessWidget {
  const _Way({
    required this.icon,
    required this.title,
    required this.body,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : Space.sm),
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 19, color: AppColors.accent),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppText.bodyStrong.copyWith(fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: AppText.caption.copyWith(height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One numbered step of the walkthrough.
///
/// A connecting line runs between the numbers so the five read as a sequence
/// rather than as five unrelated cards. Somebody skimming this at a gate at
/// 05:30 needs to see the shape of it before they read a word.
class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    this.icon,
    this.last = false,
  });

  final int number;
  final String title;
  final String body;

  /// Shown beside the title when the step names a control, so the thing being
  /// described is recognisable before you go looking for it.
  final IconData? icon;

  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: AppColors.accentInk,
                    fontSize: 14,
                    fontFamily: AppFonts.ui,
                    fontVariations: AppFonts.weight(800),
                  ),
                ),
              ),
              if (!last)
                const Expanded(
                  child: SizedBox(
                    width: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.outline),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : Space.xl, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(child: Text(title, style: AppText.title3)),
                      if (icon != null) ...<Widget>[
                        const SizedBox(width: Space.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentWash,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(icon, size: 15, color: AppColors.accent),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(body, style: AppText.caption.copyWith(height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the points are, and what they are not.
///
/// Shown on this screen and again during onboarding. It matters that this is
/// said plainly and early: a scoreboard that ranks living animals invites
/// exactly one misreading, and leaving it unaddressed would let the app imply
/// something nobody involved believes.
///
/// It is also a better explanation of the scoring than any table. Rarity is a
/// measure of *difficulty*, which is why a pangolin beats an elephant — the
/// elephant is not worth less, it is standing in the road.
class SpiritOfTheGame extends StatelessWidget {
  const SpiritOfTheGame({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.accentWash,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.favorite_rounded, size: 18, color: AppColors.accent),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'It is a game, and only a game',
                  style: AppText.label.copyWith(
                    color: AppColors.accent,
                    fontVariations: AppFonts.weight(800),
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'Every animal out there is worth the same. The points only '
                  'measure how hard something is to find — a pangolin beats an '
                  'elephant because the elephant is standing in the road.\n\n'
                  'Nothing is checked or verified. It runs on trust, same as '
                  'the paper version. Watch the animal first; the phone can '
                  'wait.',
                  style: AppText.caption.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Text(text, style: AppText.overline),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.accentWash,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.accent),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: AppText.title3),
                  const SizedBox(height: Space.xs),
                  Text(body, style: AppText.caption.copyWith(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  const _PointRow({required this.tier});

  final RarityTier tier;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = tier.style;
    final int? chances = tier.chancesPerDay;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(
              tier.label,
              style: AppText.label.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Text(
            chances == null ? 'unlimited' : '$chances a day',
            style: AppText.caption.copyWith(fontSize: 11),
          ),
          const SizedBox(width: Space.md),
          SizedBox(
            width: 52,
            child: Text(
              '${tier.points}',
              textAlign: TextAlign.right,
              style: AppText.label.copyWith(
                color: style.accent,
                fontVariations: AppFonts.weight(800),
                fontFeatures: AppText.tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
