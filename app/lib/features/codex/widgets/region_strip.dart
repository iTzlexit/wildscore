import 'package:flutter/material.dart';

import '../../../domain/park_region.dart';
import '../../../shared/theme.dart';

/// Where in the park a species occurs, drawn as the park itself.
///
/// Kruger is long and narrow, so the strip runs vertically with north at the
/// top — the same orientation as every map in every rest camp. Knowing that
/// roan means "drive to Pafuri" is the difference between a field guide and a
/// list of animals.
class RegionStrip extends StatelessWidget {
  const RegionStrip({required this.regions, super.key});

  static const double _segmentHeight = 52;

  final List<ParkRegion> regions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Column(
            children: <Widget>[
              for (final ParkRegion region in ParkRegion.values)
                Container(
                  width: 8,
                  height: _segmentHeight,
                  color: regions.contains(region)
                      ? AppColors.accent
                      : const Color(0xFF232C27),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final ParkRegion region in ParkRegion.values)
                _RegionRow(region: region, present: regions.contains(region)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({required this.region, required this.present});

  final ParkRegion region;
  final bool present;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RegionStrip._segmentHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                region.label,
                style: TextStyle(
                  color: present ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 13.5,
                  fontWeight: present ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (present) ...<Widget>[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: AppColors.accent,
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            region.bounds,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: present
                  ? AppColors.textSecondary
                  : const Color(0xFF4B564F),
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
