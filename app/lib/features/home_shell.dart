import 'package:flutter/material.dart';

import '../data/house_rules_repository.dart';
import '../data/location_service.dart';
import '../data/trivia_repository.dart';
import '../data/scorecard_repository.dart';
import '../data/species_repository.dart';
import '../data/spotted_repository.dart';
import '../data/visit_repository.dart';
import '../domain/house_rules.dart';
import '../domain/scorecard.dart';
import '../domain/species.dart';
import '../domain/tracker_profile.dart';
import '../domain/trip.dart';
import '../domain/trivia.dart';
import '../domain/visit.dart';
import '../shared/theme.dart';
import 'codex/codex_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/visit_history_screen.dart';
import 'scorecard/claim_details_sheet.dart';
import 'scorecard/scoring_confirm_screen.dart';
import 'scorecard/spot_picker_screen.dart';
import 'scorecard/start_scorecard_sheet.dart';
import 'scorecard/trivia_sheet.dart';
import 'scorecard/wild_score_screen.dart';

/// The four tabs.
///
/// Order is deliberate: your own record first, today's game second, the goal
/// third, other people last. A player opens the app to see what they have, not
/// to see a list of animals they do not.
///
/// Uses an [IndexedStack] so each tab keeps its scroll position and its search
/// text when you switch away and back. Rebuilding the Codex from scratch every
/// time you glance at your profile would be both slower and irritating.
class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.profile,
    this.repository = const SpeciesRepository(),
    super.key,
  });

  final TrackerProfile profile;
  final SpeciesRepository repository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const SpottedRepository _spottedRepo = SpottedRepository();
  static const ScorecardRepository _cardRepo = ScorecardRepository();
  static const VisitRepository _visitRepo = VisitRepository();
  static const LocationService _location = LocationService();

  late final Future<List<Species>> _speciesFuture;
  int _tab = 0;

  /// Held here rather than in either tab, because both read it — the Profile
  /// counts it and the Dex colours by it.
  Set<String> _spotted = <String>{};

  /// Every finished day. The lifetime total is derived from this, never stored.
  List<Visit> _visits = const <Visit>[];

  /// The day's game, or null when none is running.
  Scorecard? _card;

  /// Everything this car has decided to do differently — its own point values,
  /// its own limits, its own jam tax.
  ///
  /// Held here because the points and the caps have to be folded into the
  /// catalogue at load, and the catalogue is loaded here. Default for almost
  /// everybody.
  HouseRules _rules = HouseRules.none;

  @override
  void initState() {
    super.initState();
    _speciesFuture = _loadSpecies();
    _spottedRepo.load().then((Set<String> ids) {
      if (mounted) {
        setState(() => _spotted = ids);
      }
    });
    _visitRepo.load().then((List<Visit> visits) {
      if (mounted) {
        setState(() => _visits = visits);
      }
    });
    _cardRepo.load().then((Scorecard? card) {
      if (mounted) {
        setState(() => _card = card);
      }
    });
  }

  Future<List<Species>> _loadSpecies() async {
    _rules = await const HouseRulesRepository().load();
    return widget.repository.loadAll(rules: _rules);
  }

  /// Saves a change to the car's rules and rebuilds the catalogue under it.
  ///
  /// Reloads the whole catalogue rather than patching one entry, because the
  /// list is handed to four tabs and a dozen widgets — rebuilding it once is
  /// cheaper than making every one of them aware that a number can change.
  Future<void> _saveRules(HouseRules next) async {
    await const HouseRulesRepository().save(next);
    if (!mounted) {
      return;
    }
    setState(() {
      _rules = next;
      _speciesFuture = widget.repository.loadAll(rules: next);
    });
  }

  Future<void> _setHousePoints(String id, int? points) {
    final Map<String, int> next = <String, int>{..._rules.points};
    if (points == null) {
      next.remove(id);
    } else {
      next[id] = points;
    }
    return _saveRules(_rules.copyWith(points: next));
  }

  /// A limit on one species, or `reset` to hand it back to the catalogue.
  ///
  /// Three states, not two: a cap, no cap, and no opinion. A car that wants
  /// unlimited impala has to be able to say so, and that is not the same as
  /// never having asked — the default can still move under the second.
  Future<void> _setHouseCap(String id, SpeciesCap? cap, {bool reset = false}) {
    final Map<String, SpeciesCap?> next = <String, SpeciesCap?>{..._rules.caps};
    if (reset) {
      next.remove(id);
    } else {
      next[id] = cap;
    }
    return _saveRules(_rules.copyWith(caps: next));
  }

  /// Re-reads everything from disk. Called after a restore, which rewrites the
  /// stores underneath this widget without going through it.
  Future<void> _reload() async {
    final Set<String> spotted = await _spottedRepo.load();
    final List<Visit> visits = await _visitRepo.load();
    if (mounted) {
      setState(() {
        _spotted = spotted;
        _visits = visits;
      });
    }
  }

  Future<void> _toggleSpotted(String id) async {
    final Set<String> next = await _spottedRepo.toggle(_spotted, id);
    if (mounted) {
      setState(() => _spotted = next);
    }
  }

  /// Opens the question this player has unlocked.
  ///
  /// The question is chosen from what they have not seen and recorded as asked
  /// **before** the sheet opens, so closing it and coming back cannot shop for
  /// an easier one. A wrong answer costs the question, which is the only thing
  /// that makes a right one worth thirty points.
  Future<void> _askQuestion(Player player) async {
    final Scorecard? card = _card;
    if (card == null) {
      return;
    }
    const TriviaRepository repo = TriviaRepository();
    final List<TriviaQuestion> bank = await repo.loadAll();
    final TriviaQuestion? q = repo.next(bank, card.trivia, player.id);
    if (q == null || !mounted) {
      return;
    }

    await _updateCard(card.withTrivia(card.trivia.withAsked(player.id, q.id)));
    if (!mounted) {
      return;
    }
    final bool right = await TriviaSheet.ask(
      context,
      player: player,
      question: q,
    );
    final Scorecard? latest = _card;
    if (!right || latest == null) {
      return;
    }
    await _updateCard(latest.withTrivia(latest.trivia.withCorrect(player.id)));
  }

  /// Who is in the car, then what everything is worth, then go.
  ///
  /// The prices screen is Alex's rule and it is a good one: an argument about
  /// what a sable is worth is funny at the gate and sour at four in the
  /// afternoon when somebody has already scored one. It is one tap for a car
  /// that agrees with us, and prices are saved, so the second morning is one
  /// tap as well.
  Future<void> _startScorecard(List<Species> species) async {
    final List<String>? names = await StartScorecardSheet.show(
      context,
      owner: widget.profile.name,
    );
    if (names == null || names.isEmpty || !mounted) {
      return;
    }
    final bool go = await ScoringConfirmScreen.show(
      context,
      species: species,
      players: names,
      onSetPoints: _setHousePoints,
    );
    if (!go || !mounted) {
      return;
    }
    final Scorecard card = Scorecard.start(names, owner: widget.profile.name);
    await _cardRepo.save(card);
    if (mounted) {
      setState(() => _card = card);
    }
  }

  /// Ends the day and banks it.
  ///
  /// This is the only moment points become permanent. Crediting per claim was
  /// simpler to explain but meant undo and restart each had to reverse
  /// themselves correctly, and every one of those paths was a way for a
  /// lifetime total to drift with nothing to check it against. Banking once, at
  /// a deliberate act, removes the whole class of bug — and the day is
  /// persisted throughout, so nothing is at risk if the phone dies at the gate.
  Future<void> _endScorecard() async {
    final Scorecard? card = _card;
    if (card == null) {
      return;
    }
    final int mine = card.owner == null ? 0 : card.pointsFor(card.owner!.id);
    final Visit pending = Visit.from(card);
    final int newToCollection = pending.collectedSpecies
        .where((String id) => !_spotted.contains(id))
        .length;
    final bool ok = await _confirm(
      title: 'End the day?',
      message:
          'The drive is saved to your history with everyone who played, and '
          'your $mine points join your lifetime total.'
          '${newToCollection == 0 ? '' : ' $newToCollection new '
                    '${newToCollection == 1 ? 'species joins' : 'species join'} '
                    'your collection.'}'
          ' This cannot be undone.',
      action: 'End day',
      danger: false,
    );
    if (!ok) {
      return;
    }

    final Visit visit = pending;
    final List<Visit> visits = await _visitRepo.add(visit);

    // Everything *anyone* in the car called enters the owner's collection —
    // they were there and they saw it. Points stay with whoever called it
    // first, because that is a different question. See Visit.collectedSpecies.
    Set<String> spotted = _spotted;
    for (final String id in visit.collectedSpecies) {
      spotted = await _spottedRepo.add(spotted, id);
    }

    await _cardRepo.clear();
    if (mounted) {
      setState(() {
        _card = null;
        _visits = visits;
        _spotted = spotted;
      });
    }
  }

  /// Takes one animal back off a player, from the standings.
  ///
  /// Confirmed, and the dialog names the person and the points — this is the
  /// one destructive action in the game that someone else is watching over your
  /// shoulder while you do it.
  Future<void> _removeClaim(Player player, Species species) async {
    final Scorecard? card = _card;
    if (card == null) {
      return;
    }
    // What that claim actually paid, not what the species is worth. Since
    // sightings carry a crowd multiplier and a variant bonus those are two
    // different numbers — a male lion found alone is 200 against a tier value
    // of 40, and a dialog that says 40 is about to lose somebody 200.
    Claim? claim;
    for (final Claim c in card.claims) {
      if (c.playerId == player.id && c.speciesId == species.id) {
        claim = c;
      }
    }
    final bool ok = await _confirm(
      title: 'Take it back?',
      message:
          'Removes one ${species.commonName} from ${player.name} '
          '— ${claim?.points ?? species.points} points.',
      action: 'Remove',
    );
    if (!ok) {
      return;
    }
    await _updateCard(card.withoutClaimBy(player.id, species.id));
  }

  Future<void> _deleteVisit(Visit visit) async {
    final List<Visit> visits = await _visitRepo.remove(visit);
    if (mounted) {
      setState(() => _visits = visits);
    }
  }

  /// Same players, no claims. The common case is "we scored the first hour
  /// wrong", and that must not cost anyone four names retyped at a gate.
  Future<void> _restartScorecard() async {
    final Scorecard? card = _card;
    if (card == null) {
      return;
    }
    final bool ok = await _confirm(
      title: 'Restart the drive?',
      message:
          'Everyone keeps their place in the car, but every claim today is '
          'wiped. Nothing has been banked yet, so your record is untouched.',
      action: 'Restart',
    );
    if (!ok) {
      return;
    }
    await _updateCard(card.restarted);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool danger = true,
  }) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppText.title3),
        content: Text(message, style: AppText.body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: AppText.label),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              action,
              style: AppText.label.copyWith(
                color: danger ? AppColors.danger : AppColors.accent,
                fontVariations: AppFonts.weight(700),
              ),
            ),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _updateCard(Scorecard next) async {
    await _cardRepo.save(next);
    if (mounted) {
      setState(() => _card = next);
    }
  }

  /// "Sam spotted something" — the picker, opened from Sam's row.
  ///
  /// Claiming used to start in the Animal Dex and then ask *who*. That put the
  /// Dex in two minds — a tap meant different things depending on state you
  /// could not see — and it asked the question backwards. In a car the name
  /// comes first, because somebody shouts it.
  Future<void> _spotFor(Player player, List<Species> species) async {
    final Scorecard? card = _card;
    if (card == null) {
      return;
    }
    final Set<String> spent = Trip.bonusesSpent(
      species,
      visits: _visits,
      live: card,
    );
    final Species? chosen = await SpotPickerScreen.open(
      context,
      player: player,
      species: species,
      card: card,
      wildCardsSpent: spent,
    );
    if (chosen == null || !mounted) {
      return;
    }

    // The first zebra of the morning pays 50; the second pays 5 like any other
    // zebra. The bonus is decided here, once, and then stored on the claim —
    // so a day scored months ago stays explicable even if the rule changes.
    final bool earnsBonus = chosen.isWildCard && !spent.contains(chosen.id);

    // Was it a male, and was anybody else there. Only asked about animals
    // where the answer changes something, so an impala never sees this.
    // Dismissing it cancels the claim rather than scoring an ordinary one —
    // backing out of a half-finished claim must not quietly bank points.
    final ClaimDetails? details = await ClaimDetailsSheet.ask(
      context,
      chosen,
      jamMultiplier: _rules.jamMultiplier,
    );
    if (details == null || !mounted) {
      return;
    }

    // Which road, if the phone can say so. Awaited rather than fired off,
    // because a fix that lands after the claim is written is a fix that belongs
    // to nothing — but it is capped at a few seconds and returns null on every
    // failure, so the claim is never blocked for long and never blocked hard.
    final String? road = await _location.roadFor(chosen);

    final Scorecard? latest = _card;
    if (latest == null) {
      return;
    }

    await _updateCard(
      latest.withClaim(
        Claim(
          speciesId: chosen.id,
          playerId: player.id,
          at: DateTime.now(),
          points: chosen.scoreFor(
            wildCardBonusEarned: earnsBonus,
            variantsApplied: details.variants,
            context: details.context,
            extras: details.extras,
            // Which one of the day this is, counting from one. Only elephant
            // and buffalo care: neither can be capped, being Big Five, but the
            // fourteenth elephant is not the event the second one was.
            sightingsToday: latest.timesClaimed(chosen.id) + 1,
            jamMultiplier: _rules.jamMultiplier,
          ),
          road: road,
          context: details.context,
          variants: details.variants,
          extras: details.extras,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Species>>(
      future: _speciesFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Species>> snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final List<Species> species = snapshot.data!;

        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _tab,
            children: <Widget>[
              ProfileScreen(
                profile: widget.profile,
                species: species,
                caughtIds: _spotted,
                visits: _visits,
                card: _card,
                onOpenGame: () => setState(() => _tab = 1),
                onDeleteVisit: _deleteVisit,
                onRestored: _reload,
                onToggleSpotted: _toggleSpotted,
                rules: _rules,
                onRulesChanged: _saveRules,
              ),
              WildScoreScreen(
                species: species,
                card: _card,
                onStart: () => _startScorecard(species),
                onEnd: _endScorecard,
                onRestart: _restartScorecard,
                onRemoveClaim: _removeClaim,
                onSpotFor: (Player p) => _spotFor(p, species),
                onQuizFor: _askQuestion,
                onOpenHistory: () => VisitHistoryScreen.open(
                  context,
                  visits: _visits,
                  species: species,
                  live: _card,
                  onDelete: _deleteVisit,
                ),
              ),
              // Always a field guide, never a claim surface. Marking something
              // spotted here is the life list — no points, no drive — and it
              // stays available whether or not a game is running.
              CodexScreen(
                repository: widget.repository,
                caughtIds: _spotted,
                onToggleSpotted: _toggleSpotted,
                rules: _rules,
                onSetPoints: _setHousePoints,
                onSetCap: _setHouseCap,
              ),
            ],
          ),
          // No camera button. It sat over the content on every tab and did
          // nothing but apologise — a permanent advertisement for a feature
          // that does not exist. Verified capture is Phase 2; see
          // docs/SPEC.md, and it comes back with a purpose rather than as a
          // placeholder.
          bottomNavigationBar: _BottomBar(
            index: _tab,
            onChanged: (int i) => setState(() => _tab = i),
            driveInPlay: _card != null,
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.onChanged,
    required this.driveInPlay,
  });

  final int index;
  final ValueChanged<int> onChanged;

  /// Puts a live dot on the Wild Score tab. A game running on a tab you are not
  /// looking at should say so — otherwise the phone gets handed to the back
  /// seat and the day quietly stops being scored.
  final bool driveInPlay;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFAFFFFFF),
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: <Widget>[
              _Tab(
                icon: Icons.person_rounded,
                label: 'Profile',
                selected: index == 0,
                onTap: () => onChanged(0),
              ),
              _Tab(
                icon: Icons.sports_score_rounded,
                label: 'Wild Score',
                selected: index == 1,
                onTap: () => onChanged(1),
                live: driveInPlay,
              ),
              _Tab(
                icon: Icons.menu_book_rounded,
                label: 'Animals',
                selected: index == 2,
                onTap: () => onChanged(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.live = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.accent : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Icon(icon, size: 21, color: color),
                if (live)
                  Positioned(
                    right: -3,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
