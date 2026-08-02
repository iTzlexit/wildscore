import '../domain/backup.dart';
import '../domain/tracker_profile.dart';
import 'profile_repository.dart';
import 'spotted_repository.dart';
import 'visit_repository.dart';

/// Reads everything out, and merges everything back in.
///
/// Deliberately the only class that touches all four stores at once. Restoring
/// is the one operation that can destroy a person's record, so it exists in
/// exactly one place where the ordering can be read top to bottom.
class BackupRepository {
  const BackupRepository({
    this.profiles = const ProfileRepository(),
    this.spotted = const SpottedRepository(),
    this.visits = const VisitRepository(),
  });

  final ProfileRepository profiles;
  final SpottedRepository spotted;
  final VisitRepository visits;

  Future<Backup> read() async {
    return Backup(
      exportedAt: DateTime.now(),
      profile: await profiles.load(),
      spotted: await spotted.load(),
      visits: await visits.load(),
    );
  }

  /// Merges a decoded backup into this device and returns the result.
  ///
  /// Nothing is cleared first. A restore that wiped local state before writing
  /// would lose everything if the app died halfway, and the failure would look
  /// exactly like the disaster it was supposed to prevent.
  Future<Backup> restore(Backup incoming) async {
    final Backup merged = incoming.mergedInto(
      localProfile: await profiles.load(),
      localSpotted: await spotted.load(),
      localVisits: await visits.load(),
    );

    await spotted.save(merged.spotted);
    await visits.replaceAll(merged.visits);
    final TrackerProfile? profile = merged.profile;
    if (profile != null) {
      await profiles.save(profile);
    }
    return merged;
  }
}
