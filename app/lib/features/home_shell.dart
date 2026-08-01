import 'package:flutter/material.dart';

import '../data/species_repository.dart';
import '../domain/species.dart';
import '../domain/tracker_profile.dart';
import '../shared/theme.dart';
import 'codex/codex_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'profile/profile_screen.dart';

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
  late final Future<List<Species>> _speciesFuture;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _speciesFuture = widget.repository.loadAll();
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
              ProfileScreen(profile: widget.profile, species: species),
              CodexScreen(repository: widget.repository),
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
