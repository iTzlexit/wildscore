import 'package:flutter/material.dart';

import '../../domain/species.dart';
import '../../domain/tracker_profile.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/species_image.dart';

/// The player's own record: lifetime score, then the collection.
///
/// Opens on the score because that is what a player checks first — it is the
/// summary of everything they have ever found.
///
/// The collection below is deliberately **not** an empty list. Every species in
/// the park is shown, darkened, with a question mark. Seventy-one empty slots
/// staring back is the entire motivation of a collection game; "You haven't
/// caught anything yet" is a dead end.
/// Which window the header is reporting on.
enum ProfileScope {
  today(label: 'Today', metricLabel: 'POINTS TODAY'),
  lifetime(label: 'Lifetime', metricLabel: 'LIFETIME POINTS');

  const ProfileScope({required this.label, required this.metricLabel});

  final String label;
  final String metricLabel;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.profile,
    required this.species,
    this.caughtIds = const <String>{},
    super.key,
  });

  final TrackerProfile profile;
  final List<Species> species;

  /// Empty until Phase 2. The whole screen is already written to fill in.
  final Set<String> caughtIds;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Opens on Today. During a trip that is the number you care about — it is
  // what the family in the car is arguing over. Lifetime is the trophy shelf
  // you visit afterwards.
  ProfileScope _scope = ProfileScope.today;

  int get _points => 0;

  @override
  Widget build(BuildContext context) {
    final int found = widget.caughtIds.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _Header(
                profile: widget.profile,
                scope: _scope,
                onScopeChanged: (ProfileScope s) => setState(() => _scope = s),
                points: _points,
                found: found,
                total: widget.species.length,
              ),
            ),
            SliverToBoxAdapter(
              child: _CollectionHeader(
                found: found,
                total: widget.species.length,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 110,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.86,
                ),
                itemCount: widget.species.length,
                itemBuilder: (BuildContext context, int index) {
                  final Species s = widget.species[index];
                  return _CollectionSlot(
                    species: s,
                    caught: widget.caughtIds.contains(s.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.profile,
    required this.scope,
    required this.onScopeChanged,
    required this.points,
    required this.found,
    required this.total,
  });

  final TrackerProfile profile;
  final ProfileScope scope;
  final ValueChanged<ProfileScope> onScopeChanged;
  final int points;
  final int found;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0x26D9A441),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  profile.initial,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tracker · Season ${profile.seasonYear}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ScopeToggle(scope: scope, onChanged: onScopeChanged),
          const SizedBox(height: 18),
          // The number the whole screen exists for.
          Center(
            child: Column(
              children: <Widget>[
                Text(
                  '$points',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 62,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -3,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  scope.metricLabel,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Expanded(
                child: _Stat(value: '$found/$total', label: 'SPECIES'),
              ),
              const _StatDivider(),
              const Expanded(
                child: _Stat(value: '0', label: 'TRIPS'),
              ),
              const _StatDivider(),
              const Expanded(
                child: _Stat(value: '—', label: 'RAREST'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Today vs Lifetime.
///
/// Both matter and they matter at different moments: during a trip you want
/// today's number, because that is what everyone in the car is arguing about.
/// Afterwards you want the lifetime figure. Burying either behind a menu makes
/// the app feel like admin.
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
        borderRadius: BorderRadius.circular(11),
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
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: scope == value
                        ? AppColors.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    value.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scope == value
                          ? const Color(0xFF14100A)
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: scope == value
                          ? FontWeight.w800
                          : FontWeight.w600,
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: AppColors.outline);
  }
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({required this.found, required this.total});

  final int found;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : found / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                'COLLECTION',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const Spacer(),
              Text(
                '$found of $total found',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          if (found == 0) ...<Widget>[
            const SizedBox(height: 14),
            const Text(
              'Nothing here yet. Every animal you photograph in the park '
              'fills one of these slots — for good.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CollectionSlot extends StatelessWidget {
  const _CollectionSlot({required this.species, required this.caught});

  final Species species;
  final bool caught;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: caught ? style.border : AppColors.outline,
          width: caught ? style.borderWidth : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SpeciesImage(species: species, locked: !caught),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Text(
                caught ? species.commonName : 'No. ${species.dexLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: caught ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
