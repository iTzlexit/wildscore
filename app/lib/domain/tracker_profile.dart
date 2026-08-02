import 'avatar_seed.dart';

/// Who the player is.
///
/// The first thing the app asks for, and deliberately the *only* thing —
/// no email, no password, no account. You give a name and you are in.
/// Sign-in arrives in Phase 4, when sightings need to survive a lost phone.
///
/// "Tracker" rather than anything borrowed from a certain collecting game: in
/// South African safari culture a tracker is the person who finds the animals,
/// which is exactly what the player does.
class TrackerProfile {
  const TrackerProfile({
    required this.name,
    required this.createdAt,
    required this.seasonYear,
    required this.avatar,
  });

  factory TrackerProfile.fromJson(Map<String, dynamic> json) {
    final String name = json['name'] as String;
    return TrackerProfile(
      name: name,
      createdAt: DateTime.parse(json['createdAt'] as String),
      seasonYear: json['seasonYear'] as int,
      // Profiles saved before avatars existed derive theirs from the name,
      // which is the same value they would have been given anyway.
      avatar: json['avatar'] as int? ?? AvatarSeed.forName(name),
    );
  }

  /// Creates a profile for the current season.
  factory TrackerProfile.create(String name, {DateTime? now}) {
    final DateTime timestamp = now ?? DateTime.now();
    final String clean = sanitiseName(name);
    return TrackerProfile(
      name: clean,
      createdAt: timestamp,
      seasonYear: timestamp.year,
      avatar: AvatarSeed.forName(clean),
    );
  }

  static const int minNameLength = 2;
  static const int maxNameLength = 20;

  final String name;
  final DateTime createdAt;

  /// The season the tracker joined. Seasons reset annually and the leaderboard
  /// turns over with them; the collection never resets. See docs/VISION.md.
  final int seasonYear;

  /// The account's face, assigned once and never reshuffled. Guests in a game
  /// get a new avatar each day; the account holder does not, because this is
  /// how other players will come to recognise them.
  final int avatar;

  /// Single uppercase letter for the profile badge.
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'seasonYear': seasonYear,
      'avatar': avatar,
    };
  }

  /// Collapses runs of whitespace and trims. Names appear on a public
  /// leaderboard, so 'A            B' must not be a way to shout.
  static String sanitiseName(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Returns null when the name is acceptable, or a message to show under the
  /// field. Kept in the domain so the rule is testable without a widget.
  static String? validateName(String raw) {
    final String name = sanitiseName(raw);
    if (name.isEmpty) {
      return 'Every tracker needs a name.';
    }
    if (name.length < minNameLength) {
      return 'A little longer — at least $minNameLength characters.';
    }
    if (name.length > maxNameLength) {
      return 'Keep it under $maxNameLength characters.';
    }
    return null;
  }
}
