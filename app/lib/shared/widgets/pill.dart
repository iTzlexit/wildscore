import 'package:flutter/material.dart';

/// A small capsule label. Used for rarity tiers, Big Five badges, IUCN codes —
/// anything that needs to read as a stamp rather than as prose.
class Pill extends StatelessWidget {
  const Pill({
    required this.label,
    required this.color,
    this.background,
    this.borderColor,
    this.icon,
    this.dense = false,
    super.key,
  });

  final String label;
  final Color color;
  final Color? background;
  final Color? borderColor;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final double fontSize = dense ? 9.5 : 11;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 9,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background ?? const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(dense ? 5 : 7),
        border: Border.all(color: borderColor ?? const Color(0x1FFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
