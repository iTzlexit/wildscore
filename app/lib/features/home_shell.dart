import 'package:flutter/material.dart';

import '../data/scorecard_repository.dart';
import '../data/species_repository.dart';
import '../data/spotted_repository.dart';
import '../data/visit_repository.dart';
import '../domain/scorecard.dart';
import '../domain/species.dart';
import '../domain/tracker_profile.dart';
import '../domain/visit.dart';
import '../shared/theme.dart';
import 'codex/codex_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'profile/profile_screen.dart';
import 'scorecard/spot_picker_screen.dart';
import 'scorecard/start_scorecard_sheet.dart';
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

  late final Future<List<Species>> _speciesFuture;
  int _tab = 0;

  /// Held here rather than in either tab, because both read it — the Profile
  /// counts it and the Dex colours by it.
  Set<String> _spotted = <String>{};

  /// Every finished day. The lifetime total is derived from this, never stored.
  List<Visit> _visits = const <Visit>[];

  /// The day's game, or null when none is running.
  Scorecard? _card;

  @override
  void initState() {
    super.initState();
    _speciesFuture = widget.repository.loadAll();
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

  Future<void> _startScorecard() async {
    final List<String>? names = await StartScorecardSheet.show(
      context,
      owner: widget.profile.name,
    );
    if (names == null || names.isEmpty || !mounted) {
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
    final bool ok = await _confirm(
      title: 'Take it back?',
      message:
          'Removes one ${species.commonName} from ${player.name} '
          '— ${species.points} points.',
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
    final Species? chosen = await SpotPickerScreen.open(
      context,
      player: player,
      species: species,
      card: card,
    );
    if (chosen == null || !mounted) {
      return;
    }
    await _updateCard(
      card.withClaim(
        Claim(
          speciesId: chosen.id,
          playerId: player.id,
          at: DateTime.now(),
          points: chosen.points,
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
              ),
              WildScoreScreen(
                species: species,
                card: _card,
                onStart: _startScorecard,
                onEnd: _endScorecard,
                onRestart: _restartScorecard,
                onRemoveClaim: _removeClaim,
                onSpotFor: (Player p) => _spotFor(p, species),
              ),
              // Always a field guide, never a claim surface. Marking something
              // spotted here is the life list — no points, no drive — and it
              // stays available whether or not a game is running.
              CodexScreen(
                repository: widget.repository,
                caughtIds: _spotted,
                onToggleSpotted: _toggleSpotted,
              ),
              LeaderboardScreen(seasonYear: widget.profile.seasonYear),
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
                label: 'Animal Dex',
                selected: index == 2,
                onTap: () => onChanged(2),
              ),
              _Tab(
                icon: Icons.emoji_events_rounded,
                label: 'Leaderboard',
                selected: index == 3,
                onTap: () => onChanged(3),
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
