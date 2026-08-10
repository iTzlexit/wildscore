import 'rarity_tier.dart';
import 'scorecard.dart';
import 'species.dart';
import 'species_tag.dart';
import 'trip.dart';
import 'visit.dart';

/// One find worth showing: what it was, who called it, when, and where.
class Sighting {
  const Sighting({
    required this.species,
    required this.finder,
    required this.avatar,
    required this.byOwner,
    required this.at,
    required this.road,
    required this.live,
  });

  final Species species;

  /// The player who called it. A name rather than an id, because ids are minted
  /// per drive and a name is what people remember.
  final String finder;
  final int avatar;

  /// The account holder found it themselves, rather than somebody in the car.
  final bool byOwner;

  final DateTime at;

  /// `S100 · Nkaya Pan`, or null. Null covers location off, no fix, outside the
  /// park — and rhino and pangolin, which never get one. See LocationService.
  final String? road;

  /// From the drive currently in play, so it has not been banked yet.
  final bool live;

  /// Whether this find is one a photograph will eventually have to back up.
  ///
  /// Nothing enforces this yet — verification is a later phase — but the line
  /// is drawn here so the feed and the future check cannot disagree about which
  /// sightings it applies to.
  bool get needsVerifying => species.points >= RarityTier.rare.low;
}

/// The feed of notable finds, newest first.
///
/// **Not every sighting.** A list with every impala on it is a list nobody
/// scrolls, and the interesting question is never "what did you see" but "what
/// did you *get*". So: anything from Rare upwards, plus the Big Five, which
/// earn their place by reputation rather than by points — a lion is a story
/// even on the day four cars are already parked at it.
///
/// Everything is derived from the visit history on each read, the same as
/// Records was. There is no stored feed to drift out of step with the drives it
/// describes.
class Sightings {
  const Sightings._();

  /// The bar for appearing here at all: the bottom of the Rare band.
  ///
  /// Expressed against the band rather than a typed 100, because a tier is a
  /// range now and `rarityTier.points` is only a fallback. Left as a constant
  /// it would have swept the whole Notable tier into the feed — including the
  /// klipspringer, which is not what anybody means by a notable find.
  static int get minimumPoints => RarityTier.scarce.low;

  static bool notable(Species species) =>
      species.points >= minimumPoints ||
      species.tags.contains(SpeciesTag.bigFive);

  static List<Sighting> from(
    List<Visit> visits,
    List<Species> species, {
    Scorecard? live,
  }) {
    final Map<String, Species> byId = <String, Species>{
      for (final Species s in species) s.id: s,
    };
    final List<Sighting> found = <Sighting>[];

    void collect(
      List<Claim> claims,
      List<Player> players, {
      required bool live,
    }) {
      final Map<String, Player> byPlayer = <String, Player>{
        for (final Player p in players) p.id: p,
      };
      for (final Claim claim in claims) {
        final Species? what = byId[claim.speciesId];
        final Player? who = byPlayer[claim.playerId];
        if (what == null || who == null || !notable(what)) {
          continue;
        }
        found.add(
          Sighting(
            species: what,
            finder: who.name,
            avatar: who.avatar,
            byOwner: who.isOwner,
            at: claim.at,
            // Belt and braces. LocationService already refuses to look one up
            // for a rhino or a pangolin, so a stored road on one of these can
            // only come from restored data written by some other build — and
            // this feed is the one screen where publishing it would matter.
            road: what.isSensitive ? null : claim.road,
            live: live,
          ),
        );
      }
    }

    for (final Visit visit in visits) {
      collect(visit.claims, visit.players, live: false);
    }
    if (live != null) {
      collect(live.claims, live.players, live: true);
    }

    // Newest first. A feed that opens on something from last winter is a feed
    // that gets closed.
    found.sort((Sighting a, Sighting b) => b.at.compareTo(a.at));
    return found;
  }

  /// Roads with finds on them, busiest first — the closest thing to a map that
  /// works with no signal and no tiles.
  ///
  /// Sensitive species are already roadless by the time they reach here, so
  /// nothing on this list can point anyone at a rhino.
  static List<RoadTally> roads(List<Sighting> sightings) {
    final Map<String, RoadTally> tallies = <String, RoadTally>{};
    for (final Sighting s in sightings) {
      if (s.road case final String road) {
        (tallies[road] ??= RoadTally._(road))._count++;
      }
    }
    return tallies.values.toList()..sort((RoadTally a, RoadTally b) {
      final int byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.road.compareTo(b.road);
    });
  }

  /// Sightings grouped into the trips they happened on, newest trip first.
  ///
  /// Dates alone read as a wall of headings on a five-day holiday. Trips are
  /// how people remember it — "that time at Satara" — and the gap rule that
  /// defines them already exists.
  static List<TripGroup> byTrip(List<Sighting> sightings) {
    final List<TripGroup> groups = <TripGroup>[];
    for (final Sighting s in sightings) {
      final TripGroup? open = groups.isEmpty ? null : groups.last;
      if (open != null && open.first.difference(s.at).abs() <= Trip.maxGap) {
        open._sightings.add(s);
        open._first = s.at;
      } else {
        groups.add(TripGroup._(s));
      }
    }
    return groups;
  }
}

class RoadTally {
  RoadTally._(this.road);

  final String road;
  int _count = 0;

  int get count => _count;

  /// `S100`, dropping the name. Tags and chips have no room for `S100 · Nkaya`.
  String get short => road.split(' · ').first;
}

/// A run of sightings with no long gap in it — one trip to the park.
class TripGroup {
  TripGroup._(Sighting first)
    : _first = first.at,
      _sightings = <Sighting>[first];

  DateTime _first;
  final List<Sighting> _sightings;

  /// The earliest sighting in the group. The list runs newest-first, so this
  /// moves backwards as the group grows.
  DateTime get first => _first;

  DateTime get last => _sightings.first.at;

  List<Sighting> get sightings => List<Sighting>.unmodifiable(_sightings);

  bool get live => _sightings.any((Sighting s) => s.live);
}
