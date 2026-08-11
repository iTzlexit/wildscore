import 'package:flutter/material.dart';

import '../../domain/rarity_tier.dart';
import '../../shared/emphasis.dart';
import '../../shared/theme.dart';
import '../onboarding/intro_tour.dart';

/// The rule book. **Not** a tutorial.
///
/// Called "Rules" now, and it is only rules — Alex's instruction on 10 August
/// 2026, and the right split. Teaching somebody the game and settling an
/// argument about whether a second pride counts are different jobs for
/// different moments: the first happens once, at the gate, and belongs in the
/// tour; the second happens at 40km/h with somebody insisting, and needs a page
/// you can land on and scan.
///
/// **The wording is Alex's, near enough verbatim.** Two numbers move because
/// the app does something his draft did not: birds are capped at one a day, and
/// the first impala pays 100 rather than 60. Both were confirmed before this
/// was written. The rest is his, including the wink.
///
/// Source of truth is docs/HOW-TO-PLAY.md — keep them in step.
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
        title: Text('Rules', style: AppText.title2),
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
          // The four steps that used to sit here are in the tour now, which is
          // the only place they belong. This button is how somebody who wants
          // teaching gets to it from the page they landed on by mistake.
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
            label: const Text('New to this? Take the quick tour'),
          ),
          const SizedBox(height: Space.xl),

          const _Section('THE RULES'),
          // The paragraph explaining this is gone — Alex's note, and he is
          // right: the examples *are* the explanation, and the sentence above
          // them said the same thing in longer words.
          const _Rule(
            icon: Icons.groups_rounded,
            title: 'A group counts as one sighting',
            body:
                'Herd of elephants = **1 sighting**\n'
                'Pod of hippos = **1 sighting**\n'
                'Pride of lions = **1 sighting**\n'
                'Dazzle of zebra = **1 sighting**\n'
                'Tower of giraffe = **1 sighting**\n'
                'Troop of baboons = **1 sighting**\n'
                'Crash of rhino = **1 sighting**\n'
                'Obstinacy of buffalo = **1 sighting**',
          ),
          const _Rule(
            icon: Icons.u_turn_left_rounded,
            title: 'The same sighting counts once',
            body:
                'The same group of animals can only be scored once.\n\n'
                'Seeing them again later does not create a new sighting.',
          ),
          const SizedBox(height: Space.xl),

          const _Section('SPECIAL RULES'),
          const _Rule(
            icon: Icons.traffic_rounded,
            title: 'Traffic jam',
            body:
                'A traffic jam usually means something exciting has been '
                'spotted.\n\n'
                'If you arrive and correctly identify the animal, the sighting '
                'still counts — but you score **20% fewer points**.',
          ),
          const _Rule(
            icon: Icons.lock_clock_rounded,
            title: 'Daily limits',
            body:
                'Only a few animals have a daily limit:\n\n'
                'Impala: **2 per day**\n'
                'Vervet monkey: **4 per day**\n'
                'Every bird: **once a day**\n\n'
                'All other animals are unlimited — and you can change or lift '
                'any of these in **House rules** on your profile.',
          ),
          const SizedBox(height: Space.xl),

          // One section, not five.
          //
          // There used to be a card for the first impala, another for the first
          // lion of the day, and separate entries for each bonus — a page of
          // special cases, most of them about one animal. Alex cut the lot:
          // *"we don't need a separate block for impala and every animal below
          // it."* The first-spot bonuses are gone from the game entirely, and
          // what is left is one list of things that pay more.
          const _Section('BONUS ANIMALS'),
          const _Rule(
            icon: Icons.auto_awesome_rounded,
            title: 'Worth more than the animal',
            body:
                'Some sightings pay more than the number on the card:\n\n'
                'Male lion\n'
                'Mother with young\n'
                'Predator with a kill\n'
                'A kill up a tree\n'
                'A mating pair\n'
                'An elephant bull in musth\n'
                'A lone bull, or an old dagga boy\n'
                'A big tusker',
          ),
          const _Rule(
            icon: Icons.wb_sunny_rounded,
            title: 'Night animals in daylight',
            body:
                'See a normally nocturnal animal during the day and earn '
                '**2.5× its normal points**.\n\n'
                'Includes porcupine, genet, civet and bushpig.',
          ),
          const _Rule(
            icon: Icons.quiz_rounded,
            title: 'Trivia questions',
            body:
                'Earn additional points by answering trivia questions about '
                'Kruger and its animals during your game.\n\n'
                'Every **new animal** you spot earns you one, and one more is '
                'handed to somebody in the car every half hour.\n\n'
                'Easy **20**, tricky **40**, hard **70**. One guess each.',
          ),
          const SizedBox(height: Space.xl),

          const _Section('POINTS'),
          const _Rule(
            icon: Icons.leaderboard_rounded,
            title: 'How points work',
            body:
                'Each animal has a base score based on how difficult it is to '
                'find.\n\n'
                'Special rules and bonuses can increase or reduce the final '
                'score.',
          ),
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
            'Sweep up every Bush Staple in the park in one day and a single '
            'pangolin still beats the lot of you.',
            style: AppText.caption.copyWith(height: 1.5),
          ),
          const SizedBox(height: Space.xl),

          const _Section("CHANGE AN ANIMAL'S VALUE"),
          const _Rule(
            icon: Icons.tune_rounded,
            title: "Don't agree with a score? Change it",
            body:
                'Every game opens on **the prices**. Tap any animal and set '
                'what it is worth in your game.\n\n'
                'We remember it, so you do it once — not every morning. '
                'Changed your mind? **Back to ours** puts our number back.',
          ),
          const _Rule(
            icon: Icons.traffic_rounded,
            title: 'And the jam tax, if you think it is harsh',
            body:
                'Anything from nothing to half, in **House rules** on your '
                'profile.',
          ),
          const SizedBox(height: Space.lg),

          const SpiritOfTheGame(),
        ],
      ),
    );
  }
}

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
                  'It’s just a game',
                  style: AppText.label.copyWith(
                    color: AppColors.accent,
                    fontVariations: AppFonts.weight(800),
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  'Points measure how difficult an animal is to find, nothing '
                  'more. Every animal in Kruger is equally special.\n\n'
                  'Wild Score runs on honesty, just like the paper version. '
                  'Watch the animal first — the phone can wait.',
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
                  emphasised(
                    body,
                    style: AppText.caption.copyWith(height: 1.5),
                  ),
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
          SizedBox(
            // A range, because every animal in a tier no longer scores the
            // same — a leopard and a wild dog are both Prize animals and
            // nobody thinks they are equally hard to find.
            width: 84,
            child: Text(
              '${tier.low}–${tier.high}',
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
