import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/rarity_tier.dart';
import '../../shared/emphasis.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/avatar_badge.dart';

/// Three slides that explain the game before anyone is asked for anything.
///
/// The app used to open on a wall of prose. It was accurate and nobody read it,
/// which is the worst outcome a first screen can have: a family at Numbi gate
/// with the engine running does not read paragraphs. Three pictures with one
/// idea each survives that moment.
///
/// **Everything is drawn, not photographed.** Cartoon stock art of a family in
/// a car is either licensed per-use or is somebody's actual family, and this
/// app is offline-first with a hard rule about bundled licences. Painted scenes
/// cost no bytes, no attribution and no risk — and they match the emoji avatars
/// the rest of the app already uses.
///
/// The rarity table on slide two is generated from [RarityTier] rather than
/// typed out, so a tier revalued next season cannot leave the sales pitch
/// saying something the game no longer does.
class IntroTour extends StatefulWidget {
  const IntroTour({
    required this.onDone,
    this.doneLabel = 'Let\'s go',
    super.key,
  });

  /// Called by Skip and by the button on the last slide alike. What happens
  /// next is the caller's business — first run continues to naming, a later
  /// viewing just closes.
  final VoidCallback onDone;

  final String doneLabel;

  /// Opens the tour on its own, for somebody who skipped it or wants a reminder.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: IntroTour(
              doneLabel: 'Done',
              onDone: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<IntroTour> createState() => _IntroTourState();
}

class _IntroTourState extends State<IntroTour> {
  final PageController _controller = PageController();
  int _page = 0;

  static const int _count = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _count - 1) {
      widget.onDone();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool last = _page == _count - 1;

    return Column(
      children: <Widget>[
        // Skip sits at the top where it is findable and easy to ignore. Hiding
        // it would win a few completed tours and cost the goodwill of everybody
        // who has seen it before.
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, Space.sm, Space.sm, 0),
            // A fixed height so the slides do not shift up when Skip goes on
            // the last one. An empty label would have left an invisible button
            // in the corner, which is worse than no button.
            child: SizedBox(
              height: 40,
              child: last
                  ? null
                  : TextButton(
                      onPressed: widget.onDone,
                      child: Text(
                        'Skip',
                        style: AppText.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (int i) => setState(() => _page = i),
            children: const <Widget>[_SlideOne(), _SlideTwo(), _SlideThree()],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, Space.lg, 28, Space.xl),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < _count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.accent
                            : AppColors.outlineStrong,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Space.lg),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                    ),
                  ),
                  child: Text(
                    last ? widget.doneLabel : 'Next',
                    style: AppText.bodyStrong.copyWith(
                      color: AppColors.accentInk,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shared frame: art on top, words below, and it scrolls when a short screen or
/// a large text scale demands it rather than overflowing.
class _Slide extends StatelessWidget {
  const _Slide({
    required this.art,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.extra,
  });

  final Widget art;
  final String eyebrow;
  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  // Full width so the painted scenes have a canvas and the
                  // centred ones actually centre — the column aligns to the
                  // start, which a bare SizedBox would inherit.
                  width: double.infinity,
                  height: (constraints.maxHeight * 0.34).clamp(150.0, 230.0),
                  child: art,
                ),
                const SizedBox(height: Space.xl),
                // An empty eyebrow costs its own line and its margin, which on
                // a 360-wide phone is a slide's worth of breathing room.
                if (eyebrow.isNotEmpty) ...<Widget>[
                  Text(
                    eyebrow,
                    style: AppText.label.copyWith(color: AppColors.accent),
                  ),
                  const SizedBox(height: Space.sm),
                ],
                Text(
                  title,
                  style: AppText.title1.copyWith(fontSize: 27, height: 1.15),
                ),
                // A slide whose content *is* the numbered steps has nothing to
                // say in prose first, and an empty paragraph still costs its
                // margins.
                if (body.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Space.md),
                  Text.rich(
                    TextSpan(
                      children: emphasisSpans(
                        body,
                        AppText.body.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
                if (extra != null) ...<Widget>[
                  SizedBox(height: body.isEmpty ? Space.lg : Space.xl),
                  extra!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- slide one

class _SlideOne extends StatelessWidget {
  const _SlideOne();

  @override
  Widget build(BuildContext context) {
    return const _Slide(
      art: _CarScene(),
      eyebrow: 'WILD SCORE: KRUGER EDITION',
      // Opened on the problem — "six hours of driving, and nothing to show for
      // it" — which is a real technique and was the wrong one here. Somebody
      // reads this at a gate at six in the morning, already excited, and being
      // told their last holiday was a disappointment is a strange greeting.
      // The owner's version asks a question instead, and the question is the
      // whole game.
      title:
          'Do you have what it takes to be crowned the Ultimate '
          'Kruger Spotter?',
      body:
          'Every animal has a score based on how rare it is to spot, so every '
          'drive counts from start to finish.\n\n'
          'Compete with everyone in your vehicle and see who ends the day as '
          'the Ultimate Kruger Spotter.',
      extra: _Promises(),
    );
  }
}

/// The three things people want to know before they will try anything.
///
/// Kept on the first slide, where somebody is still deciding, rather than in a
/// settings screen they reach a week later.
class _Promises extends StatelessWidget {
  const _Promises();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: <Widget>[
        for (final String promise in const <String>[
          'No account',
          'No ads',
          'No signal needed',
        ])
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            // A chip cannot be wider than the column it sits in. At a large
            // text scale one of these grows past the screen otherwise.
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: AppColors.accentWash,
              borderRadius: BorderRadius.circular(Radii.chip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    promise,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      color: AppColors.accent,
                      fontVariations: AppFonts.weight(700),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A game-drive vehicle on a dirt road: people inside looking out, animals
/// outside with their points floating over them.
///
/// The vehicle used to be full of animal faces, which was a charming picture of
/// the wrong thing — the animals are what you are looking *for*. Putting people
/// with binoculars in the seats and the quarry in the bush says what the app is
/// in one image, and the point badges say what the game is without a word of
/// copy: somebody who reads "🐆 300" and "🦌 5" has already understood it.
class _CarScene extends StatelessWidget {
  const _CarScene();

  /// The people. Emoji rather than drawn faces, for the same reason the
  /// avatars are: colour emoji ship with every platform, cost no bytes and no
  /// licence, and read at 30pt.
  ///
  /// **Smiling faces, and nothing held up to them.** They used to be neutral
  /// figures behind a telescope emoji, which covered the one part of a
  /// passenger that carries any feeling. A car of faces with binoculars over
  /// them is a picture of equipment; a car of grinning faces is a picture of
  /// the holiday.
  static const List<String> _passengers = <String>['😀', '😄', '🙂', '😁'];

  /// What they are looking at, and what it pays. The points are the joke and
  /// the explanation at once — a first-time viewer reads "🐆 300" and has
  /// understood the entire game before reading a word of the copy.
  ///
  /// **All three stand on the ground, off the road, clear of the vehicle.**
  /// The rhino used to float at 0.20 of the height, which is above the roof
  /// line: it read as a two-tonne animal standing on the canopy. Wrong in a
  /// game park and wrong in a game — the whole idea is that the animals are
  /// out there and you are in here.
  ///
  /// The vehicle occupies x 0.20–0.80 and y 0.42–0.72, and the road runs from
  /// y 0.72 down. These sit outside both.
  static const List<(String, String, double, double)> _quarry =
      <(String, String, double, double)>[
        ('🐆', '300', 0.085, 0.72),
        ('🦏', '2000', 0.905, 0.60),
        ('🦌', '5', 0.86, 0.86),
      ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        final double face = (w * 0.10).clamp(24.0, 38.0);
        final double beast = (w * 0.11).clamp(26.0, 44.0);

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(size: Size(w, h), painter: _CarPainter()),

            // Animals first, so the vehicle paints over anything that strays
            // behind it.
            for (final (String emoji, String points, double x, double y)
                in _quarry)
              Positioned(
                left: w * x - beast / 2,
                top: h * y - beast / 2,
                child: _Quarry(emoji: emoji, points: points, size: beast),
              ),

            // People in the seats, looking out. The vehicle used to be full of
            // animals, which was a nice picture of the wrong thing: the
            // animals are what you are looking *for*.
            for (int i = 0; i < _passengers.length; i++)
              Positioned(
                left: w * (0.245 + i * 0.125) - face / 2,
                top: h * 0.565 - face / 2,
                child: _Passenger(emoji: _passengers[i], size: face),
              ),
          ],
        );
      },
    );
  }
}

/// One passenger, face uncovered.
///
/// This was a face with a telescope emoji stacked over its lower half. It read
/// as a prop rather than a person and it hid the expression, which on a slide
/// selling a family game is the only thing the figure is there to do.
class _Passenger extends StatelessWidget {
  const _Passenger({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.15,
      child: Align(
        alignment: Alignment.topCenter,
        child: Text(emoji, style: TextStyle(fontSize: size * 0.86)),
      ),
    );
  }
}

/// An animal out in the bush with its points floating over it.
class _Quarry extends StatelessWidget {
  const _Quarry({
    required this.emoji,
    required this.points,
    required this.size,
  });

  final String emoji;
  final String points;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: size * 0.16,
            vertical: size * 0.05,
          ),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(size),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            points,
            style: AppText.label.copyWith(
              color: AppColors.accentInk,
              fontSize: size * 0.26,
              fontFeatures: AppText.tabular,
            ),
          ),
        ),
        SizedBox(height: size * 0.08),
        Text(emoji, style: TextStyle(fontSize: size * 0.82)),
      ],
    );
  }
}

class _CarPainter extends CustomPainter {
  static const Color _sun = Color(0xFFF2C15C);
  static const Color _bush = Color(0xFFBFC9B4);
  static const Color _bushFar = Color(0xFFD6DCCD);
  static const Color _road = Color(0xFFDCD2C0);
  static const Color _body = Color(0xFF6B7A5A);
  static const Color _bodyDark = Color(0xFF4E5B41);
  static const Color _tyre = Color(0xFF3A3F38);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint p = Paint()..isAntiAlias = true;

    // Sun, low and behind everything.
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.26),
      h * 0.17,
      p..color = _sun.withValues(alpha: 0.35),
    );
    canvas.drawCircle(Offset(w * 0.78, h * 0.26), h * 0.11, p..color = _sun);

    // Two rows of hills, far one paler, so the scene has depth without detail.
    void hills(double top, double amp, Color colour) {
      final Path path = Path()..moveTo(0, h);
      for (double x = 0; x <= w; x += w / 24) {
        path.lineTo(x, top + math.sin(x / w * math.pi * 2.4) * amp);
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, p..color = colour);
    }

    hills(h * 0.56, h * 0.045, _bushFar);
    hills(h * 0.66, h * 0.03, _bush);

    // An acacia, because nothing else says Lowveld in four strokes.
    _acacia(canvas, p, Offset(w * 0.09, h * 0.66), h * 0.30);

    // The road, wider at the front so it reads as running towards you.
    final Path road = Path()
      ..moveTo(w * 0.18, h * 0.72)
      ..lineTo(w * 0.82, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(road, p..color = _road);

    // ------------------------------------------------------------- vehicle
    final double cx = w * 0.5;
    final double roof = h * 0.42;
    final double deck = h * 0.70;
    final double left = cx - w * 0.30;
    final double right = cx + w * 0.30;

    // Roof canopy and its four posts. Open-sided, like every game viewer.
    canvas.drawRRect(
      RRect.fromLTRBR(
        left - 6,
        roof - 9,
        right + 6,
        roof,
        const Radius.circular(4),
      ),
      p..color = _bodyDark,
    );
    for (final double t in <double>[0.04, 0.36, 0.66, 0.96]) {
      final double x = left + (right - left) * t;
      canvas.drawRect(
        Rect.fromLTWH(x - 2, roof, 4, deck - roof),
        p..color = _bodyDark,
      );
    }

    // Body, with a lighter bonnet stepping down at the front.
    canvas.drawRRect(
      RRect.fromLTRBR(
        left,
        deck - h * 0.10,
        right,
        deck,
        const Radius.circular(7),
      ),
      p..color = _body,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        right - w * 0.03,
        deck - h * 0.145,
        right + w * 0.09,
        deck,
        const Radius.circular(7),
      ),
      p..color = _body,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(
        right + w * 0.005,
        deck - h * 0.135,
        right + w * 0.075,
        deck - h * 0.085,
        const Radius.circular(3),
      ),
      p..color = const Color(0xFFCFE0E6),
    );

    // Wheels.
    for (final double x in <double>[left + w * 0.09, right + w * 0.035]) {
      canvas.drawCircle(Offset(x, deck), h * 0.075, p..color = _tyre);
      canvas.drawCircle(Offset(x, deck), h * 0.032, p..color = _bushFar);
    }

    // Dust behind the back wheel. Three fading puffs is plenty of motion.
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(left - w * 0.02 - i * w * 0.045, deck - i * h * 0.02),
        h * (0.035 + i * 0.012),
        p..color = _road.withValues(alpha: 0.55 - i * 0.15),
      );
    }
  }

  void _acacia(Canvas canvas, Paint p, Offset base, double height) {
    const Color bark = Color(0xFF8A7B62);
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 2.5, base.dy - height * 0.55, 5, height * 0.55),
      p..color = bark,
    );
    // The flat top. An acacia is a line and a wedge, and anything more detailed
    // at this size turns into a smudge.
    final Path canopy = Path()
      ..moveTo(base.dx - height * 0.42, base.dy - height * 0.52)
      ..quadraticBezierTo(
        base.dx,
        base.dy - height * 0.86,
        base.dx + height * 0.42,
        base.dy - height * 0.52,
      )
      ..quadraticBezierTo(
        base.dx,
        base.dy - height * 0.42,
        base.dx - height * 0.42,
        base.dy - height * 0.52,
      )
      ..close();
    canvas.drawPath(canopy, p..color = const Color(0xFF7E9068));
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) => false;
}

// ---------------------------------------------------------------- slide two

class _SlideTwo extends StatelessWidget {
  const _SlideTwo();

  @override
  Widget build(BuildContext context) {
    return const _Slide(
      art: _ScoringScene(),
      // No eyebrow. It read "THEN PLAY WILD SCORE", which is the third time in
      // three screens the app has said its own name.
      eyebrow: '',
      title: 'How it works',
      body: '',
      extra: _HowItWorks(),
    );
  }
}

/// A working-looking standings row. Not a screenshot — a screenshot goes stale
/// the week the layout changes, and this is built from the same tokens the real
/// board uses.
class _ScoringScene extends StatelessWidget {
  const _ScoringScene();

  @override
  Widget build(BuildContext context) {
    // This is a picture of the app, not text to be read, so it scales as a
    // whole rather than reflowing. Left to its own devices it grows past its
    // box at a large accessibility text scale and takes the slide with it.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: MediaQuery.withNoTextScaling(
        child: Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: AppColors.outline),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _MockRow(avatar: 3, name: 'Alex', points: 415, fraction: 1),
              SizedBox(height: Space.md),
              _MockRow(avatar: 9, name: 'Dad', points: 260, fraction: 0.63),
              SizedBox(height: Space.md),
              _MockRow(avatar: 14, name: 'Sarah', points: 95, fraction: 0.23),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockRow extends StatelessWidget {
  const _MockRow({
    required this.avatar,
    required this.name,
    required this.points,
    required this.fraction,
  });

  final int avatar;
  final String name;
  final int points;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final bool leading = fraction == 1;

    return Row(
      children: <Widget>[
        AvatarBadge(avatar: avatar, size: 26),
        const SizedBox(width: Space.sm),
        SizedBox(
          width: 58,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyStrong.copyWith(fontSize: 13),
          ),
        ),
        SizedBox(
          width: 62,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(
                leading ? AppColors.accent : AppColors.outlineStrong,
              ),
            ),
          ),
        ),
        const SizedBox(width: Space.sm),
        SizedBox(
          width: 34,
          child: Text(
            '$points',
            textAlign: TextAlign.right,
            style: AppText.title3.copyWith(
              fontSize: 14,
              color: leading ? AppColors.accent : AppColors.textPrimary,
              fontFeatures: AppText.tabular,
            ),
          ),
        ),
        const SizedBox(width: Space.sm),
        // The button the sentence above is talking about, drawn exactly as it
        // appears on the real board.
        Container(
          width: 28,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accentWash,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          ),
          child: const Icon(
            Icons.visibility_rounded,
            size: 15,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

/// The three things that happen, then what the animals are worth.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _NumberedStep(n: '1', text: 'Start the drive.'),
        _NumberedStep(n: '2', text: 'Enter everyone playing.'),
        _NumberedStep(
          n: '3',
          text:
              'Somebody spots an animal first — tap the eye beside their '
              'name and choose it. The points land on them.',
          last: true,
        ),
        SizedBox(height: Space.md),
        _RarityTable(),
      ],
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.n, required this.text, this.last = false});

  final String n;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              style: AppText.label.copyWith(
                color: AppColors.accentInk,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: AppText.body.copyWith(fontSize: 14.5, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every tier and what it pays, straight from the enum.
class _RarityTable extends StatelessWidget {
  const _RarityTable();

  /// One animal everybody recognises per tier, so the numbers mean something.
  static const Map<RarityTier, String> _examples = <RarityTier, String>{
    RarityTier.common: 'Impala, zebra',
    RarityTier.frequent: 'Elephant, giraffe',
    RarityTier.uncommon: 'Lion, rhino',
    RarityTier.scarce: 'Honey badger',
    RarityTier.rare: 'Cheetah, wild dog',
    RarityTier.legendary: 'Pangolin, caracal',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        children: <Widget>[
          for (final RarityTier tier in RarityTier.values)
            Padding(
              padding: EdgeInsets.only(
                bottom: tier == RarityTier.values.last ? 0 : Space.sm,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tier.style.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  SizedBox(
                    width: 74,
                    child: Text(
                      tier.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: tier.style.accent,
                        fontVariations: AppFonts.weight(700),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _examples[tier] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '${tier.points}',
                    style: AppText.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontVariations: AppFonts.weight(800),
                      fontFeatures: AppText.tabular,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- slide three

class _SlideThree extends StatelessWidget {
  const _SlideThree();

  @override
  Widget build(BuildContext context) {
    return const _Slide(
      art: _VictoryScene(),
      eyebrow: 'BACK AT CAMP',
      title: 'Crown today’s Ultimate Spotter',
      body:
          'Tap **End Day** to total the scores, crown the winner, and save '
          'your adventure to your history.\n\n'
          'Tomorrow is a brand-new game.',
      extra: _AfterwardsList(),
    );
  }
}

/// A rosette. Cheap to draw, instantly legible, and it does not pretend to be
/// a trophy the app can post to anybody.
class _VictoryScene extends StatelessWidget {
  const _VictoryScene();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double h = constraints.maxHeight;
        // The rays and ribbons are drawn as multiples of the medal's own
        // radius, so the two have to agree on it. Sized off the box height so
        // the whole device stays inside its slot — the first version ran its
        // ribbons over the heading below.
        final double disc = (h * 0.40).clamp(64.0, 100.0);

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              size: Size(constraints.maxWidth, h),
              painter: _RosettePainter(radius: disc / 2),
            ),
            Container(
              width: disc,
              height: disc,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF2C15C),
                shape: BoxShape.circle,
              ),
              child: Container(
                width: disc * 0.82,
                height: disc * 0.82,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8B347),
                  shape: BoxShape.circle,
                ),
                child: Text('🦁', style: TextStyle(fontSize: disc * 0.44)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RosettePainter extends CustomPainter {
  const _RosettePainter({required this.radius});

  /// The medal's radius. Everything else is a multiple of it, and nothing
  /// reaches beyond 2× — which is what keeps the device inside its box.
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double r = radius;
    final Paint p = Paint()..isAntiAlias = true;

    // Ribbons first, so the medal sits on top of where they join.
    for (final double dir in <double>[-1, 1]) {
      final Path ribbon = Path()
        ..moveTo(centre.dx + dir * r * 0.20, centre.dy + r * 0.60)
        ..lineTo(centre.dx + dir * r * 0.95, centre.dy + r * 1.90)
        ..lineTo(centre.dx + dir * r * 0.52, centre.dy + r * 1.72)
        ..lineTo(centre.dx + dir * r * 0.26, centre.dy + r * 1.98)
        ..close();
      canvas.drawPath(ribbon, p..color = const Color(0xFFC97B4A));
    }

    // Rays, alternating weight so it reads as a burst rather than a wheel.
    for (int i = 0; i < 16; i++) {
      final double angle = i * math.pi / 8;
      final double length = r * (i.isEven ? 1.85 : 1.55);
      p
        ..color = AppColors.accent.withValues(alpha: i.isEven ? 0.18 : 0.10)
        ..strokeWidth = i.isEven ? 7 : 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        centre + Offset(math.cos(angle), math.sin(angle)) * r * 1.20,
        centre + Offset(math.cos(angle), math.sin(angle)) * length,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RosettePainter oldDelegate) =>
      oldDelegate.radius != radius;
}

/// The reasons to still have the app in March. Deliberately last: nobody
/// installs a game for its history screen, but they keep it for one.
class _AfterwardsList extends StatelessWidget {
  const _AfterwardsList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        _Afterward(
          icon: Icons.place_rounded,
          title: 'Latest sightings',
          body: 'Every good find, and the road it happened on.',
        ),
        _Afterward(
          icon: Icons.history_rounded,
          title: 'Every drive you have done',
          body: 'Who won, what they got, going back years.',
        ),
        _Afterward(
          icon: Icons.menu_book_rounded,
          title: 'A collection that keeps',
          body: 'Everything the car saw joins your life list — for good.',
        ),
      ],
    );
  }
}

class _Afterward extends StatelessWidget {
  const _Afterward({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 17, color: AppColors.accent),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppText.bodyStrong.copyWith(fontSize: 13.5)),
                const SizedBox(height: 1),
                Text(
                  body,
                  style: AppText.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
