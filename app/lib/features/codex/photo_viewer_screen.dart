import 'package:flutter/material.dart';

import '../../domain/species.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/species_image.dart';

/// Full-screen species photograph, pinch to zoom.
///
/// Reached by tapping the hero image on the detail screen. Kept deliberately
/// bare — black background, no chrome except a close button and the credit,
/// because the photograph is the entire point of the screen.
class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({required this.species, this.credit, super.key});

  final Species species;

  /// Photographer and licence. Legally required for CC-BY images, so it is
  /// displayed here rather than tucked away in a settings screen.
  final String? credit;

  static Route<void> route(Species species, {String? credit}) {
    return PageRouteBuilder<void>(
      opaque: false,
      // Fully opaque. At 0xF2 the 5% of light leaking through was enough to
      // show the detail screen's text faintly behind the photograph.
      barrierColor: const Color(0xFF000000),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (BuildContext context, _, _) =>
          PhotoViewerScreen(species: species, credit: credit),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          // Tap anywhere off the photo to dismiss — the expected gesture in
          // every photo viewer anyone has used.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Center(
            child: Hero(
              tag: 'species-photo-${species.id}',
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: SpeciesImage(species: species, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: <Widget>[
                    _CircleButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        species.commonName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (credit != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  color: const Color(0x99000000),
                  child: Text(
                    credit!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x66000000),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
