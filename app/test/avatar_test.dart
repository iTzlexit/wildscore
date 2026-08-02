import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/domain/avatar_seed.dart';
import 'package:wildscore/shared/widgets/avatar_badge.dart';

void main() {
  test('the artwork set matches the count the maths deals from', () {
    // If these drift, guests stop getting distinct faces and nothing visibly
    // breaks — which is exactly the kind of bug that survives to production.
    expect(WildAvatar.all.length, AvatarSeed.count);
  });

  group('the account holder', () {
    test('always gets the same face for the same name', () {
      expect(AvatarSeed.forName('Alex'), AvatarSeed.forName('Alex'));
    });

    test('is not thrown off by case or stray spaces', () {
      expect(AvatarSeed.forName('  alex '), AvatarSeed.forName('Alex'));
    });

    test('lands inside the set', () {
      for (final String name in <String>['A', 'Zanele', 'Jean-Pierre', '']) {
        expect(
          AvatarSeed.forName(name),
          inInclusiveRange(0, AvatarSeed.count - 1),
        );
      }
    });
  });

  group('dealing guests', () {
    test('gives everyone in the car a different face', () {
      final List<int> dealt = AvatarSeed.deal(6, 12345);

      expect(dealt.length, 6);
      expect(dealt.toSet().length, 6, reason: 'no two players share a face');
    });

    test('is stable for a seed, so a reloaded game looks the same', () {
      expect(AvatarSeed.deal(4, 99), AvatarSeed.deal(4, 99));
    });

    test('varies between games', () {
      expect(AvatarSeed.deal(4, 1), isNot(AvatarSeed.deal(4, 2)));
    });

    test('never deals a face already taken by the account holder', () {
      final List<int> dealt = AvatarSeed.deal(5, 77, taken: <int>{3});

      expect(dealt, isNot(contains(3)));
    });

    test('survives a car with more people than there are faces', () {
      final List<int> dealt = AvatarSeed.deal(AvatarSeed.count + 3, 5);

      expect(dealt.length, AvatarSeed.count + 3);
    });

    test('a zero seed does not collapse the shuffle', () {
      expect(AvatarSeed.deal(3, 0).toSet().length, 3);
    });
  });

  test('WildAvatar.at wraps rather than throwing on a stale index', () {
    // Saved profiles outlive the artwork set. An index from a build with more
    // avatars must not crash the app on launch.
    expect(WildAvatar.at(AvatarSeed.count + 1), isA<WildAvatar>());
    expect(WildAvatar.at(-4), isA<WildAvatar>());
  });
}
