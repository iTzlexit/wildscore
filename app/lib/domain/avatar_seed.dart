/// Picking avatars. Pure arithmetic, no Flutter — the artwork lives in
/// shared/widgets/avatar_badge.dart and this only ever deals in indices.
///
/// Two different rules, deliberately:
///
/// * **The account holder's avatar never changes.** It is derived from their
///   name, so it survives a reinstall and it is how other people will recognise
///   them on the leaderboard later.
/// * **Guests get a fresh face every game.** They are not accounts, and a new
///   scorecard dealing new animals is part of the ritual of starting a day.
abstract final class AvatarSeed {
  /// Must match `WildAvatar.all.length`. Pinned by a test.
  static const int count = 19;

  static int forName(String name) {
    int hash = 7;
    for (final int unit in name.toLowerCase().trim().codeUnits) {
      hash = (hash * 31 + unit) & 0x3FFFFFFF;
    }
    return hash % count;
  }

  /// [players] distinct avatars, shuffled from [shuffleSeed].
  ///
  /// Deterministic: a scorecard reloaded from disk shows the same faces it did
  /// five minutes ago, because only the seed is stored.
  static List<int> deal(
    int players,
    int shuffleSeed, {
    Set<int> taken = const <int>{},
  }) {
    final List<int> pool = <int>[
      for (int i = 0; i < count; i++)
        if (!taken.contains(i)) i,
    ];
    if (pool.isEmpty) {
      return List<int>.filled(players, 0);
    }
    int state = shuffleSeed.abs() % 2147483647;
    if (state == 0) {
      state = 1;
    }
    for (int i = pool.length - 1; i > 0; i--) {
      state = (state * 48271) % 2147483647;
      final int j = state % (i + 1);
      final int temp = pool[i];
      pool[i] = pool[j];
      pool[j] = temp;
    }
    return <int>[for (int i = 0; i < players; i++) pool[i % pool.length]];
  }
}
