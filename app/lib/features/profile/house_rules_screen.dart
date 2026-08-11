import 'package:flutter/material.dart';

import '../../domain/house_rules.dart';
import '../../domain/species.dart';
import '../../domain/species_category.dart';
import '../../shared/theme.dart';

/// Wild Score settings — the rules a car can overrule.
///
/// **Built to Alex's mockup, 11 August 2026.** Three things changed with it and
/// each is worth naming.
///
/// It lives on the **Wild Score tab**, behind a gear, rather than on the
/// profile. These are settings for the game, and the game has its own tab; a
/// personal record was never the right place for "what does a traffic jam
/// cost".
///
/// Changes are **held until Saved**. Everything else in this app applies the
/// moment you touch it, and for a price on one animal that is right — you are
/// looking at the animal. A settings screen is different: somebody comes here to
/// try numbers out, and a screen that commits every experiment gives them no way
/// to change their mind except to remember what it used to be.
///
/// And it says, in as many words, that **changing a rule is safe**. That is the
/// question behind the hesitation — *will this rewrite my history* — and it has
/// a good answer: a claim stores what it scored on the day, so a table edited in
/// March cannot touch February.
class HouseRulesScreen extends StatefulWidget {
  const HouseRulesScreen({
    required this.rules,
    required this.onChanged,
    this.species = const <Species>[],
    this.onOpenAnimals,
    super.key,
  });

  static Future<void> open(
    BuildContext context, {
    required HouseRules rules,
    required ValueChanged<HouseRules> onChanged,
    List<Species> species = const <Species>[],
    VoidCallback? onOpenAnimals,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => HouseRulesScreen(
          rules: rules,
          onChanged: onChanged,
          species: species,
          onOpenAnimals: onOpenAnimals,
        ),
      ),
    );
  }

  final HouseRules rules;
  final ValueChanged<HouseRules> onChanged;

  /// The catalogue, so the limits section knows which species are birds and
  /// what is in force on each.
  final List<Species> species;

  /// Closes this screen and opens the Animals tab. Null leaves the row as a
  /// signpost rather than a door.
  final VoidCallback? onOpenAnimals;

  @override
  State<HouseRulesScreen> createState() => _HouseRulesScreenState();
}

class _HouseRulesScreenState extends State<HouseRulesScreen> {
  /// The rules as edited, not yet saved.
  late HouseRules _draft = widget.rules;

  bool get _dirty => _draft != widget.rules;

  @override
  void didUpdateWidget(HouseRulesScreen old) {
    super.didUpdateWidget(old);
    // The rules changed underneath us — a save landing, or a price set on
    // another screen. Adopt them, unless there are unsaved edits here, in which
    // case the person in front of the screen wins.
    if (old.rules != widget.rules && _draft == old.rules) {
      _draft = widget.rules;
    }
  }

  List<String> get _birdIds => <String>[
    for (final Species s in widget.species)
      if (s.category == SpeciesCategory.bird) s.id,
  ];

  /// The limit in force on one species under the **draft**: a number, or null
  /// for no limit.
  int? _capFor(String id) {
    if (_draft.caps.containsKey(id)) {
      return _draft.caps[id]?.times;
    }
    for (final Species s in widget.species) {
      if (s.id == id) {
        return s.catalogueCap?.times;
      }
    }
    return null;
  }

  void _setCap(List<String> ids, int? times) {
    final Map<String, SpeciesCap?> next = <String, SpeciesCap?>{..._draft.caps};
    for (final String id in ids) {
      // A present key holding null is "no limit", which is not the same as a
      // missing key — that is a car which has never been asked, and our default
      // is still allowed to move under them.
      next[id] = times == null
          ? null
          : SpeciesCap(times: times, scope: CapScope.day);
    }
    setState(() => _draft = _draft.copyWith(caps: next));
  }

  void _save() {
    widget.onChanged(_draft);
    Navigator.of(context).pop();
  }

  Future<void> _resetToDefault() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Back to our rules?', style: AppText.title3),
        content: Text(
          'Every score, limit and setting you have changed goes back to ours. '
          'Your collection and your past drives are not touched.',
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
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _draft = HouseRules.none);
    }
  }

  /// Warns before dropping edits on the floor.
  Future<bool> _confirmDiscard() async {
    if (!_dirty) {
      return true;
    }
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Leave without saving?', style: AppText.title3),
        content: Text(
          'Your changes have not been saved yet.',
          style: AppText.body,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final int keeps = (100 * _draft.jamMultiplier).ceil();

    return PopScope<Object?>(
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, Object? _) async {
        if (didPop || !mounted) {
          return;
        }
        // Grabbed before the await, not after it. The dialog is a gap in which
        // this route can be disposed, and a context used on the other side of
        // one belongs to a widget that may no longer be in the tree.
        final NavigatorState navigator = Navigator.of(context);
        if (await _confirmDiscard()) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Wild Score settings', style: AppText.title2),
          backgroundColor: AppColors.background,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.sm,
            Space.screen,
            Space.xl,
          ),
          children: <Widget>[
            const _Banner(
              icon: Icons.explore_outlined,
              title: 'Your game, your rules',
              body:
                  'Adjust settings your way. You can change anything, any '
                  'time.',
            ),
            const SizedBox(height: Space.xl),

            const _Section('ARRIVING AT A JAM'),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _CardHead(
                    icon: Icons.directions_car_filled_outlined,
                    title: 'Cars already stopped when you arrive?',
                    subtitle: 'How much should that cost?',
                    hint:
                        'You did see the animal, so a jam never scores '
                        'nothing — it scores less.\n\n'
                        'Set it to No tax if your car would rather a sighting '
                        'were simply a sighting.',
                  ),
                  const SizedBox(height: Space.lg),
                  _ChipGrid(
                    labels: <String>[
                      for (final double p in HouseRules.jamPenaltyChoices)
                        p == 0 ? 'No tax' : '−${(p * 100).round()}%',
                    ],
                    selected: HouseRules.jamPenaltyChoices.indexOf(
                      _draft.effectiveJamPenalty,
                    ),
                    onPick: (int i) {
                      final double p = HouseRules.jamPenaltyChoices[i];
                      setState(
                        () => _draft = p == HouseRules.defaultJamPenalty
                            // Agreeing with us clears the setting rather than
                            // storing a copy of it, or a car that agreed in
                            // August would be pinned to that number when we
                            // changed our minds in September.
                            ? _draft.copyWith(clearJamPenalty: true)
                            : _draft.copyWith(jamPenalty: p),
                      );
                    },
                  ),
                  const SizedBox(height: Space.lg),
                  _Note(
                    _draft.effectiveJamPenalty == 0
                        ? 'A sighting is a sighting. A 100-point leopard pays '
                              '100 either way.'
                        : 'A 100-point leopard pays $keeps if you roll up to '
                              'a jam.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xl),

            // Kept from the previous version, in the new clothes.
            //
            // Alex asked for these on 10 August and the mockup routes limits to
            // the Dex instead — but "which animals run out, and can I turn that
            // off" is a question about the *game*, and answering it three taps
            // deep inside a species page is answering it in the wrong place.
            // Both live here now: the three real caps, and a way through to
            // everything else.
            const _Section('DAILY LIMITS'),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _CardHead(
                    icon: Icons.timelapse_outlined,
                    title: 'What runs out in a day',
                    subtitle: 'Everything else is unlimited.',
                  ),
                  const SizedBox(height: Space.lg),
                  _CapRow(
                    label: 'Impala',
                    current: _capFor('impala'),
                    choices: const <int?>[2, 4, null],
                    onPick: (int? t) => _setCap(<String>['impala'], t),
                  ),
                  const SizedBox(height: Space.lg),
                  _CapRow(
                    label: 'Vervet monkey',
                    current: _capFor('vervet-monkey'),
                    choices: const <int?>[4, 8, null],
                    onPick: (int? t) => _setCap(<String>['vervet-monkey'], t),
                  ),
                  if (_birdIds.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Space.lg),
                    _CapRow(
                      label: 'Every bird',
                      current: _capFor(_birdIds.first),
                      choices: const <int?>[1, 2, null],
                      onPick: (int? t) => _setCap(_birdIds, t),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Space.xl),

            const _Section('POINTS & LIMITS'),
            _Card(
              onTap: widget.onOpenAnimals == null
                  ? null
                  : () async {
                      if (await _confirmDiscard() && mounted) {
                        widget.onOpenAnimals!();
                      }
                    },
              child: _CardHead(
                icon: Icons.pets_rounded,
                title: 'Animal scores & limits',
                subtitle:
                    'Set what any animal is worth on its own page in Animals, '
                    'or on the prices screen when a game starts.',
                trailing: widget.onOpenAnimals == null
                    ? null
                    : Icons.chevron_right_rounded,
              ),
            ),
            const SizedBox(height: Space.xl),

            const _Section('HOW CHANGES WORK'),
            const _Banner(
              icon: Icons.verified_user_outlined,
              title: 'Safe to change',
              body:
                  'Rules only affect new sightings. Past drives stay exactly '
                  'as they were.',
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.sm,
              Space.screen,
              Space.sm,
            ),
            // Flexible on both, or the pair overflows a 430pt phone by 117
            // pixels before anybody touches the text scale — "Reset to default"
            // and "Save changes" are simply wider than a phone together.
            child: Row(
              children: <Widget>[
                Flexible(
                  child: TextButton.icon(
                    onPressed: _draft.isDefault ? null : _resetToDefault,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'Reset to default',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                    ),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Flexible(
                  child: FilledButton.icon(
                    onPressed: _dirty ? _save : null,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text(
                      'Save changes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.accentInk,
                      disabledBackgroundColor: AppColors.outline,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.md,
                        vertical: Space.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.card),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The soft-tinted panels top and bottom: a statement, not a control.
class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.accentWash,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 26, color: AppColors.accent),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppText.title3),
                const SizedBox(height: 3),
                Text(body, style: AppText.caption.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: AppColors.outline),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Icon in a soft disc, title, one line under it, and something on the right.
class _CardHead extends StatelessWidget {
  const _CardHead({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hint,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Behind a small **i**. For the one thing on this screen that has a reason
  /// rather than just a value.
  final String? hint;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accentWash,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.accent),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppText.title3),
              const SizedBox(height: 2),
              Text(subtitle, style: AppText.caption.copyWith(height: 1.45)),
            ],
          ),
        ),
        if (hint != null)
          Tooltip(
            message: hint!,
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 8),
            margin: const EdgeInsets.symmetric(horizontal: Space.screen),
            textStyle: AppText.caption.copyWith(
              color: AppColors.surface,
              height: 1.45,
            ),
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.info_outline_rounded,
                size: 19,
                color: AppColors.textMuted,
              ),
            ),
          ),
        if (trailing != null)
          Icon(trailing, size: 20, color: AppColors.textMuted),
      ],
    );
  }
}

/// The choices, as a grid of equal boxes with a tick on the chosen one.
///
/// Not [ChoiceChip]: six chips of different widths wrap into a ragged block,
/// and this is a row of prices — the eye should be able to run down it.
class _ChipGrid extends StatelessWidget {
  const _ChipGrid({
    required this.labels,
    required this.selected,
    required this.onPick,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const int columns = 3;
        const double gap = Space.sm;
        final double width = (c.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (int i = 0; i < labels.length; i++)
              SizedBox(
                width: width,
                child: _Choice(
                  label: labels[i],
                  selected: i == selected,
                  onTap: () => onPick(i),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentWash : AppColors.surface,
      borderRadius: BorderRadius.circular(Radii.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.chip),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.outline,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontSize: 14.5,
                    color: selected ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
              ),
              if (selected) ...<Widget>[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 17,
                  color: AppColors.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The consequence of the setting above it, in plain numbers.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.star_outline_rounded,
            size: 17,
            color: AppColors.accent,
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(text, style: AppText.caption.copyWith(height: 1.45)),
          ),
        ],
      ),
    );
  }
}

/// One animal's daily limit.
///
/// Fixed choices rather than a number field. "How many a day" is not a question
/// anybody has a considered answer to beyond *a couple*, *a few*, or *stop
/// counting them* — and this is operated with a thumb.
class _CapRow extends StatelessWidget {
  const _CapRow({
    required this.label,
    required this.current,
    required this.choices,
    required this.onPick,
  });

  final String label;

  /// The limit in force. Null means no limit.
  final int? current;

  /// Offered limits, with null for "no limit" last.
  final List<int?> choices;
  final ValueChanged<int?> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppText.bodyStrong),
        const SizedBox(height: Space.sm),
        _ChipGrid(
          labels: <String>[
            for (final int? t in choices)
              t == null
                  ? 'No limit'
                  : t == 1
                  ? 'Once a day'
                  : '$t a day',
          ],
          selected: choices.indexOf(current),
          onPick: (int i) => onPick(choices[i]),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.md),
    child: Text(
      text,
      style: AppText.overline.copyWith(color: AppColors.accent),
    ),
  );
}
