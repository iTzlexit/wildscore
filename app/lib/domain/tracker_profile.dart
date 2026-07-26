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
  });

  factory TrackerProfile.fromJson(Map<String, dynamic> json) {
    return TrackerProfile(
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      seasonYear: json['seasonYear'] as int,
    );
  }

  /// Creates a profile for the current season.
  factory TrackerProfile.create(String name, {DateTime? now}) {
    final DateTime timestamp = now ?? DateTime.now();
    return TrackerProfile(
      name: sanitiseName(name),
      createdAt: timestamp,
      seasonYear: timestamp.year,
    );
  }

  static const int minNameLength = 2;
  static const int maxNameLength = 20;

  final String name;
  final DateTime createdAt;

  /// The season the tracker joined. Seasons reset annually and the leaderboard
  /// turns over with them; the collection never resets. See docs/VISION.md.
  final int seasonYear;

  /// Single uppercase letter for the profile badge.
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'seasonYear': seasonYear,
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
