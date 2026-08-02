import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/tracker_profile.dart';
import '../../shared/theme.dart';

/// First run: name yourself, and you are a tracker.
///
/// Three steps, no account, no email, no password. The whole point is that a
/// family in a car at the gate can be playing within twenty seconds. Anything
/// that asks for a password here loses half of them.
///
/// The third step is deliberately a small ceremony rather than a confirmation
/// dialog. It is the first rehearsal of the reveal moment that docs/VISION.md
/// says the whole product rests on — worth practising on something cheap.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onComplete, super.key});

  final ValueChanged<TrackerProfile> onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  int _step = 0;
  String? _nameError;
  TrackerProfile? _profile;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _submitName() {
    final String raw = _nameController.text;
    final String? error = TrackerProfile.validateName(raw);
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }
    _nameFocus.unfocus();
    setState(() {
      _nameError = null;
      _profile = TrackerProfile.create(raw);
    });
    _goTo(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          // Buttons only. A half-swipe that lands between steps makes the
          // opening of the app feel broken.
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            _WelcomeStep(onBegin: () => _goTo(1)),
            _NameStep(
              controller: _nameController,
              focusNode: _nameFocus,
              errorText: _nameError,
              onSubmit: _submitName,
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            if (_profile != null)
              _RevealStep(
                profile: _profile!,
                isVisible: _step == 2,
                onEnter: () => widget.onComplete(_profile!),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onBegin});

  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Spacer(),
          Row(
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'KRUGER NATIONAL PARK',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Wild Score',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 46,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.8,
              height: 1,
            ),
          ),
          const SizedBox(height: 24),
          const _PitchLine(
            icon: Icons.photo_camera_rounded,
            text: 'Photograph what you find, in the park, with the camera.',
          ),
          const _PitchLine(
            icon: Icons.auto_awesome_rounded,
            text:
                'Earn points for how hard it was to find. '
                'An impala is 5. A pangolin is 2500.',
          ),
          const _PitchLine(
            icon: Icons.inventory_2_rounded,
            text:
                'Keep a collection that lasts for years, '
                'not a scorecard you lose at the gate.',
          ),
          const Spacer(),
          _PrimaryButton(label: 'Begin', onPressed: onBegin),
          const SizedBox(height: 10),
          const Text(
            'No account. No email. Works offline.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PitchLine extends StatelessWidget {
  const _PitchLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.onSubmit,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final VoidCallback onSubmit;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Spacer(),
          const Text(
            'What should we\ncall you?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'This is the name other trackers will see on the leaderboard.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: TrackerProfile.maxNameLength,
            onChanged: onChanged,
            onSubmitted: (_) => onSubmit(),
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(TrackerProfile.maxNameLength),
            ],
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            decoration: nameFieldDecoration(errorText),
          ),
          const Spacer(),
          _PrimaryButton(label: 'Continue', onPressed: onSubmit),
        ],
      ),
    );
  }
}

/// The payoff. Scales and fades the tracker card in rather than simply
/// appearing — the first, cheapest version of the reveal.
class _RevealStep extends StatefulWidget {
  const _RevealStep({
    required this.profile,
    required this.isVisible,
    required this.onEnter,
  });

  final TrackerProfile profile;
  final bool isVisible;
  final VoidCallback onEnter;

  @override
  State<_RevealStep> createState() => _RevealStepState();
}

class _RevealStepState extends State<_RevealStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didUpdateWidget(_RevealStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward(from: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
      child: Column(
        children: <Widget>[
          const Spacer(),
          FadeTransition(
            opacity: _controller,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.82, end: 1).animate(curve),
              child: _TrackerCard(profile: widget.profile),
            ),
          ),
          const SizedBox(height: 26),
          FadeTransition(
            opacity: _controller,
            child: const Text(
              'Your collection starts empty.\nGo and find something.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(),
          _PrimaryButton(label: 'Enter the park', onPressed: widget.onEnter),
        ],
      ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({required this.profile});

  final TrackerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB08D2E), width: 1.6),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x3DE8C15A), blurRadius: 28, spreadRadius: -6),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0x26D9A441),
              shape: BoxShape.circle,
            ),
            child: Text(
              profile.initial,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'TRACKER',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.outline, height: 1),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const _Stat(value: '0', label: 'POINTS'),
              const _Stat(value: '0', label: 'SPECIES'),
              _Stat(value: '${profile.seasonYear}', label: 'SEASON'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF14100A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
