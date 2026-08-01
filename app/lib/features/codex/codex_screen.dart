import 'package:flutter/material.dart';

import '../../data/attribution_repository.dart';
import '../../data/species_repository.dart';
import '../../domain/park_region.dart';
import '../../domain/rarity_tier.dart';
import '../../domain/species.dart';
import '../../domain/species_category.dart';
import '../../domain/species_tag.dart';
import '../../domain/tracker_profile.dart';
import '../../shared/theme.dart';
import 'species_detail_screen.dart';
import 'widgets/species_grid_card.dart';

/// The Codex — every species in the park, searchable and filterable.
///
/// Phase 1 keeps all state in this one widget with `setState`. That is not a
/// placeholder for something better; for a single screen owning a search string
/// and three filters, it is the correct amount of machinery. Riverpod arrives
/// in Phase 2, when sightings have to be visible from several screens at once.
class CodexScreen extends StatefulWidget {
  const CodexScreen({
    this.repository = const SpeciesRepository(),
    this.profile,
    this.caughtIds = const <String>{},
    super.key,
  });

  /// Null in tests that only exercise the list. When present, the strip sits
  /// above the title.
  final TrackerProfile? profile;

  /// Species already spotted. Empty until Phase 2; the Spotted / Not spotted
  /// filter is wired to it now so the screen does not need restructuring later.
  final Set<String> caughtIds;

  /// Injected so widget tests can supply an in-memory catalogue.
  ///
  /// Reading the JSON asset is real file I/O, and `testWidgets` runs inside a
  /// fake-async zone where real I/O does not reliably complete — the tests
  /// passed alone and timed out in a full run. Constructor injection is the
  /// same fix you would reach for in ASP.NET Core, for the same reason.
  final SpeciesRepository repository;

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  late final Future<List<Species>> _speciesFuture;
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  SpeciesCategory? _category;
  RarityTier? _tier;
  ParkRegion? _region;
  SpeciesTag? _tag;
  SpottedFilter _spotted = SpottedFilter.all;
  bool _filtersExpanded = false;
  Map<String, String> _credits = const <String, String>{};

  int get _activeFilterCount =>
      (_category == null ? 0 : 1) +
      (_tier == null ? 0 : 1) +
      (_region == null ? 0 : 1) +
      (_tag == null ? 0 : 1);

  @override
  void initState() {
    super.initState();
    // Kicked off once, here — not in build(), which Flutter may call many
    // times per second. This trips up almost everyone coming from the server
    // side, where a request handler runs exactly once.
    _speciesFuture = widget.repository.loadAll();

    // Credits are decorative to the list and only needed when a photo is
    // opened, so this is deliberately not awaited — the Codex renders without
    // waiting on it.
    const AttributionRepository().loadAll().then((Map<String, String> credits) {
      if (mounted) {
        setState(() => _credits = credits);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _category = null;
      _tier = null;
      _region = null;
      _tag = null;
    });
  }

  List<Species> _applyFilters(List<Species> all) {
    return <Species>[
      for (final Species species in all)
        if (species.matchesQuery(_query) &&
            (_category == null || species.category == _category) &&
            (_tier == null || species.rarityTier == _tier) &&
            (_region == null || species.parkRegions.contains(_region)) &&
            (_tag == null || species.tags.contains(_tag)) &&
            _spotted.matches(widget.caughtIds.contains(species.id)))
          species,
    ];
  }

  void _openDetail(Species species) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SpeciesDetailScreen(
          species: species,
          photoCredit: _credits[species.id],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Species>>(
          future: _speciesFuture,
          builder:
              (BuildContext context, AsyncSnapshot<List<Species>> snapshot) {
                if (snapshot.hasError) {
                  return _ErrorState(error: snapshot.error!);
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                final List<Species> all = snapshot.data!;
                final List<Species> visible = _applyFilters(all);

                return Column(
                  children: <Widget>[
                    // No screen title. The tab is already labelled "Animal
                    // Dex"; a "Codex" heading under it was a second name for
                    // the same thing and cost a third of the screen.
                    const SizedBox(height: Space.md),
                    _SearchBar(
                      controller: _searchController,
                      filtersExpanded: _filtersExpanded,
                      activeFilterCount: _activeFilterCount,
                      onChanged: (String value) =>
                          setState(() => _query = value),
                      onToggleFilters: () =>
                          setState(() => _filtersExpanded = !_filtersExpanded),
                    ),
                    _QuickFilterRow(
                      category: _category,
                      tag: _tag,
                      spotted: _spotted,
                      onCategory: (SpeciesCategory? value) => setState(() {
                        _category = value;
                        _tag = null;
                      }),
                      onTag: (SpeciesTag? value) => setState(() {
                        _tag = value;
                        _category = null;
                      }),
                      onSpotted: (SpottedFilter value) =>
                          setState(() => _spotted = value),
                      onClear: () => setState(() {
                        _category = null;
                        _tag = null;
                        _spotted = SpottedFilter.all;
                      }),
                    ),
                    _RarityRow(
                      selected: _tier,
                      onSelected: (RarityTier? value) =>
                          setState(() => _tier = value),
                    ),
                    if (_filtersExpanded)
                      _AdvancedFilters(
                        region: _region,
                        onRegion: (ParkRegion? value) =>
                            setState(() => _region = value),
                      ),
                    _ResultBar(
                      count: visible.length,
                      total: all.length,
                      activeFilterCount: _activeFilterCount,
                      onClear: _clearFilters,
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? const _EmptyState()
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              // maxCrossAxisExtent rather than a fixed column
                              // count, so a small phone gets 2 columns and a
                              // tablet gets 4 without any breakpoint logic.
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 190,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio:
                                        SpeciesGridCard.aspectRatio,
                                  ),
                              itemCount: visible.length,
                              itemBuilder: (BuildContext context, int index) {
                                final Species species = visible[index];
                                return SpeciesGridCard(
                                  species: species,
                                  // Three-state Codex, per MASTER-VISION.md:
                                  // undiscovered species show as silhouettes.
                                  // The tile is the tease; the detail screen
                                  // still carries the full field-guide entry,
                                  // so the free tier stays genuinely useful.
                                  locked: !widget.caughtIds.contains(
                                    species.id,
                                  ),
                                  onTap: () => _openDetail(species),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }
}

/// Who you are, and how you are doing. Zeroes for now — Phase 2 fills these in
/// from the local sightings table, and watching them climb is the point.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.filtersExpanded,
    required this.activeFilterCount,
    required this.onChanged,
    required this.onToggleFilters,
  });

  final TextEditingController controller;
  final bool filtersExpanded;
  final int activeFilterCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: searchFieldDecoration(
                'Search — impala, rooibok, Panthera…',
              ),
            ),
          ),
          const SizedBox(width: 10),
          _FilterToggle(
            expanded: filtersExpanded,
            activeCount: activeFilterCount,
            onTap: onToggleFilters,
          ),
        ],
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({
    required this.expanded,
    required this.activeCount,
    required this.onTap,
  });

  final bool expanded;
  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = expanded || activeCount > 0;

    return Material(
      color: highlighted ? const Color(0x26D9A441) : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 52,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted ? AppColors.accent : AppColors.outline,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: highlighted ? AppColors.accent : AppColors.textMuted,
              ),
              if (activeCount > 0)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          color: Color(0xFF14100A),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row, two axes — collection groups and categories together.
///
/// Three separate chip rows put ~120pt of chrome between the search field and
/// the first animal, which is most of a phone screen. Mixing axes in one row
/// is slightly impure but it is what every field-guide app does, and it is
/// what a player expects: these are all just "show me a subset".
///
/// Selecting from one axis clears the other, which is the behaviour a single
/// row implies anyway.
class _QuickFilterRow extends StatelessWidget {
  const _QuickFilterRow({
    required this.category,
    required this.tag,
    required this.spotted,
    required this.onCategory,
    required this.onTag,
    required this.onSpotted,
    required this.onClear,
  });

  final SpeciesCategory? category;
  final SpeciesTag? tag;
  final SpottedFilter spotted;
  final ValueChanged<SpeciesCategory?> onCategory;
  final ValueChanged<SpeciesTag?> onTag;
  final ValueChanged<SpottedFilter> onSpotted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.screen),
        children: <Widget>[
          FilterPill(
            label: 'All',
            selected: category == null && tag == null,
            onTap: onClear,
          ),
          for (final SpottedFilter value in SpottedFilter.values)
            if (value != SpottedFilter.all)
              FilterPill(
                label: value.label,
                selected: spotted == value,
                accent: value == SpottedFilter.spotted
                    ? AppColors.verified
                    : null,
                onTap: () =>
                    onSpotted(spotted == value ? SpottedFilter.all : value),
              ),
          // Groups first — "have you got the Big Five yet" is the question
          // every visitor is asked.
          for (final SpeciesTag value in SpeciesTag.values)
            if (value.isFilter)
              FilterPill(
                label: value.label,
                selected: tag == value,
                onTap: () => onTag(tag == value ? null : value),
              ),
          for (final SpeciesCategory value in SpeciesCategory.values)
            FilterPill(
              label: value.label,
              selected: category == value,
              onTap: () => onCategory(category == value ? null : value),
            ),
        ],
      ),
    );
  }
}

/// Whether a species has been spotted.
///
/// This is why the collection grid does not also live on the Profile — one
/// grid, one place, filtered. Two grids showing the same 71 animals makes both
/// screens feel like the same screen.
enum SpottedFilter {
  all(label: 'All'),
  spotted(label: 'Spotted'),
  notSpotted(label: 'Not spotted');

  const SpottedFilter({required this.label});

  final String label;

  bool matches(bool isSpotted) => switch (this) {
    SpottedFilter.all => true,
    SpottedFilter.spotted => isSpotted,
    SpottedFilter.notSpotted => !isSpotted,
  };
}

/// Rarity gets its own row, in tier colours.
///
/// It was buried in the advanced panel, which is wrong — rarity *is* the app's
/// central concept, and a row of tier-coloured chips doubles as a legend for
/// what the colours on the cards mean.
class _RarityRow extends StatelessWidget {
  const _RarityRow({required this.selected, required this.onSelected});

  final RarityTier? selected;
  final ValueChanged<RarityTier?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.screen),
          children: <Widget>[
            FilterPill(
              label: 'Any rarity',
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
            // Rarest first — the interesting end of the scale should be the
            // end you reach without scrolling.
            for (final RarityTier value in RarityTier.values.reversed)
              FilterPill(
                label: value.label,
                selected: selected == value,
                accent: value.style.accent,
                onTap: () => onSelected(selected == value ? null : value),
              ),
          ],
        ),
      ),
    );
  }
}

/// Region only. Rarity was promoted to its own always-visible row.
class _AdvancedFilters extends StatelessWidget {
  const _AdvancedFilters({required this.region, required this.onRegion});

  final ParkRegion? region;
  final ValueChanged<ParkRegion?> onRegion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _FilterGroupLabel('PARK REGION'),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.screen),
            children: <Widget>[
              FilterPill(
                label: 'Anywhere',
                selected: region == null,
                onTap: () => onRegion(null),
              ),
              for (final ParkRegion value in ParkRegion.values)
                FilterPill(
                  label: value.label,
                  selected: region == value,
                  onTap: () => onRegion(region == value ? null : value),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.xs),
      ],
    );
  }
}

class _FilterGroupLabel extends StatelessWidget {
  const _FilterGroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

/// A selectable capsule. Written by hand rather than using [FilterChip] so the
/// selected state can take a per-rarity accent colour, and so it is immune to
/// Material's chip theming changing shape between Flutter releases.
class FilterPill extends StatelessWidget {
  const FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color tint = accent ?? AppColors.accent;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected ? tint : AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: selected ? tint : AppColors.outline),
            ),
            child: Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 12,
                color: selected ? AppColors.accentInk : AppColors.textSecondary,
                fontVariations: AppFonts.weight(selected ? 700 : 500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.count,
    required this.total,
    required this.activeFilterCount,
    required this.onClear,
  });

  final int count;
  final int total;
  final int activeFilterCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(
        children: <Widget>[
          Text(
            count == total ? 'All $total species' : '$count of $total species',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          if (activeFilterCount > 0)
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Clear filters',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.travel_explore_rounded,
              size: 42,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 14),
            Text(
              'Nothing matches',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try a different search, or clear a filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 40,
            ),
            const SizedBox(height: 14),
            const Text(
              'Could not load the species catalogue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
