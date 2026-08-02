import 'package:flutter/material.dart';

import '../../shared/theme.dart';

/// Add everyone in the car, then start.
///
/// No accounts, no invites, no sign-in — a family at a gate at 05:30 will not
/// do any of that, and every field added here is a family that gives up and
/// uses paper instead.
class StartScorecardSheet extends StatefulWidget {
  const StartScorecardSheet({super.key});

  /// Returns the player names, or null if dismissed.
  static Future<List<String>?> show(BuildContext context) {
    return showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => const StartScorecardSheet(),
    );
  }

  @override
  State<StartScorecardSheet> createState() => _StartScorecardSheetState();
}

class _StartScorecardSheetState extends State<StartScorecardSheet> {
  final List<String> _names = <String>[];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final String name = _controller.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty || _names.contains(name)) {
      return;
    }
    setState(() {
      _names.add(name);
      _controller.clear();
    });
    // Keep focus so a carful of people can be added without reaching for the
    // field again between each one.
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(Space.md),
          padding: const EdgeInsets.all(Space.screen),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Radii.sheet),
            boxShadow: AppColors.shadowMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("Who's in the car?", style: AppText.title2),
              const SizedBox(height: Space.xs),
              Text(
                'Add everyone playing today. Names only.',
                style: AppText.caption,
              ),
              const SizedBox(height: Space.screen),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                      style: AppText.bodyStrong,
                      decoration: searchFieldDecoration('Name').copyWith(
                        prefixIcon: const Icon(
                          Icons.person_add_alt_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  IconButton.filled(
                    onPressed: _add,
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.accentInk,
                      minimumSize: const Size(52, 52),
                    ),
                  ),
                ],
              ),
              if (_names.isNotEmpty) ...<Widget>[
                const SizedBox(height: Space.lg),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: <Widget>[
                    for (final String name in _names)
                      InputChip(
                        label: Text(name, style: AppText.label),
                        onDeleted: () => setState(() => _names.remove(name)),
                        backgroundColor: AppColors.surfaceAlt,
                        side: const BorderSide(color: AppColors.outline),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Space.xl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _names.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_names),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentInk,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.card),
                    ),
                  ),
                  child: Text(
                    _names.isEmpty
                        ? 'Add at least one player'
                        : 'Start the day  ·  ${_names.length} playing',
                    style: AppText.bodyStrong.copyWith(
                      color: _names.isEmpty
                          ? AppColors.textMuted
                          : AppColors.accentInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
