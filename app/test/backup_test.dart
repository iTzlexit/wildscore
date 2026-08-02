import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/backup.dart';
import 'package:wildscore/domain/scorecard.dart';
import 'package:wildscore/domain/tracker_profile.dart';
import 'package:wildscore/domain/visit.dart';

/// The one feature whose failure is unrecoverable. A restore that loses a
/// sighting is worse than no restore at all, so the merge is tested harder than
/// the encoding.
Visit _visit(DateTime ended, {String species = 'leopard', int points = 100}) {
  final Scorecard card = Scorecard.start(
    <String>['Alex'],
    owner: 'Alex',
    now: ended,
  );
  return Visit(
    startedAt: ended,
    endedAt: ended,
    players: card.players,
    claims: <Claim>[
      Claim(
        speciesId: species,
        playerId: card.players.first.id,
        at: ended,
        points: points,
      ),
    ],
  );
}

Backup _backup({
  Set<String> spotted = const <String>{'leopard'},
  List<Visit> visits = const <Visit>[],
  String name = 'Alex',
}) => Backup(
  exportedAt: DateTime(2026, 8, 2, 18),
  profile: TrackerProfile.create(name, now: DateTime(2026, 7, 1)),
  spotted: spotted,
  visits: visits,
);

void main() {
  group('the code', () {
    test('survives a round trip', () {
      final Backup original = _backup(
        spotted: <String>{'leopard', 'ground-pangolin'},
        visits: <Visit>[_visit(DateTime(2026, 8, 1, 18))],
      );

      final Backup restored = Backup.decode(original.encode());

      expect(restored.spotted, original.spotted);
      expect(restored.visits.length, 1);
      expect(restored.visits.single.ownerPoints, 100);
      expect(restored.profile?.name, 'Alex');
      expect(restored.exportedAt, original.exportedAt);
    });

    test('survives whitespace, which email clients add', () {
      // A pasted code arrives wrapped across lines more often than not.
      final Backup original = _backup();
      final String mangled = original
          .encode()
          .replaceRange(20, 20, '\n  ')
          .replaceRange(40, 40, ' \n');

      expect(Backup.decode(mangled).spotted, original.spotted);
    });

    test('an empty paste says so', () {
      expect(
        () => Backup.decode('   '),
        throwsA(
          isA<BackupFormatException>().having(
            (BackupFormatException e) => e.message,
            'message',
            contains('Paste your backup code'),
          ),
        ),
      );
    });

    test('something that is not a backup says so', () {
      expect(
        () => Backup.decode('hello granny how are you'),
        throwsA(
          isA<BackupFormatException>().having(
            (BackupFormatException e) => e.message,
            'message',
            contains('does not look like'),
          ),
        ),
      );
    });

    test('a truncated code says it was cut short', () {
      final String code = _backup().encode();

      expect(
        () => Backup.decode(code.substring(0, code.length - 30)),
        throwsA(
          isA<BackupFormatException>().having(
            (BackupFormatException e) => e.message,
            'message',
            contains('damaged'),
          ),
        ),
      );
    });

    test('a newer format is refused rather than guessed at', () {
      expect(
        () => Backup.decode('WILDSCORE99:abcdef'),
        throwsA(
          isA<BackupFormatException>().having(
            (BackupFormatException e) => e.message,
            'message',
            contains('newer version'),
          ),
        ),
      );
    });
  });

  group('merging into a phone', () {
    test('unions the collection rather than replacing it', () {
      // The phone has something the backup does not. Losing it would be the
      // exact disaster this feature exists to prevent.
      final Backup incoming = _backup(spotted: <String>{'leopard', 'lion'});

      final Backup merged = incoming.mergedInto(
        localProfile: null,
        localSpotted: <String>{'cheetah'},
        localVisits: const <Visit>[],
      );

      expect(merged.spotted, <String>{'leopard', 'lion', 'cheetah'});
    });

    test('keeps drives from both sides, newest first', () {
      final Backup incoming = _backup(
        visits: <Visit>[_visit(DateTime(2026, 7, 1, 18))],
      );

      final Backup merged = incoming.mergedInto(
        localProfile: null,
        localSpotted: const <String>{},
        localVisits: <Visit>[_visit(DateTime(2026, 8, 1, 18))],
      );

      expect(merged.visits.length, 2);
      expect(merged.visits.first.endedAt, DateTime(2026, 8, 1, 18));
    });

    test('does not duplicate a drive present on both sides', () {
      final Visit shared = _visit(DateTime(2026, 8, 1, 18));

      final Backup merged = _backup(visits: <Visit>[shared]).mergedInto(
        localProfile: null,
        localSpotted: const <String>{},
        localVisits: <Visit>[shared],
      );

      expect(merged.visits.length, 1);
    });

    test('the phone in your hand keeps its own name', () {
      final Backup merged = _backup(name: 'Old Name').mergedInto(
        localProfile: TrackerProfile.create('Alex'),
        localSpotted: const <String>{},
        localVisits: const <Visit>[],
      );

      expect(merged.profile?.name, 'Alex');
    });

    test('a fresh phone takes the name from the backup', () {
      final Backup merged = _backup(name: 'Alex').mergedInto(
        localProfile: null,
        localSpotted: const <String>{},
        localVisits: const <Visit>[],
      );

      expect(merged.profile?.name, 'Alex');
    });
  });

  test('reports what is in it, for the screen', () {
    final Backup backup = _backup(
      visits: <Visit>[
        _visit(DateTime(2026, 8, 1, 18)),
        _visit(DateTime(2026, 7, 1, 18), species: 'cheetah', points: 250),
      ],
    );

    expect(backup.lifetimePoints, 350);
  });
}
