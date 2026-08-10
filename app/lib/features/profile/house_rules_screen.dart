import 'package:flutter/material.dart';

import '../../domain/house_rules.dart';
import '../../shared/emphasis.dart';
import '../../shared/theme.dart';

/// The settings your car argues about.
///
/// **Deliberately not a settings screen.** There is nothing here about
/// notifications or units or accounts, because the app has none of those. What
/// it has is three judgement calls we made on everybody's behalf — what an
/// animal is worth, what a jam costs you, and when counting stops being fun —
/// and this is where a car overrules them.
///
/// The per-animal ones are not here. Points and limits live on the animal's own
/// page in the Dex, because that is where somebody is standing when they decide
/// a sable is worth more than we think. This screen holds the one rule that
/// applies to everything, and owns up to what has been changed.
class HouseRulesScreen extends StatelessWidget {
  const HouseRulesScreen({
    required this.rules,
    required this.onChanged,
    super.key,
  });

  static Future<void> open(
    BuildContext context, {
    required HouseRules rules,
    required ValueChanged<HouseRules> onChanged,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            HouseRulesScreen(rules: rules, onChanged: onChanged),
      ),
    );
  }

  final HouseRules rules;
  final ValueChanged<HouseRules> onChanged;

  @override
  Widget build(BuildContext context) {
    final int changed = rules.changeCount;

    return Scaffold(
      appBar: AppBar(
        title: Text('House rules', style: AppText.title2),
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
          emphasised(
            'Our scores are one opinion, and Kruger is not one place. '
            '**Change anything you disagree with.**',
            style: AppText.body.copyWith(height: 1.55),
          ),
          const SizedBox(height: Space.xl),

          const _Section('ARRIVING AT A JAM'),
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                emphasised(
                  'Cars already stopped when you got there. **How much should '
                  'that cost?**',
                  style: AppText.body,
                ),
                const SizedBox(height: Space.md),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: <Widget>[
                    for (final double p in HouseRules.jamPenaltyChoices)
                      ChoiceChip(
                        label: Text(
                          p == 0 ? 'No tax' : '−${(p * 100).round()}%',
                        ),
                        selected: rules.effectiveJamPenalty == p,
                        labelStyle: AppText.body.copyWith(fontSize: 14),
                        selectedColor: AppColors.accentWash,
                        side: BorderSide(
                          color: rules.effectiveJamPenalty == p
                              ? AppColors.accent
                              : AppColors.outline,
                        ),
                        onSelected: (_) => onChanged(
                          // Choosing the default clears the setting rather than
                          // storing a copy of it — otherwise a car that agreed
                          // with us in August would be pinned to that number
                          // when we changed our minds in September.
                          p == HouseRules.defaultJamPenalty
                              ? rules.copyWith(clearJamPenalty: true)
                              : rules.copyWith(jamPenalty: p),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Space.md),
                Text(
                  rules.effectiveJamPenalty == 0
                      ? 'A sighting is a sighting. A 100-point leopard pays '
                            '100 either way.'
                      : 'A 100-point leopard pays '
                            '${(100 * rules.jamMultiplier).ceil()} if you '
                            'rolled up to a jam.',
                  style: AppText.caption.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),

          const _Section('POINTS AND LIMITS'),
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                emphasised(
                  'These are set **on the animal itself**. Open anything in '
                  'the Animal Dex and look under its score.',
                  style: AppText.body,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  changed == 0
                      ? 'You have not changed anything yet.'
                      : 'You have changed $changed '
                            '${changed == 1 ? 'thing' : 'things'}.',
                  style: AppText.caption,
                ),
                if (changed > 0) ...<Widget>[
                  const SizedBox(height: Space.sm),
                  TextButton(
                    onPressed: () async {
                      final bool ok = await _confirmReset(context);
                      if (ok) {
                        onChanged(HouseRules.none);
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Put everything back'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.xl),

          Text(
            'Changing a rule never touches a drive you have already ended. '
            'Every claim keeps the points it scored on the day.',
            style: AppText.caption.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmReset(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Put everything back?', style: AppText.title3),
        content: Text(
          'Every score and limit you have changed goes back to ours. Your '
          'collection and your drives are not touched.',
          style: AppText.body,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep mine'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Put back'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.md),
    child: Text(text, style: AppText.overline),
  );
}
