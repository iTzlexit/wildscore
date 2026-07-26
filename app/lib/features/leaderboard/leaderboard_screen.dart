import 'package:flutter/material.dart';

import '../../shared/theme.dart';

/// Placeholder until Phase 5.
///
/// Shows what the board will contain rather than an apology. A locked screen
/// that explains the prize is motivating; "Coming soon" is not.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({required this.seasonYear, super.key});

  final int seasonYear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
          children: <Widget>[
            const Text(
              'Leaderboard',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Season $seasonYear',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 17,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Opens when trackers start catching',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Ranked on verified sightings. Seasons reset each year, so '
                    'the board is always winnable — but your collection never '
                    'resets.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'FOUR WAYS TO WIN',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 14),
            const _BoardPreview(
              icon: Icons.emoji_events_rounded,
              title: 'Season score',
              blurb:
                  'Every verified sighting this year. Rewards getting out '
                  'into the park.',
            ),
            const _BoardPreview(
              icon: Icons.local_activity_rounded,
              title: 'Best single trip',
              blurb:
                  'One visit, one score. A once-a-year family can top this '
                  'one.',
            ),
            const _BoardPreview(
              icon: Icons.grid_view_rounded,
              title: 'Collection',
              blurb:
                  'How much of the park you have found. Built over years, '
                  'not bought.',
            ),
            const _BoardPreview(
              icon: Icons.auto_awesome_rounded,
              title: 'Rarest find',
              blurb: 'One lucky pangolin beats a hundred impala.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview({
    required this.icon,
    required this.title,
    required this.blurb,
  });

  final IconData icon;
  final String title;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  blurb,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
