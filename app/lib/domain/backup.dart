import 'dart:convert';

import 'tracker_profile.dart';
import 'visit.dart';

/// Everything worth keeping, in one portable blob.
///
/// The app stores its whole record in `shared_preferences` on one phone. The
/// operating system *might* back that up — Android only over Wi-Fi, while idle
/// and charging, silently when it fails; iOS only with iCloud Backup switched
/// on and space free. Partial, invisible and unverifiable, which is no use to
/// somebody who has just lost three seasons of sightings.
///
/// This is the answer that needs no server: get the data out, in a form a
/// person can email to themselves, and put it back on the other side.
///
/// See docs/RISKS.md — this is the highest-value thing on that list.
class Backup {
  const Backup({
    required this.exportedAt,
    required this.profile,
    required this.spotted,
    required this.visits,
  });

  factory Backup.fromJson(Map<String, dynamic> json) => Backup(
    exportedAt: DateTime.parse(json['at'] as String),
    profile: json['profile'] == null
        ? null
        : TrackerProfile.fromJson(json['profile'] as Map<String, dynamic>),
    spotted: <String>{
      for (final dynamic id in json['spotted'] as List<dynamic>) id as String,
    },
    visits: <Visit>[
      for (final dynamic v in json['visits'] as List<dynamic>)
        Visit.fromJson(v as Map<String, dynamic>),
    ],
  );

  /// Bumped when the shape changes. [decode] refuses anything newer than it
  /// understands rather than guessing, because a half-read backup is worse than
  /// a refused one.
  static const int formatVersion = 1;

  /// Marks the payload so a stray paste fails loudly instead of throwing a
  /// base64 error at somebody who has just lost their phone.
  static const String prefix = 'WILDSCORE';

  final DateTime exportedAt;
  final TrackerProfile? profile;
  final Set<String> spotted;
  final List<Visit> visits;

  int get lifetimePoints =>
      visits.fold(0, (int sum, Visit v) => sum + v.ownerPoints);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'v': formatVersion,
    'at': exportedAt.toIso8601String(),
    if (profile != null) 'profile': profile!.toJson(),
    'spotted': spotted.toList()..sort(),
    'visits': <Map<String, dynamic>>[for (final Visit v in visits) v.toJson()],
  };

  /// A single line of text, safe to paste into an email or a message.
  ///
  /// Base64 rather than raw JSON for one practical reason: mail clients and
  /// chat apps reflow, wrap and "helpfully" convert quotes in plain text, and
  /// any one of those corrupts JSON silently. Base64 survives all of it.
  String encode() =>
      '$prefix$formatVersion:${base64Url.encode(utf8.encode(json.encode(toJson())))}';

  /// Reads a pasted code. Throws [BackupFormatException] with something a
  /// person can act on, never a raw decoder error.
  static Backup decode(String raw) {
    final String code = raw.trim().replaceAll(RegExp(r'\s'), '');
    if (code.isEmpty) {
      throw const BackupFormatException('Paste your backup code first.');
    }
    if (!code.startsWith(prefix)) {
      throw const BackupFormatException(
        'That does not look like a Wild Score backup. It should start with '
        '"$prefix".',
      );
    }
    final int colon = code.indexOf(':');
    if (colon < 0) {
      throw const BackupFormatException('That backup code looks incomplete.');
    }
    final int? version = int.tryParse(code.substring(prefix.length, colon));
    if (version == null) {
      throw const BackupFormatException('That backup code looks incomplete.');
    }
    if (version > formatVersion) {
      throw const BackupFormatException(
        'That backup was made by a newer version of Wild Score. Update the '
        'app and try again.',
      );
    }
    try {
      final String decoded = utf8.decode(
        base64Url.decode(code.substring(colon + 1)),
      );
      return Backup.fromJson(json.decode(decoded) as Map<String, dynamic>);
    } on Object {
      throw const BackupFormatException(
        'That backup code is damaged — it may have been cut short when it was '
        'copied. Try copying the whole thing again.',
      );
    }
  }

  /// Combines a backup with what is already on this phone.
  ///
  /// **Union, never replace.** Restoring must not be able to delete a sighting,
  /// so anything either side knows about survives. Visits are matched on when
  /// they ended, which is unique per drive in practice.
  ///
  /// The local profile wins when there is one: the name and avatar on the phone
  /// in your hand are the ones you chose most recently.
  Backup mergedInto({
    required TrackerProfile? localProfile,
    required Set<String> localSpotted,
    required List<Visit> localVisits,
  }) {
    final Map<DateTime, Visit> byEnd = <DateTime, Visit>{
      for (final Visit v in visits) v.endedAt: v,
      for (final Visit v in localVisits) v.endedAt: v,
    };
    final List<Visit> merged = byEnd.values.toList()
      ..sort((Visit a, Visit b) => b.endedAt.compareTo(a.endedAt));

    return Backup(
      exportedAt: DateTime.now(),
      profile: localProfile ?? profile,
      spotted: <String>{...localSpotted, ...spotted},
      visits: merged,
    );
  }
}

/// A pasted code that could not be read, carrying a message worth showing.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}
