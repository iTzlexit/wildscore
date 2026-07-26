import 'package:flutter/material.dart';

import '../data/profile_repository.dart';
import '../domain/tracker_profile.dart';
import '../shared/theme.dart';
import 'home_shell.dart';
import 'onboarding/onboarding_screen.dart';

/// Decides what the app opens on: onboarding for a new tracker, the Codex for
/// a returning one.
///
/// A backend equivalent would be the middleware that checks for a session
/// before routing. The difference is that this runs on every cold start and the
/// answer comes off local disk, so it has to be fast — anything slow here is a
/// visible splash screen.
class AppRoot extends StatefulWidget {
  const AppRoot({
    this.profileRepository = const ProfileRepository(),
    super.key,
  });

  final ProfileRepository profileRepository;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late Future<TrackerProfile?> _profileFuture;
  TrackerProfile? _profile;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.profileRepository.load();
  }

  Future<void> _completeOnboarding(TrackerProfile profile) async {
    await widget.profileRepository.save(profile);
    if (!mounted) {
      return;
    }
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TrackerProfile?>(
      future: _profileFuture,
      builder: (BuildContext context, AsyncSnapshot<TrackerProfile?> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final TrackerProfile? profile = _profile ?? snapshot.data;
        if (profile == null) {
          return OnboardingScreen(onComplete: _completeOnboarding);
        }
        return HomeShell(profile: profile);
      },
    );
  }
}
