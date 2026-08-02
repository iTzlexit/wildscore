import 'package:flutter/material.dart';

import '../../domain/rarity_tier.dart';
import '../../shared/theme.dart';

/// How to play, player-facing.
///
/// Source of truth is docs/HOW-TO-PLAY.md — keep them in step.
///
/// Ordered by what a person needs *now*. The walkthrough is first, in five
/// numbered steps, because the reason anyone opens this screen is that a car
/// full of people is waiting for them to work out how to start. The rules that
/// settle arguments come second. The scoring table, which is the least urgent
/// thing here, comes last.
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
            'Someone shouts. Everyone looks. Whoever spotted it first takes '
            'the points, and the harder it was to find, the more it pays.\n\n'
            "That's the whole game, and it turns a quiet stretch of road into "
            'the best hour of the trip.',
            style: AppText.body.copyWith(height: 1.55),
          ),
          const SizedBox(height: Space.xl),

          const _Section('FIVE STEPS AND YOU ARE PLAYING'),
          const _Step(
            number: 1,
            title: 'Start a drive',
            body:
                'Wild Score tab, big green button. Do it in the queue at the '
                'gate — it takes about five seconds.',
          ),
          const _Step(
            number: 2,
            title: 'Add the car',
            body:
                'First names, that is all. No accounts, no passwords, no '
                'email. Gran counts. The kids definitely count. On your own '
                'counts too, and scores exactly the same.',
          ),
          const _Step(
            number: 3,
            title: 'Someone shouts',
            body:
                'Tap the eye beside their name, then tap the animal. Done in '
                'two taps, so you can get your eyes back on it.',
            icon: Icons.visibility_rounded,
          ),
          const _Step(
            number: 4,
            title: 'Watch the bars move',
            body:
                'An impala is 5 points. A pangolin is 2,500. Somewhere around '
                'the third sighting everyone in the car starts looking '
                'properly, and that is rather the point.',
          ),
          const _Step(
            number: 5,
            title: 'End the day at camp',
            body:
                'Preferably with a drink in your hand. Scores lock in, the '
                'day goes into your history with everyone who played, and '
                'tomorrow you all start level again.',
            last: true,
          ),

          const SizedBox(height: Space.xl),
          const SpiritOfTheGame(),

          const SizedBox(height: Space.xl),
          const _Section('THE FOUR THAT KEEP IT FAIR'),
          const _Rule(
            icon: Icons.fence_rounded,
            title: 'Inside the park only',
            body:
                'The gate is the line. That kudu on the road in was lovely, '
                'and it does not count.',
          ),
          const _Rule(
            icon: Icons.u_turn_left_rounded,
            title: 'One sighting, one claim',
            body:
                'Reverse back for another look at the leopard by all means. '
                'It is still the same leopard.',
          ),
          const _Rule(
            icon: Icons.groups_rounded,
            title: 'A pride is one lion',
            body:
                'Twelve lions at a kill is one claim, not twelve. Sorry. Same '
                'goes for a breeding herd of elephant.',
          ),
          const _Rule(
            icon: Icons.no_transfer_rounded,
            title: 'No asking at a jam',
            body:
                'Cars stopped up ahead means something good. Nobody may wind '
                'down a window and ask what it is. Find it yourself — that is '
                'the entire fun of it.',
          ),

          const SizedBox(height: Space.lg),
          const _Section('HANDY TO KNOW'),
          const _Rule(
            icon: Icons.campaign_rounded,
            title: 'Every claim is timestamped',
            body: 'So "I said it first" finally has an answer.',
          ),
          const _Rule(
            icon: Icons.undo_rounded,
            title: 'Gave it to the wrong person?',
            body:
                'Tap the animal under their name and it comes straight back '
                'off. No hard feelings.',
          ),
          const _Rule(
            icon: Icons.lock_clock_rounded,
            title: 'The common ones run out',
            body:
                'If every impala counted you would be finished by the first '
                'waterhole. So impala and friends can be claimed once a day, '
                'the middling ones three times, and everything rare stays open '
                'all day. Every leopard counts, every single time.',
          ),
          const _Rule(
            icon: Icons.visibility_rounded,
            title: 'You saw it too',
            body:
                'The points go to whoever called it, but everything the car '
                'finds still joins your collection. You were there. You saw '
                'the pangolin.',
          ),
          const _Rule(
            icon: Icons.restart_alt_rounded,
            title: 'First hour went sideways?',
            body:
                'Restart wipes the day and keeps everyone in their seats. '
                'Nothing was saved yet, so nothing is lost.',
          ),
          const _Rule(
            icon: Icons.menu_book_rounded,
            title: 'Not in the mood for a game?',
            body:
                'Just tick animals off in the Animal Dex as you see them. No '
                'drive, no scores, nobody keeping count. Your collection fills '
                'up all the same.',
          ),
          const _Rule(
            icon: Icons.handshake_rounded,
            title: 'It runs on trust',
            body:
                'Same as the paper version your family has been arguing over '
                'for years. Nothing is checked, nothing is verified, and these '
                'scores stay in your car.',
          ),

          const SizedBox(height: Space.lg),
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
            'None of this is about how impressive an animal is. It is about '
            'how hard it is to find, which is why lions are worth less than '
            'sable. Sweep up every common animal in the park in a single day '
            'and one pangolin still beats the lot of you — exactly as it '
            'should be.',
            style: AppText.caption.copyWith(height: 1.5),
          ),
        ],
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
                  'measure how hard something is to find — a pangolin scores '
                  'more than an elephant because the elephant is standing in '
                  'the road, not because it matters less.\n\n'
                  'The ranking exists so a long drive has something to argue '
                  'about. Watch the animal first. The phone can wait.',
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
