import 'package:flutter/material.dart';

import '../theme.dart';

/// A cute animal face, on a tinted disc.
///
/// Emoji rather than drawn artwork on purpose. It is zero bytes of assets, it
/// is legible at 24pt, and every platform already ships a colour emoji font —
/// which matters because this app must work with no signal for days. The
/// animals are all Kruger residents, so the avatars are of a piece with the
/// rest of the product rather than a generic set of faces.
///
/// Identity is an **index**, not a picture. That is what gets stored, so the
/// artwork can be replaced later without touching a single saved profile.
class WildAvatar {
  const WildAvatar({
    required this.emoji,
    required this.tint,
    required this.name,
  });

  final String emoji;
  final Color tint;
  final String name;

  /// Kept at a prime-ish length so `seed % count` spreads names evenly.
  static const List<WildAvatar> all = <WildAvatar>[
    WildAvatar(emoji: '🦁', tint: Color(0xFFC98A15), name: 'Lion'),
    WildAvatar(emoji: '🐘', tint: Color(0xFF6E7B84), name: 'Elephant'),
    WildAvatar(emoji: '🦏', tint: Color(0xFF7A7F72), name: 'Rhino'),
    WildAvatar(emoji: '🐆', tint: Color(0xFFB8860B), name: 'Leopard'),
    WildAvatar(emoji: '🦒', tint: Color(0xFFC26A15), name: 'Giraffe'),
    WildAvatar(emoji: '🦓', tint: Color(0xFF4A5560), name: 'Zebra'),
    WildAvatar(emoji: '🦛', tint: Color(0xFF8C6E82), name: 'Hippo'),
    WildAvatar(emoji: '🐊', tint: Color(0xFF4E7A3F), name: 'Crocodile'),
    WildAvatar(emoji: '🦅', tint: Color(0xFF8B5E34), name: 'Eagle'),
    WildAvatar(emoji: '🐗', tint: Color(0xFF87664B), name: 'Warthog'),
    WildAvatar(emoji: '🦌', tint: Color(0xFFA8763E), name: 'Impala'),
    WildAvatar(emoji: '🐒', tint: Color(0xFF6E8C1F), name: 'Vervet'),
    WildAvatar(emoji: '🦩', tint: Color(0xFFC0567A), name: 'Flamingo'),
    WildAvatar(emoji: '🐢', tint: Color(0xFF2E8B57), name: 'Tortoise'),
    WildAvatar(emoji: '🦎', tint: Color(0xFF2372A8), name: 'Monitor'),
    WildAvatar(emoji: '🐍', tint: Color(0xFF6B47C0), name: 'Mamba'),
    WildAvatar(emoji: '🦇', tint: Color(0xFF5C5470), name: 'Bat'),
    WildAvatar(emoji: '🦉', tint: Color(0xFF8A6B3E), name: 'Owl'),
    WildAvatar(emoji: '🦔', tint: Color(0xFF9C6B10), name: 'Porcupine'),
  ];

  static int get count => all.length;

  static WildAvatar at(int index) => all[index.abs() % count];
}

/// The avatar as drawn. [size] is the diameter.
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    required this.avatar,
    this.size = 40,
    this.ring = false,
    super.key,
  });

  final int avatar;
  final double size;

  /// A ring marks "this one is you". Only ever one per screen.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final WildAvatar face = WildAvatar.at(avatar);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: face.tint.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: ring
            ? Border.all(color: AppColors.accent, width: 2)
            : Border.all(color: face.tint.withValues(alpha: 0.35)),
      ),
      child: Text(
        face.emoji,
        // Emoji have generous internal leading; without a tight height they sit
        // low in the disc.
        style: TextStyle(fontSize: size * 0.5, height: 1.15),
      ),
    );
  }
}
