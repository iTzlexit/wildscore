import 'visit.dart';

/// A run of drives that belong to the same visit to the park.
///
/// It used to carry `bonusesSpent`, which worked out whether a species had
/// already paid its first-sighting bonus this trip. That whole mechanic is
/// gone — see the note on [Species.scoreFor] — and with it the need to load a
/// fortnight of history before scoring one impala.
///
/// **Derived, never declared.** Making somebody press "Start trip" on top of
/// "Start drive" doubles the ceremony for a family at a gate, and they would
/// forget to end it — leaving a trip open for eight months. A trip is simply
/// consecutive drives, which is what a trip actually is.
abstract final class Trip {
  /// A rest day at camp with no drive is normal; a fortnight between drives is
  /// clearly a different holiday. Two days is the line, and it is one number
  /// to change if it ever feels wrong.
  static const Duration maxGap = Duration(days: 2);

  /// The drives belonging to the trip that [now] falls in, newest first.
  ///
  /// Walks back from the most recent drive while the gaps stay short. Returns
  /// empty when the last drive was long enough ago that today starts a new one.
  static List<Visit> current(List<Visit> visits, {DateTime? now}) {
    if (visits.isEmpty) {
      return const <Visit>[];
    }
    final DateTime today = now ?? DateTime.now();
    final List<Visit> sorted = <Visit>[...visits]
      ..sort((Visit a, Visit b) => b.endedAt.compareTo(a.endedAt));

    if (today.difference(sorted.first.endedAt) > maxGap) {
      return const <Visit>[];
    }

    final List<Visit> run = <Visit>[sorted.first];
    for (int i = 1; i < sorted.length; i++) {
      if (run.last.endedAt.difference(sorted[i].endedAt) > maxGap) {
        break;
      }
      run.add(sorted[i]);
    }
    return run;
  }
}
