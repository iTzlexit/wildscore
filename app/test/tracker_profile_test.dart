import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/tracker_profile.dart';

void main() {
  group('name validation', () {
    test('accepts an ordinary name', () {
      expect(TrackerProfile.validateName('Alex'), isNull);
    });

    test('rejects empty and whitespace-only', () {
      expect(TrackerProfile.validateName(''), isNotNull);
      expect(TrackerProfile.validateName('    '), isNotNull);
    });

    test('rejects a single character', () {
      expect(TrackerProfile.validateName('A'), isNotNull);
    });

    test('rejects an over-long name', () {
      expect(TrackerProfile.validateName('A' * 21), isNotNull);
    });

    test('accepts exactly the maximum length', () {
      expect(TrackerProfile.validateName('A' * 20), isNull);
    });

    test('validates the sanitised form, not the raw input', () {
      // '  Al  ' collapses to 'Al', which is long enough.
      expect(TrackerProfile.validateName('  Al  '), isNull);
    });
  });

  group('sanitiseName', () {
    test('trims', () {
      expect(TrackerProfile.sanitiseName('  Alex  '), 'Alex');
    });

    test('collapses internal whitespace', () {
      // Names go on a public leaderboard; padding must not be a way to shout.
      expect(
        TrackerProfile.sanitiseName('Alex     van der Merwe'),
        'Alex van der Merwe',
      );
    });

    test('collapses tabs and newlines too', () {
      expect(TrackerProfile.sanitiseName('Alex\t\nB'), 'Alex B');
    });
  });

  group('TrackerProfile.create', () {
    test('stores the sanitised name and the current season', () {
      final TrackerProfile p = TrackerProfile.create(
        '  Alex  ',
        now: DateTime(2027, 7, 14),
      );

      expect(p.name, 'Alex');
      expect(p.seasonYear, 2027);
      expect(p.createdAt, DateTime(2027, 7, 14));
    });

    test('initial is the first letter, uppercased', () {
      expect(TrackerProfile.create('alex').initial, 'A');
    });
  });

  test('survives a JSON round trip', () {
    final TrackerProfile original = TrackerProfile.create(
      'Alex',
      now: DateTime(2026, 7, 26, 8, 30),
    );
    final TrackerProfile restored = TrackerProfile.fromJson(original.toJson());

    expect(restored.name, original.name);
    expect(restored.seasonYear, original.seasonYear);
    expect(restored.createdAt, original.createdAt);
  });
}
