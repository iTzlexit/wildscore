import 'package:flutter/material.dart';

import '../data/lifetime_repository.dart';
import '../data/scorecard_repository.dart';
import '../data/species_repository.dart';
import '../data/spotted_repository.dart';
import '../domain/scorecard.dart';
import '../domain/species.dart';
import '../domain/tracker_profile.dart';
import '../shared/theme.dart';
import 'codex/codex_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'profile/profile_screen.dart';
import 'scorecard/start_scorecard_sheet.dart';
import 'scorecard/who_spotted_sheet.dart';

/// The three tabs, plus the camera.
///
/// Order is deliberate: your own record first, the goal second, other people
/// third. A player opens the app to see what they have, not to see a list of
/// animals they do not.
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
  static const LifetimeRepository _lifetimeRepo = LifetimeRepository();

  late final Future<List<Species>> _speciesFuture;
  int _tab = 0;

  /// Held here rather than in either tab, because both read it — the Profile
  /// counts it and the Dex colours by it.
  Set<String> _spotted = <String>{};

  /// Points earned across every day, by this account only.
  int _lifetimePoints = 0;

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
    _lifetimeRepo.loadPoints().then((int points) {
      if (mounted) {
        setState(() => _lifetimePoints = points);
      }
    });
    _cardRepo.load().then((Scorecard? card) {
      if (mounted) {
        setState(() => _card = card);
      }
    });
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

  Future<void> _endScorecard() async {
    // Confirmed, because the day's standings are gone afterwards. What the
    // owner claimed is already in their lifetime record by this point — the
    // credit happens per claim, not at the end, so a phone that dies at the
    // gate still keeps the leopard.
    final bool ok = await _confirm(
      title: 'End the day?',
      message:
          "Today's standings are cleared. Everything you claimed yourself "
          'stays in your collection.',
      action: 'End day',
    );
    if (!ok) {
      return;
    }
    await _cardRepo.clear();
    if (mounted) {
      setState(() => _card = null);
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
      title: 'Restart the game?',
      message:
          'Everyone keeps their place in the car, but every claim today is '
          'wiped — including the points that went to your own total.',
      action: 'Restart',
    );
    if (!ok) {
      return;
    }
    await _updateCard(card.restarted);

    // Wiping the day must wipe what the day gave the owner, otherwise a
    // restart is a way to farm points. The species stay marked as spotted, for
    // the same reason undo leaves them: they may predate today.
    final String? ownerId = card.owner?.id;
    if (ownerId != null) {
      final int refund = card.pointsFor(ownerId);
      if (refund > 0) {
        final int points = await _lifetimeRepo.addPoints(-refund);
        if (mounted) {
          setState(() => _lifetimePoints = points);
        }
      }
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
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
                color: AppColors.danger,
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

  /// A species tapped from the Dex while a game is running.
  ///
  /// [openDetail] is supplied by the Codex, which owns the photo credits. It is
  /// how the sheet can offer the field-guide entry: during a game a tap is a
  /// claim, and without this there was no reachable way to simply look
  /// something up.
  Future<void> _claim(Species species, VoidCallback openDetail) async {
    final Scorecard? card = _card;
    if (card == null) {
      return;
    }
    final String? choice = await WhoSpottedSheet.show(
      context: context,
      species: species,
      card: card,
    );
    if (choice == null || !mounted) {
      return;
    }
    if (choice == WhoSpottedSheet.detailSentinel) {
      openDetail();
      return;
    }
    if (choice == WhoSpottedSheet.unclaimSentinel) {
      final Scorecard next = card.withoutLastClaimOf(species.id);
      await _updateCard(next);
      // An undo has to reach the lifetime total too, or the fix for a mis-tap
      // silently inflates the permanent score. The species stays marked as
      // spotted: it may well have been seen on an earlier trip, and un-spotting
      // it would delete a real record to correct a fake one.
      final Claim? undone = _lastOwnClaim(card, species.id);
      if (undone != null) {
        final int points = await _lifetimeRepo.addPoints(-undone.points);
        if (mounted) {
          setState(() => _lifetimePoints = points);
        }
      }
      return;
    }
    await _updateCard(
      card.withClaim(
        Claim(
          speciesId: species.id,
          playerId: choice,
          at: DateTime.now(),
          points: species.points,
        ),
      ),
    );

    // The account holder's claims are also theirs permanently. This is the
    // whole reason the owner is flagged on the scorecard: a guest's leopard is
    // a guest's, and writing it to this phone's lifetime record would make that
    // record something nobody could trust.
    if (card.owner?.id == choice) {
      await _creditOwner(species);
    }
  }

  /// The claim `withoutLastClaimOf` is about to drop, if the owner made it.
  Claim? _lastOwnClaim(Scorecard card, String speciesId) {
    final String? ownerId = card.owner?.id;
    if (ownerId == null) {
      return null;
    }
    final int index = card.claims.lastIndexWhere(
      (Claim c) => c.speciesId == speciesId,
    );
    if (index < 0 || card.claims[index].playerId != ownerId) {
      return null;
    }
    return card.claims[index];
  }

  Future<void> _creditOwner(Species species) async {
    final Set<String> nextSpotted = await _spottedRepo.add(
      _spotted,
      species.id,
    );
    final int nextPoints = await _lifetimeRepo.addPoints(species.points);
    if (mounted) {
      setState(() {
        _spotted = nextSpotted;
        _lifetimePoints = nextPoints;
      });
    }
  }

  void _onCameraPressed() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceAlt,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 96),
          content: Text(
            'Camera capture arrives in the next update.',
            style: TextStyle(color: AppColors.textPrimary),
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
                lifetimePoints: _lifetimePoints,
                card: _card,
                onStartScorecard: _startScorecard,
                onEndScorecard: _endScorecard,
                onRestartScorecard: _restartScorecard,
              ),
              CodexScreen(
                repository: widget.repository,
                // While a game runs, the Dex colours by what has been claimed
                // today rather than by the lifetime record — the screen you are
                // staring at in the car should answer "have we got it yet".
                caughtIds: _card?.claimedSpecies ?? _spotted,
                onToggleSpotted: _card == null ? _toggleSpotted : null,
                onClaim: _card == null ? null : _claim,
                card: _card,
              ),
              LeaderboardScreen(seasonYear: widget.profile.seasonYear),
            ],
          ),
          floatingActionButton: _CameraButton(onPressed: _onCameraPressed),
          bottomNavigationBar: _BottomBar(
            index: _tab,
            onChanged: (int i) => setState(() => _tab = i),
          ),
        );
      },
    );
  }
}

/// The camera is the primary action of the whole product — one tap from
/// anywhere, per docs/VISION.md. It gets the accent colour and it sits above
/// the tab bar rather than inside it, so it never reads as "one of four things
/// you might do".
class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Standard size, not .large. The large FAB is 96pt and was covering the
    // category counts on the profile — a floating button that hides data is
    // worse than a smaller one. Gold on near-black is prominent enough.
    return Padding(
      padding: const EdgeInsets.only(bottom: 58),
      child: SizedBox(
        width: 62,
        height: 62,
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.accentInk,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.photo_camera_rounded, size: 26),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

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
                icon: Icons.menu_book_rounded,
                label: 'Animal Dex',
                selected: index == 1,
                onTap: () => onChanged(1),
              ),
              _Tab(
                icon: Icons.emoji_events_rounded,
                label: 'Leaderboard',
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.accent : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
