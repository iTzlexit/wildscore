import 'package:flutter/material.dart';

import '../../domain/species.dart';
import '../../domain/species_category.dart';
import '../../domain/tracker_profile.dart';
import '../../shared/theme.dart';

/// The Spotter's own record: progress, then numbers, then recent catches.
///
/// **The collection grid deliberately does not live here.** It belongs in the
/// Animal Dex, filtered by Spotted / Not spotted — one grid, one place. A
/// profile that repeats the whole Codex makes both screens feel like the same
/// screen.
///
/// Opens on Today, because during a trip that is the number the car is arguing
/// about. Lifetime is the trophy shelf you visit afterwards.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.profile,
    required this.species,
    this.caughtIds = const <String>{},
    super.key,
  });

  final TrackerProfile profile;
  final List<Species> species;

  /// Empty until Phase 2. Every number here already reads from it.
  final Set<String> caughtIds;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum ProfileScope {
  today(label: 'Today'),
  lifetime(label: 'Lifetime');

  const ProfileScope({required this.label});

  final String label;
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileScope _scope = ProfileScope.today;

  int get _points => 0;

  @override
  Widget build(BuildContext context) {
    final int total = widget.species.length;
    final int spotted = widget.caughtIds.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.screen,
            Space.screen,
            110,
          ),
          children: <Widget>[
            _Identity(profile: widget.profile),
            const SizedBox(height: Space.xl),
            _ScopeToggle(
              scope: _scope,
              onChanged: (ProfileScope s) => setState(() => _scope = s),
            ),
            const SizedBox(height: Space.lg),
            _ProgressCard(spotted: spotted, total: total, points: _points),
            const SizedBox(height: Space.lg),
            _Numbers(spotted: spotted, total: total),
            const SizedBox(height: Space.section),
            _CategoryBreakdown(
              species: widget.species,
              caughtIds: widget.caughtIds,
            ),
            const SizedBox(height: Space.section),
            const _SectionLabel('RECENT SIGHTINGS'),
            const SizedBox(height: Space.md),
            const _RecentEmpty(),
          ],
        ),
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
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0x26DCA84A),
            shape: BoxShape.circle,
          ),
          child: Text(
            profile.initial,
            style: AppText.title2.copyWith(color: AppColors.accent),
          ),
        ),
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
                // "Day Visitor" is rank one of six. Ranks arrive in Phase 9;
                // everyone starts here.
                'Day Visitor · Season ${profile.seasonYear}',
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({required this.scope, required this.onChanged});

  final ProfileScope scope;
  final ValueChanged<ProfileScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.chip + 3),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: <Widget>[
          for (final ProfileScope value in ProfileScope.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(value),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: Motion.chip,
                  curve: Motion.exit,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: scope == value
                        ? AppColors.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  child: Text(
                    value.label,
                    textAlign: TextAlign.center,
                    style: AppText.label.copyWith(
                      color: scope == value
                          ? AppColors.accentInk
                          : AppColors.textSecondary,
                      fontVariations: AppFonts.weight(
                        scope == value ? 700 : 500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Score and completion in one card, because they answer the same question:
/// how am I doing?
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.spotted,
    required this.total,
    required this.points,
  });

  final int spotted;
  final int total;
  final int points;

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
          Text('POINTS', style: AppText.overline),
          const SizedBox(height: Space.screen),
          Row(
            children: <Widget>[
              Text('$spotted of $total spotted', style: AppText.label),
              const Spacer(),
              Text(
                '$percent%',
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

class _Numbers extends StatelessWidget {
  const _Numbers({required this.spotted, required this.total});

  final int spotted;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _NumberTile(
            icon: Icons.pets_rounded,
            value: '$total',
            label: 'IN THE PARK',
            tint: AppColors.accent,
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: _NumberTile(
            icon: Icons.check_circle_rounded,
            value: '$spotted',
            label: 'SPOTTED',
            tint: AppColors.verified,
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: _NumberTile(
            icon: Icons.visibility_outlined,
            value: '${total - spotted}',
            label: 'TO FIND',
            tint: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.overline.copyWith(fontSize: 8.5, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

/// Per-category completion. A mammal-focused Spotter should not stare at one
/// number that only moves when they log birds.
class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.species, required this.caughtIds});

  final List<Species> species;
  final Set<String> caughtIds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionLabel('BY CATEGORY'),
        const SizedBox(height: Space.md),
        for (final SpeciesCategory category in SpeciesCategory.values)
          _CategoryBar(
            category: category,
            total: species.where((Species s) => s.category == category).length,
            spotted: species
                .where(
                  (Species s) =>
                      s.category == category && caughtIds.contains(s.id),
                )
                .length,
          ),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.total,
    required this.spotted,
  });

  final SpeciesCategory category;
  final int total;
  final int spotted;

  @override
  Widget build(BuildContext context) {
    final double fraction = total == 0 ? 0 : spotted / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(category.label, style: AppText.label),
              const Spacer(),
              Text(
                '$spotted / $total',
                style: AppText.caption.copyWith(fontFeatures: AppText.tabular),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
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

class _RecentEmpty extends StatelessWidget {
  const _RecentEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.screen,
        vertical: Space.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.photo_camera_outlined,
            size: 26,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: Space.md),
          Text(
            'Nothing spotted yet',
            style: AppText.bodyStrong.copyWith(fontSize: 14),
          ),
          const SizedBox(height: Space.xs),
          Text(
            'Every animal you photograph in the park lands here — '
            'and stays, for good.',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
