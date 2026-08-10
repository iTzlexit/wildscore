import 'package:flutter/material.dart';

import '../../domain/house_rules.dart';
import '../../domain/scorecard.dart';
import '../../domain/species.dart';
import '../../domain/species_collection.dart';
import '../../domain/tracker_profile.dart';
import '../../domain/visit.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/avatar_badge.dart';
import '../codex/collection_screen.dart';
import 'backup_screen.dart';
import 'house_rules_screen.dart';
import 'licences_screen.dart';

/// One person's record. Not the day's game — that has its own tab.
///
/// **The collection grid deliberately does not live here.** It belongs in the
/// Animal Dex, filtered by Spotted / Not spotted — one grid, one place. A
/// profile that repeats the whole Codex makes both screens feel like the same
/// screen.
///
/// There is no Today / Lifetime toggle any more. It asked people to choose
/// which question they were asking before showing them anything, and only one
/// of the two answers belonged here: a profile answers "how am I doing
/// overall". The day's score lives where the day lives.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.profile,
    required this.species,
    this.caughtIds = const <String>{},
    this.visits = const <Visit>[],
    this.card,
    this.onOpenGame,
    this.onDeleteVisit,
    this.onRestored,
    this.onToggleSpotted,
    this.rules = HouseRules.none,
    this.onRulesChanged,
    super.key,
  });

  /// The car's own rules, and the way to change the one that is not attached
  /// to a single animal.
  final HouseRules rules;
  final ValueChanged<HouseRules>? onRulesChanged;

  final TrackerProfile profile;
  final List<Species> species;

  /// Empty until Phase 2. Every number here already reads from it.
  final Set<String> caughtIds;

  /// Every day this account has finished, newest first. The lifetime total is
  /// derived from it rather than stored — see data/visit_repository.dart.
  final List<Visit> visits;

  /// A drive running on the Wild Score tab. Worth a pointer, since this screen
  /// deliberately does not show it — and it appears, unbanked, at the top of
  /// the drive history.
  final Scorecard? card;
  final VoidCallback? onOpenGame;
  final Future<void> Function(Visit visit)? onDeleteVisit;

  /// Reloads the shell after a restore. Every screen reads from the stores this
  /// writes to, so they all have to be told.
  final VoidCallback? onRestored;

  /// Adds or removes a species, for the collection screens this opens. Without
  /// it a collection is a display case with the lid glued shut.
  final ValueChanged<String>? onToggleSpotted;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Derived, never stored. A running total drifts — every undo and restart is
  /// another chance for it to be wrong, with nothing to check it against.
  int get _lifetimePoints =>
      widget.visits.fold(0, (int sum, Visit v) => sum + v.ownerPoints);

  /// The hardest thing in the collection. A single species is a better trophy
  /// than a count — nobody brags about owning 13 animals.
  Species? get _rarest {
    Species? best;
    for (final Species s in widget.species) {
      if (!widget.caughtIds.contains(s.id)) {
        continue;
      }
      if (best == null || s.points > best.points) {
        best = s;
      }
    }
    return best;
  }

  void _openCollection(CollectionMode mode) {
    CollectionScreen.open(
      context,
      species: widget.species,
      caughtIds: widget.caughtIds,
      mode: mode,
      onToggleSpotted: widget.onToggleSpotted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.species.length;
    final int spotted = widget.caughtIds.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const AppHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.screen,
                  Space.sm,
                  Space.screen,
                  110,
                ),
                children: <Widget>[
                  // This screen is now one person's record and nothing else.
                  // The day's game moved to its own tab: a drive belongs to the
                  // vehicle and a profile belongs to a person, and having them
                  // share a screen meant neither had room.
                  _Identity(profile: widget.profile),
                  const SizedBox(height: Space.xl),
                  _LifetimeCard(
                    points: _lifetimePoints,
                    spotted: spotted,
                    total: total,
                  ),
                  if (widget.card != null) ...<Widget>[
                    const SizedBox(height: Space.md),
                    _DriveInPlayLink(onTap: widget.onOpenGame),
                  ],
                  const SizedBox(height: Space.lg),
                  _Numbers(
                    spotted: spotted,
                    toFind: total - spotted,
                    rarest: _rarest,
                    onSpotted: () => _openCollection(CollectionMode.spotted),
                    onToFind: () => _openCollection(CollectionMode.toFind),
                  ),
                  const SizedBox(height: Space.section),
                  // The per-category bars used to live below this. They are
                  // gone: "13 of 54 mammals" is a statistic, and every set here
                  // is a goal. Two progress systems on one screen made both
                  // read as filler.
                  _Collections(
                    species: widget.species,
                    caughtIds: widget.caughtIds,
                    onOpen: (SpeciesCollection group) => CollectionScreen.open(
                      context,
                      species: widget.species,
                      caughtIds: widget.caughtIds,
                      group: group,
                      onToggleSpotted: widget.onToggleSpotted,
                    ),
                  ),
                  const SizedBox(height: Space.section),
                  if (widget.onRulesChanged != null) ...<Widget>[
                    _FooterRow(
                      icon: Icons.tune_rounded,
                      title: 'House rules',
                      body:
                          'Set what an animal is worth and how often it '
                          'counts. Ours are only a suggestion.',
                      onTap: () => HouseRulesScreen.open(
                        context,
                        rules: widget.rules,
                        onChanged: (HouseRules next) {
                          widget.onRulesChanged!(next);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                  ],
                  _FooterRow(
                    icon: Icons.cloud_off_rounded,
                    title: 'Back up my collection',
                    body:
                        'All of this lives on this phone only. Save a copy you '
                        'can restore.',
                    onTap: () => BackupScreen.open(
                      context,
                      onRestored: widget.onRestored ?? () {},
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  _FooterRow(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Credits and licences',
                    body:
                        'The photographers and illustrators whose work is in '
                        'here.',
                    onTap: () => LicencesScreen.open(context),
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

/// The rows at the foot of the profile: backup, and credits.
///
/// Down here because neither is what anyone opens this screen for — but both
/// have to be *somewhere findable*. For backup, the day it matters is the day
/// after somebody wishes they had used it. For credits, it is a condition of
/// the CC-BY licence that they are reachable at all.
class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 19, color: AppColors.textSecondary),
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
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A quiet pointer to the other tab. Not the game itself — just an
/// acknowledgement that one is running, so the profile does not look like it
/// has forgotten.
class _DriveInPlayLink extends StatelessWidget {
  const _DriveInPlayLink({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentWash,
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Text(
                  'A drive is in play',
                  style: AppText.label.copyWith(
                    color: AppColors.accent,
                    fontVariations: AppFonts.weight(700),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The headline number and how far through the park you are.
///
/// Not tappable, and it says nothing about drives. It used to open the drive
/// history, which was wrong twice over: a lifetime total is not a list of
/// days, and the game's history belongs on the game's tab. It also printed the
/// spotted count immediately above a tile that printed the same count again.
class _LifetimeCard extends StatelessWidget {
  const _LifetimeCard({
    required this.points,
    required this.spotted,
    required this.total,
  });

  final int points;
  final int spotted;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double fraction = total == 0 ? 0 : spotted / total;
    final int percent = (fraction * 100).round();

    return Container(
      padding: const EdgeInsets.all(Space.screen),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$points',
            style: AppText.display.copyWith(
              color: AppColors.accent,
              fontFeatures: AppText.tabular,
            ),
          ),
          const SizedBox(height: Space.xs),
          Row(
            children: <Widget>[
              Text('MY LIFETIME POINTS', style: AppText.overline),
              const SizedBox(width: 6),
              // Points and the collection are two different things and the
              // difference confuses people, reasonably: a player who found
              // nothing all day still gains species, because everything the car
              // saw joins the collection while the points stay with whoever
              // called it. Better said on request than as permanent small print.
              const _Explainer(
                title: 'Where these come from',
                body:
                    'Points you have banked at the end of each drive, added up '
                    'across every drive you have played.\n\n'
                    'They are not the same as your collection. Points go to '
                    'whoever called the animal first. The collection takes '
                    'everything the whole car saw — you were there, so you have '
                    'seen it — plus anything you tick off yourself in the '
                    'Animal Dex.\n\n'
                    'So a quiet day in the back seat can add species without '
                    'adding points.',
              ),
            ],
          ),
          const SizedBox(height: Space.screen),
          Row(
            children: <Widget>[
              Text(
                '$percent% of the park found',
                style: AppText.label.copyWith(color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '$spotted / $total',
                style: AppText.label.copyWith(
                  color: AppColors.accent,
                  fontVariations: AppFonts.weight(800),
                  fontFeatures: AppText.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.profile});

  final TrackerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        AvatarBadge(avatar: profile.avatar, size: 52),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                profile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title1.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 2),
              Text(
                // Ranks arrive in Phase 9. Until then a made-up title under
                // someone's name is just noise — worse, "Day Visitor" reads as
                // a demotion to anyone who has been coming for twenty years.
                'Season ${profile.seasonYear}',
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The three counts. Two of them open something.
///
/// SPOTTED and TO FIND were previously dead text, which is a small betrayal —
/// a number on a dashboard reads as a link, and a player who taps it and gets
/// nothing learns that this screen's numbers are decoration.
class _Numbers extends StatelessWidget {
  const _Numbers({
    required this.spotted,
    required this.toFind,
    required this.rarest,
    required this.onSpotted,
    required this.onToFind,
  });

  final int spotted;
  final int toFind;
  final Species? rarest;
  final VoidCallback onSpotted;
  final VoidCallback onToFind;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _NumberTile(
                icon: Icons.check_circle_rounded,
                value: '$spotted',
                label: 'FOUND',
                tint: AppColors.verified,
                onTap: onSpotted,
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: _NumberTile(
                icon: Icons.visibility_outlined,
                value: '$toFind',
                label: 'STILL OUT THERE',
                tint: AppColors.textSecondary,
                onTap: onToFind,
              ),
            ),
          ],
        ),
        // A single species is a better trophy than a count. "13 animals" is a
        // statistic; "Ground Pangolin" is a story somebody tells at dinner.
        if (rarest != null) ...<Widget>[
          const SizedBox(height: Space.md),
          _RarestTile(species: rarest!),
        ],
      ],
    );
  }
}

class _RarestTile extends StatelessWidget {
  const _RarestTile({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: style.accent, width: style.borderWidth),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.workspace_premium_rounded, size: 19, color: style.accent),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'RAREST YOU HAVE FOUND',
                  style: AppText.overline.copyWith(fontSize: 8.5),
                ),
                const SizedBox(height: 2),
                Text(
                  species.commonName,
                  style: AppText.bodyStrong.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          Text(
            '${species.points}',
            style: AppText.title3.copyWith(
              color: style.accent,
              fontFeatures: AppText.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;
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
          padding: const EdgeInsets.symmetric(vertical: Space.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 19, color: tint),
              const SizedBox(height: Space.sm),
              Text(
                value,
                style: AppText.title2.copyWith(fontFeatures: AppText.tabular),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppText.overline.copyWith(
                        fontSize: 8.5,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sets people try to complete, each one a way in to its own grid.
///
/// Completion here is far more motivating than the category bars below, because
/// the denominator is small enough to hold in your head. "3 of 5" is a goal.
/// "13 of 54" is a statistic.
class _Collections extends StatelessWidget {
  const _Collections({
    required this.species,
    required this.caughtIds,
    required this.onOpen,
  });

  final List<Species> species;
  final Set<String> caughtIds;
  final ValueChanged<SpeciesCollection> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionLabel('COLLECTIONS'),
        const SizedBox(height: Space.md),
        for (final SpeciesCollection group in SpeciesCollection.values)
          _CollectionRow(
            group: group,
            members: group.membersOf(species),
            caughtIds: caughtIds,
            onTap: () => onOpen(group),
          ),
      ],
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    required this.group,
    required this.members,
    required this.caughtIds,
    required this.onTap,
  });

  final SpeciesCollection group;
  final List<Species> members;
  final Set<String> caughtIds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int found = members
        .where((Species s) => caughtIds.contains(s.id))
        .length;
    final bool complete = members.isNotEmpty && found == members.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
        color: complete ? AppColors.accentWash : AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.card),
          child: Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(
                color: complete
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.outline,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: complete ? AppColors.accent : AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    group.icon,
                    size: 19,
                    color: complete
                        ? AppColors.accentInk
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              group.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyStrong,
                            ),
                          ),
                          if (complete) ...<Widget>[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 15,
                              color: AppColors.accent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        group.blurb,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.sm),
                Text(
                  '$found/${members.length}',
                  style: AppText.label.copyWith(
                    color: complete ? AppColors.accent : AppColors.textPrimary,
                    fontVariations: AppFonts.weight(800),
                    fontFeatures: AppText.tabular,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
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

/// A small "i" that opens an explanation.
///
/// Not a tooltip. A Material tooltip needs a long-press to appear on a phone,
/// which nobody discovers, and it vanishes while you are still reading it. A
/// tap that opens something you dismiss yourself is the version that works on a
/// touch screen.
class _Explainer extends StatelessWidget {
  const _Explainer({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            title: Text(title, style: AppText.title3),
            content: Text(body, style: AppText.body.copyWith(height: 1.55)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(3),
          child: Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
