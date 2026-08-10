import 'package:flutter/material.dart';

import '../../data/attribution_repository.dart';
import '../../data/species_repository.dart';
import '../../domain/house_rules.dart';
import '../../domain/park_region.dart';
import '../../domain/rarity_tier.dart';
import '../../domain/species.dart';
import '../../domain/species_category.dart';
import '../../domain/species_tag.dart';
import '../../domain/tracker_profile.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/species_image.dart';
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
    this.onToggleSpotted,
    this.rules = HouseRules.none,
    this.onSetPoints,
    this.onSetCap,
    super.key,
  });

  /// Marks a species seen — the life list, which costs nothing and scores
  /// nothing. Null in tests.
  ///
  /// The Dex no longer claims for a game. That happens on the Wild Score tab,
  /// from the row of whoever shouted, which leaves this screen with exactly one
  /// meaning: a tap opens the field-guide entry, always.
  final ValueChanged<String>? onToggleSpotted;

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

  /// Everything this car has decided to do differently.
  ///
  /// Folded into the catalogue at load, so nothing below here has to know it
  /// exists. Default for almost everybody.
  final HouseRules rules;

  /// Revalue a species, or pass null to put it back to the catalogue's figure.
  /// Null in tests and wherever the table is read-only.
  final void Function(String id, int? points)? onSetPoints;

  /// Limit an animal, or pass reset to hand it back to the catalogue.
  final void Function(String id, SpeciesCap? cap, {bool reset})? onSetCap;

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  /// Not `late final`: revaluing a species reloads the catalogue, and this
  /// screen's state survives a tab switch, so `initState` will not run again.
  late Future<List<Species>> _speciesFuture;
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  SpeciesCategory? _category;
  RarityTier? _tier;
  ParkRegion? _region;
  SpeciesTag? _tag;
  SpottedFilter _spotted = SpottedFilter.all;
  SpeciesSort _sort = SpeciesSort.rarest;
  bool _filtersExpanded = false;

  /// Two ways to look at the same catalogue.
  ///
  /// The grid is for browsing — big photographs, grouped animals then birds.
  /// The list is a **ranking**: one line each, rarest at the top, straight
  /// through from the pangolin to the impala. Different questions, and a grid
  /// answers the second one badly.
  bool _listView = false;
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
    _speciesFuture = widget.repository.loadAll(rules: widget.rules);

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
  void didUpdateWidget(CodexScreen old) {
    super.didUpdateWidget(old);
    // Identity, not deep equality: the shell rebuilds this object only when it
    // has actually saved a change, and comparing two maps of maps on every
    // frame to learn what the caller already knows is work for nothing.
    if (!identical(old.rules, widget.rules)) {
      _speciesFuture = widget.repository.loadAll(rules: widget.rules);
    }
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
            // Rhino and pangolin match every region, which is the same thing
            // as matching none: filtering to the south and finding a white
            // rhino there is a coarse answer to "where do I go", and the Where
            // to find tab was removed for exactly that reason. Excluding them
            // instead would leak it the other way — filter each region in turn,
            // note where they are missing.
            (_region == null ||
                species.isSensitive ||
                species.parkRegions.contains(_region)) &&
            (_tag == null || species.tags.contains(_tag)) &&
            _spotted.matches(widget.caughtIds.contains(species.id)))
          species,
    ]..sort(_sort.compare);
  }

  void _openDetail(Species species) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SpeciesDetailScreen(
          species: species,
          photoCredit: _credits[species.id],
          spotted: widget.caughtIds.contains(species.id),
          // No pop. The detail screen tracks its own state now, so the button
          // simply changes — which is what a toggle should do, and what makes
          // changing your mind twice in a row possible.
          onToggleSpotted: widget.onToggleSpotted == null
              ? null
              : () => widget.onToggleSpotted!(species.id),
          onSetPoints: widget.onSetPoints == null
              ? null
              : (int? points) => widget.onSetPoints!(species.id, points),
          onSetCap: widget.onSetCap == null
              ? null
              : (SpeciesCap? cap, {bool reset = false}) =>
                    widget.onSetCap!(species.id, cap, reset: reset),
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
                    const AppHeader(),
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
                      sort: _sort,
                      onSort: () => setState(() => _sort = _sort.next),
                      onClear: _clearFilters,
                      listView: _listView,
                      onToggleView: () =>
                          setState(() => _listView = !_listView),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? const _EmptyState()
                          : CustomScrollView(
                              slivers: <Widget>[
                                if (_listView)
                                  _rankedSliver(visible)
                                else
                                  ..._groupedSlivers(visible),
                                // The park boundary, stated once, at the point
                                // where someone has just scrolled the whole
                                // catalogue and might reasonably wonder where
                                // the rest of Africa is.
                                const SliverToBoxAdapter(
                                  child: ComingSoonParks(),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 110),
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }

  /// Animals, then birds, each under its own heading.
  ///
  /// The catalogue used to be one continuous grid, which was right at 127
  /// species and stopped being right at 191. Birds are now 124 of them, so a
  /// single list interleaved by rarity buries every mammal that is not
  /// Legendary somewhere below a hundred birds — and "where is the kudu" became
  /// a scroll rather than a glance.
  ///
  /// Two groups rather than five. Reptiles, the two insects and the baobab go
  /// in with the animals because nobody browsing a game park thinks of a
  /// leopard tortoise as a separate department, and three tiny sections would
  /// be more furniture than help. The chosen sort still applies *inside* each
  /// group, so rarest-first works exactly as before.
  List<Widget> _groupedSlivers(List<Species> visible) {
    final List<Species> birds = <Species>[
      for (final Species s in visible)
        if (s.category == SpeciesCategory.bird) s,
    ];
    final List<Species> animals = <Species>[
      for (final Species s in visible)
        if (s.category != SpeciesCategory.bird) s,
    ];

    // A heading over a single group is noise — filtering to Birds already says
    // what you are looking at.
    final bool labelled = birds.isNotEmpty && animals.isNotEmpty;

    return <Widget>[
      for (final (String label, List<Species> group)
          in <(String, List<Species>)>[('Animals', animals), ('Birds', birds)])
        if (group.isNotEmpty) ...<Widget>[
          if (labelled)
            SliverToBoxAdapter(
              child: _GroupHeading(label: label, count: group.length),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, Space.xl),
            sliver: _grid(group),
          ),
        ],
    ];
  }

  /// One line each, rarest first, numbered.
  ///
  /// **Not the grid with smaller pictures.** The grid answers "what is in the
  /// park"; this answers "what is worth the most", which is the question a car
  /// asks at breakfast. So it ignores the Animals/Birds split — a ranking with
  /// two separate number ones is not a ranking — and it ignores the sort,
  /// because rarest-first is the only order in which it means anything.
  Widget _rankedSliver(List<Species> visible) {
    final List<Species> ranked = <Species>[...visible]
      ..sort(SpeciesSort.rarest.compare);

    return SliverList.builder(
      itemCount: ranked.length,
      itemBuilder: (BuildContext context, int i) => _RankedRow(
        species: ranked[i],
        rank: i + 1,
        spotted: widget.caughtIds.contains(ranked[i].id),
        onTap: () => _openDetail(ranked[i]),
      ),
    );
  }

  Widget _grid(List<Species> visible) {
    return SliverGrid.builder(
      // maxCrossAxisExtent rather than a fixed column
      // count, so a small phone gets 2 columns and a
      // tablet gets 4 without any breakpoint logic.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: SpeciesGridCard.aspectRatio,
      ),
      itemCount: visible.length,
      itemBuilder: (BuildContext context, int index) {
        final Species species = visible[index];
        return SpeciesGridCard(
          species: species,
          // Greyed until spotted. The tile is the tease; the
          // detail screen still carries the full field-guide
          // entry, so the free tier stays genuinely useful.
          locked: !widget.caughtIds.contains(species.id),
          onToggleSpotted: widget.onToggleSpotted == null
              ? null
              : () => widget.onToggleSpotted!(species.id),
          onTap: () => _openDetail(species),
        );
      },
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

/// How the grid is ordered.
///
/// Rarest first is the default, and it is a product decision rather than a
/// neutral one. A catalogue that opens on impala says "here is a list of
/// animals"; one that opens on pangolin says "here is what you are hunting
/// for". The second is the app. Dex order remains available because a numbered
/// catalogue is genuinely easier to hold in your head over a week.
enum SpeciesSort {
  rarest(label: 'Rarest first'),
  dex(label: 'Dex order'),
  alphabetical(label: 'A–Z');

  const SpeciesSort({required this.label});

  final String label;

  int compare(Species a, Species b) => switch (this) {
    SpeciesSort.rarest => _byTier(a, b),
    SpeciesSort.dex => a.dexNumber.compareTo(b.dexNumber),
    SpeciesSort.alphabetical => a.commonName.compareTo(b.commonName),
  };

  /// By what it is worth, then by name.
  ///
  /// It used to sort by *tier* and then alphabetically, which was the same
  /// thing back when every animal in a tier scored identically. It is not the
  /// same thing now: that put the aardvark above the pangolin because A comes
  /// before G, on a list whose whole promise is that the top is the hardest
  /// thing in the park.
  ///
  /// Points already imply the tier — the bands do not overlap — so this is the
  /// stronger sort and the tier ordering falls out of it.
  static int _byTier(Species a, Species b) {
    final int points = b.points.compareTo(a.points);
    return points != 0 ? points : a.commonName.compareTo(b.commonName);
  }

  SpeciesSort get next =>
      SpeciesSort.values[(index + 1) % SpeciesSort.values.length];
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
    required this.sort,
    required this.onSort,
    required this.onClear,
    required this.listView,
    required this.onToggleView,
  });

  final int count;
  final int total;
  final int activeFilterCount;
  final SpeciesSort sort;
  final VoidCallback onSort;
  final VoidCallback onClear;
  final bool listView;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
      child: Row(
        children: <Widget>[
          // Flexible rather than followed by a Spacer: with a filter active
          // there are now two buttons on this row, and at large accessibility
          // text scales the fixed count was what pushed it over the edge.
          Expanded(
            child: Text(
              count == total ? 'All $total species' : '$count of $total',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (activeFilterCount > 0)
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Clear filters',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          // Stripped of its default 48pt tap target and 8pt padding. This row
          // already carries a count, a clear button and a sort cycle, and the
          // stock IconButton pushed it 8.5 pixels over the edge the moment a
          // filter was active.
          IconButton(
            onPressed: onToggleView,
            tooltip: listView ? 'Show the grid' : 'Show the ranking',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              listView ? Icons.grid_view_rounded : Icons.format_list_numbered,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          // Cycles rather than opening a menu. Three options is under the
          // threshold where a menu earns its extra tap.
          TextButton.icon(
            onPressed: onSort,
            icon: const Icon(Icons.swap_vert_rounded, size: 16),
            label: Text(
              sort.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

/// One animal in the ranked list.
///
/// Deliberately thin — number, thumbnail, name, points. At 190 rows the value
/// is being able to run your eye down the right-hand column, and anything else
/// on the line is in the way of that.
class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.species,
    required this.rank,
    required this.spotted,
    required this.onTap,
  });

  final Species species;
  final int rank;
  final bool spotted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final RarityStyle style = species.rarityTier.style;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                textAlign: TextAlign.right,
                style: AppText.caption.copyWith(
                  color: AppColors.textMuted,
                  fontFeatures: AppText.tabular,
                ),
              ),
            ),
            const SizedBox(width: Space.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 40,
                height: 40,
                child: SpeciesImage(species: species, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    species.commonName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong.copyWith(fontSize: 14.5),
                  ),
                  Text(
                    species.rarityTier.label,
                    style: AppText.caption.copyWith(color: style.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.sm),
            if (spotted)
              const Padding(
                padding: EdgeInsets.only(right: Space.sm),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: AppColors.verified,
                ),
              ),
            Text(
              '${species.points}',
              style: AppText.bodyStrong.copyWith(
                color: style.accent,
                fontFeatures: AppText.tabular,
                fontVariations: AppFonts.weight(800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "ANIMALS · 67" over each half of the catalogue.
///
/// Carries the count because the number is the reassurance: it tells you the
/// list below is finite before you start scrolling it.
class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, Space.md, 16, 2),
      child: Row(
        children: <Widget>[
          Text(label.toUpperCase(), style: AppText.overline),
          const SizedBox(width: Space.sm),
          Text(
            '$count',
            style: AppText.overline.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: Space.md),
          const Expanded(child: Divider(height: 1, color: AppColors.outline)),
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
