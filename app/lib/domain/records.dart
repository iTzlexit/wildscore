import 'scorecard.dart';
import 'species.dart';
import 'visit.dart';

/// Personal bests, and the running score against everyone you have played with.
///
/// This exists because the leaderboard cannot. A public board needs a server,
/// accounts and moderation, and the app is deliberately not getting any of
/// those — see docs/MONETISATION.md.
///
/// What it replaces it with is better suited to how this is actually played:
/// the person you want to beat is not a stranger in Pretoria, it is your
/// brother, and he was in the car. **A rivalry with somebody you know is worth
/// more than a rank against somebody you do not.**
///
/// Everything here is derived from the visit history on each read. There is no
/// stored state to drift, and a season of drives is a few hundred claims —
/// cheap enough to recompute whenever the screen opens.
class Records {
  const Records({
    required this.visits,
    required this.bestDrive,
    required this.rarest,
    required this.rivals,
  });

  factory Records.from(List<Visit> visits, List<Species> species) {
    final Map<String, Species> byId = <String, Species>{
      for (final Species s in species) s.id: s,
    };

    Visit? best;
    _Find? rarest;
    final Map<String, _RivalTally> tallies = <String, _RivalTally>{};

    for (final Visit visit in visits) {
      final Player? me = visit.owner;
      if (me == null) {
        // The phone was lent out that day. It is somebody's record, but not
        // this account's.
        continue;
      }

      if (best == null || visit.ownerPoints > best.ownerPoints) {
        best = visit;
      }

      // The rarest thing *you* found, not the rarest thing the car found.
      // A record you did not earn is not a record.
      for (final Claim claim in visit.claims) {
        if (claim.playerId != me.id) {
          continue;
        }
        final Species? found = byId[claim.speciesId];
        if (found == null) {
          continue;
        }
        if (rarest == null || found.points > rarest.species.points) {
          rarest = _Find(species: found, on: visit.endedAt);
        }
      }

      if (visit.wasSolo) {
        continue;
      }

      final int mine = visit.pointsFor(me.id);
      for (final Player other in visit.players) {
        if (other.id == me.id) {
          continue;
        }
        // Keyed on name, not id — player ids are minted per drive, so the same
        // brother is a different id every single time.
        final String key = other.name.toLowerCase();
        final _RivalTally tally = tallies.putIfAbsent(
          key,
          () => _RivalTally(name: other.name, avatar: other.avatar),
        );
        tally.drives++;
        final int theirs = visit.pointsFor(other.id);
        if (mine > theirs) {
          tally.wins++;
        } else if (theirs > mine) {
          tally.losses++;
        } else {
          tally.draws++;
        }
      }
    }

    final List<Rival> rivals =
        tallies.values
            .map(
              (_RivalTally t) => Rival(
                name: t.name,
                avatar: t.avatar,
                drives: t.drives,
                wins: t.wins,
                losses: t.losses,
                draws: t.draws,
              ),
            )
            .toList()
          // Most-played first: the person you argue with most is the one you
          // want to see at the top.
          ..sort((Rival a, Rival b) => b.drives.compareTo(a.drives));

    return Records(
      visits: visits,
      bestDrive: best,
      rarest: rarest == null
          ? null
          : RarestFind(species: rarest.species, on: rarest.on),
      rivals: rivals,
    );
  }

  final List<Visit> visits;

  /// The highest-scoring day this account has had.
  final Visit? bestDrive;

  /// The hardest thing they have personally called.
  final RarestFind? rarest;

  final List<Rival> rivals;

  int get drivesPlayed => visits.length;

  int get lifetimePoints =>
      visits.fold(0, (int sum, Visit v) => sum + v.ownerPoints);

  /// Claims made by the account holder, across every drive. Counts repeats —
  /// two leopards on two days is two sightings.
  int get sightings => visits.fold(0, (int sum, Visit v) {
    final Player? me = v.owner;
    if (me == null) {
      return sum;
    }
    return sum + v.claims.where((Claim c) => c.playerId == me.id).length;
  });

  bool get isEmpty => visits.isEmpty;
}

class RarestFind {
  const RarestFind({required this.species, required this.on});

  final Species species;
  final DateTime on;
}

/// Somebody you have shared a car with, and how it has gone.
class Rival {
  const Rival({
    required this.name,
    required this.avatar,
    required this.drives,
    required this.wins,
    required this.losses,
    required this.draws,
  });

  final String name;
  final int avatar;
  final int drives;

  /// Days you out-scored them, they out-scored you, and dead heats.
  final int wins;
  final int losses;
  final int draws;

  bool get ahead => wins > losses;
  bool get level => wins == losses;
}

class _Find {
  const _Find({required this.species, required this.on});

  final Species species;
  final DateTime on;
}

class _RivalTally {
  _RivalTally({required this.name, required this.avatar});

  final String name;
  final int avatar;
  int drives = 0;
  int wins = 0;
  int losses = 0;
  int draws = 0;
}
