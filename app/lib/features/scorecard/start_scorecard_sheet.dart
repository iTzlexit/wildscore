import 'package:flutter/material.dart';

import '../../domain/avatar_seed.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/avatar_badge.dart';

/// Add everyone in the car, then start.
///
/// No accounts, no invites, no sign-in — a family at a gate at 05:30 will not
/// do any of that, and every field added here is a family that gives up and
/// uses paper instead.
class StartScorecardSheet extends StatefulWidget {
  const StartScorecardSheet({this.owner, super.key});

  /// The account holder's name, pre-added and not removable.
  ///
  /// You are in the car. Making the phone's owner type their own name every
  /// morning is friction for nothing — and, more importantly, it is how a day's
  /// claims fail to reach their permanent collection, because a guest called
  /// "alex" is not the same person as the account.
  final String? owner;

  /// Returns the player names, or null if dismissed.
  static Future<List<String>?> show(BuildContext context, {String? owner}) {
    return showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => StartScorecardSheet(owner: owner),
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
  void initState() {
    super.initState();
    if (widget.owner != null) {
      _names.add(widget.owner!);
    }
  }

  bool _isOwner(String name) =>
      widget.owner != null && name.toLowerCase() == widget.owner!.toLowerCase();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final String name = _controller.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty ||
        _names.any((String n) => n.toLowerCase() == name.toLowerCase())) {
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
                widget.owner == null
                    ? 'Add everyone playing today. Names only.'
                    : 'Add everyone playing today. Whatever you claim also '
                          'goes to your own collection.',
                style: AppText.caption.copyWith(height: 1.45),
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
                        avatar: _isOwner(name)
                            ? AvatarBadge(
                                avatar: AvatarSeed.forName(name),
                                size: 26,
                              )
                            // Guests are dealt a face when the day starts, not
                            // here — the reveal is part of kicking off.
                            : const Icon(
                                Icons.person_rounded,
                                size: 17,
                                color: AppColors.textMuted,
                              ),
                        label: Text(
                          _isOwner(name) ? '$name · you' : name,
                          style: AppText.label,
                        ),
                        // The account holder cannot be removed. Playing without
                        // yourself in the car is not a thing anyone means to do.
                        onDeleted: _isOwner(name)
                            ? null
                            : () => setState(() => _names.remove(name)),
                        backgroundColor: _isOwner(name)
                            ? AppColors.accentWash
                            : AppColors.surfaceAlt,
                        side: BorderSide(
                          color: _isOwner(name)
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : AppColors.outline,
                        ),
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
