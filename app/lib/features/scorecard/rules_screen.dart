import 'package:flutter/material.dart';

import '../../domain/rarity_tier.dart';
import '../../shared/theme.dart';

/// The rules of the car game, player-facing.
///
/// Source of truth is docs/HOW-TO-PLAY.md — keep them in step.
///
/// Most of these exist because a family already argued about them. That is the
/// point of writing them down: the app cannot referee a disagreement it has no
/// opinion on, and "the app says" settles a car in a way that "I say" does not.
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
            'Everyone in the car plays. You spot animals, you claim them, the '
            'rarest finds win. At the end of the day the scores are added up '
            'and the argument is over.',
            style: AppText.body.copyWith(height: 1.55),
          ),
          const SizedBox(height: Space.lg),
          const SpiritOfTheGame(),
          const SizedBox(height: Space.xl),

          const _Section('THE FOUR THAT SETTLE ARGUMENTS'),
          const _Rule(
            icon: Icons.fence_rounded,
            title: 'Inside the park only',
            body:
                'The gate is the boundary. An animal seen on the road in, on a '
                'private reserve, or from camp before the gates open does not '
                'count.',
          ),
          const _Rule(
            icon: Icons.u_turn_left_rounded,
            title: 'One sighting, one claim',
            body:
                'Turn around and come back to the same leopard and it is still '
                'the same leopard. Driving back for a second look is worth '
                'doing — it is just not worth points.',
          ),
          const _Rule(
            icon: Icons.groups_rounded,
            title: 'A pride is one lion',
            body:
                'You claim the sighting, not the animals in it. Twelve lions '
                'at a kill is one claim. So is a breeding herd of elephant and '
                'a tower of giraffe.',
          ),
          const _Rule(
            icon: Icons.no_transfer_rounded,
            title: 'No asking at a jam',
            body:
                'A line of stopped cars means something good is ahead. Nobody '
                'may ask a passing car what it is. The point goes to whoever '
                'first sees the animal themselves — knowing it is there is not '
                'the same as finding it.',
          ),

          const SizedBox(height: Space.lg),
          const _Section('CLAIMING'),
          const _Rule(
            icon: Icons.campaign_rounded,
            title: 'Whoever calls it first',
            body:
                'Tap the animal, tap the name of whoever shouted. It is '
                'timestamped, so "I said it first" has an answer. You have five '
                'minutes to fix a mis-tap, then the claim locks.',
          ),
          const _Rule(
            icon: Icons.lock_clock_rounded,
            title: 'Common animals run out',
            body:
                'If every impala counted the game would be over by the first '
                'waterhole. Common and Frequent species can be claimed once a '
                'day; Notable three times. Rare and above never run out — every '
                'leopard counts, every time.',
          ),
          const _Rule(
            icon: Icons.verified_outlined,
            title: 'It is an honour system',
            body:
                'Exactly like the paper version. Claims are not photographed '
                'or verified, and they do not go on the public leaderboard — '
                'that is what the camera is for, later.',
          ),

          const SizedBox(height: Space.lg),
          const _Section('WHAT THINGS ARE WORTH'),
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
            'Points track how hard an animal genuinely is to find in Kruger, '
            'not how famous it is. Lions are easier to find than sable. '
            'Claiming every common species in the park in one day is worth '
            'less than a single pangolin, and that is on purpose.',
            style: AppText.caption.copyWith(height: 1.5),
          ),

          const SizedBox(height: Space.xl),
          const _Section('AT THE END OF THE DAY'),
          const _Rule(
            icon: Icons.flag_rounded,
            title: 'End the day to bank it',
            body:
                'Ending a drive saves it to your history and adds your own '
                'points to your lifetime total. Everyone else\'s scores are '
                'saved with the day, so you can look back and see who was in '
                'the car.',
          ),
          const _Rule(
            icon: Icons.restart_alt_rounded,
            title: 'Restart if it went wrong',
            body:
                'Wipes the day and keeps the car. Nothing is banked, so '
                'nothing is lost from your record.',
          ),
          const _Rule(
            icon: Icons.visibility_rounded,
            title: 'You saw it too',
            body:
                'Points go to whoever called it first — but everything the car '
                'found joins your collection, because you were there and you '
                'saw it. Scoring and your life list are different questions.',
          ),
        ],
      ),
    );
  }
}

/// What the points are, and what they are not.
///
/// Shown on the rules screen and again during onboarding. It matters that this
/// is said plainly and early: a scoreboard that ranks living animals invites
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
