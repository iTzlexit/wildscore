import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/backup_repository.dart';
import '../../domain/backup.dart';
import '../../shared/date_format.dart';
import '../../shared/theme.dart';

/// Get your collection off this phone, and back onto another one.
///
/// A code rather than a file, and no share sheet, because both of those want
/// plugins and this needed to exist now rather than after a dependency
/// discussion. A long-press paste into an email to yourself is not elegant, and
/// it is the difference between losing a season and losing nothing.
///
/// See docs/RISKS.md for why this is worth more than anything else outstanding.
class BackupScreen extends StatefulWidget {
  const BackupScreen({
    this.repository = const BackupRepository(),
    this.onRestored,
    super.key,
  });

  final BackupRepository repository;

  /// Lets the shell reload its state after a restore, since every screen reads
  /// from it.
  final VoidCallback? onRestored;

  static Future<void> open(
    BuildContext context, {
    BackupRepository repository = const BackupRepository(),
    VoidCallback? onRestored,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            BackupScreen(repository: repository, onRestored: onRestored),
      ),
    );
  }

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final TextEditingController _paste = TextEditingController();
  Backup? _current;
  String? _error;
  String? _done;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.repository.read().then((Backup b) {
      if (mounted) {
        setState(() => _current = b);
      }
    });
  }

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final Backup? backup = _current;
    if (backup == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: backup.encode()));
    if (!mounted) {
      return;
    }
    setState(() {
      _error = null;
      _done =
          'Backup copied. Paste it into an email to yourself, or a message to '
          'your own number, and keep it somewhere you will find it again.';
    });
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _error = null;
      _done = null;
    });
    try {
      final Backup incoming = Backup.decode(_paste.text);
      final Backup merged = await widget.repository.restore(incoming);
      widget.onRestored?.call();
      if (!mounted) {
        return;
      }
      _paste.clear();
      setState(() {
        _current = merged;
        _done =
            'Restored. You now have ${merged.spotted.length} species and '
            '${merged.visits.length} '
            '${merged.visits.length == 1 ? 'drive' : 'drives'}.';
      });
    } on BackupFormatException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Backup? backup = _current;

    return Scaffold(
      appBar: AppBar(
        title: Text('Back up', style: AppText.title2),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          Space.sm,
          Space.screen,
          Space.xxl,
        ),
        children: <Widget>[
          Text(
            'Everything you have found lives on this phone and nowhere else. '
            'Lose the phone and it goes with it — your own phone backup may '
            'catch it, and it may quietly not.',
            style: AppText.body.copyWith(height: 1.55),
          ),
          const SizedBox(height: Space.xl),

          const _Section('SAVE A COPY'),
          Container(
            padding: const EdgeInsets.all(Space.screen),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (backup == null)
                  Text('Reading your collection…', style: AppText.caption)
                else
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _Stat(
                          value: '${backup.spotted.length}',
                          label: 'SPECIES',
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          value: '${backup.visits.length}',
                          label: 'DRIVES',
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          value: '${backup.lifetimePoints}',
                          label: 'POINTS',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: Space.lg),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: backup == null ? null : _copy,
                    icon: const Icon(Icons.content_copy_rounded, size: 19),
                    label: Text(
                      'Copy my backup code',
                      style: AppText.bodyStrong.copyWith(
                        color: AppColors.accentInk,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.chip),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'Do it at the end of a trip, when there is signal at camp.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.xl),
          const _Section('RESTORE FROM A CODE'),
          Text(
            'On a new phone, paste the code you saved. Nothing is ever deleted '
            'by a restore — whatever is already here is kept and the two are '
            'combined.',
            style: AppText.caption.copyWith(height: 1.5),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _paste,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
            // Not searchFieldDecoration: copyWith cannot remove its magnifier,
            // because passing null to copyWith means "leave it alone".
            decoration: InputDecoration(
              hintText: 'Paste your backup code here',
              filled: true,
              fillColor: AppColors.surface,
              hintStyle: AppText.label.copyWith(color: AppColors.textMuted),
              contentPadding: const EdgeInsets.all(Space.lg),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.card),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.card),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.card),
                borderSide: const BorderSide(
                  color: AppColors.accent,
                  width: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore_rounded, size: 19),
              label: Text(
                'Restore',
                style: AppText.bodyStrong.copyWith(color: AppColors.accent),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.outlineStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.chip),
                ),
              ),
            ),
          ),

          if (_error != null) ...<Widget>[
            const SizedBox(height: Space.lg),
            _Banner(
              text: _error!,
              tint: AppColors.danger,
              icon: Icons.error_outline_rounded,
            ),
          ],
          if (_done != null) ...<Widget>[
            const SizedBox(height: Space.lg),
            _Banner(
              text: _done!,
              tint: AppColors.accent,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],

          if (backup != null) ...<Widget>[
            const SizedBox(height: Space.xl),
            Text(
              'This copy is from ${formatLongDate(backup.exportedAt)}.',
              style: AppText.caption,
            ),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: AppText.title1.copyWith(
            fontSize: 26,
            color: AppColors.accent,
            fontFeatures: AppText.tabular,
          ),
        ),
        Text(label, style: AppText.overline.copyWith(fontSize: 9)),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.tint, required this.icon});

  final String text;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: tint),
          const SizedBox(width: Space.md),
          Expanded(
            child: Text(
              text,
              style: AppText.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Text(text, style: AppText.overline),
    );
  }
}
