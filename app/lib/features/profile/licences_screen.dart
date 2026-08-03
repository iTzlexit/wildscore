import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../shared/theme.dart';

/// Every photograph and silhouette in the app, with its author and licence.
///
/// **This is a legal requirement, not a courtesy.** The photographs are CC-BY,
/// and attribution is a condition of that licence — one that has to be
/// *reachable by the user*, not merely present in a JSON file. A credit shown
/// only when somebody happens to open a full-screen photo does not satisfy it
/// for the ones they never open.
///
/// See docs/IMAGE-ASSETS.md, which records how this project walked into the
/// non-commercial licence trap twice before settling on CC0 and CC-BY only.
class LicencesScreen extends StatefulWidget {
  const LicencesScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const LicencesScreen(),
      ),
    );
  }

  @override
  State<LicencesScreen> createState() => _LicencesScreenState();
}

class _LicencesScreenState extends State<LicencesScreen> {
  List<_Credit> _photos = const <_Credit>[];
  List<_Credit> _silhouettes = const <_Credit>[];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<_Credit> photos = await _read(
      'assets/data/attributions.json',
      'photos',
    );
    final List<_Credit> silhouettes = await _read(
      'assets/data/silhouette-credits.json',
      'images',
    );
    if (mounted) {
      setState(() {
        _photos = photos;
        _silhouettes = silhouettes;
        _loaded = true;
      });
    }
  }

  static Future<List<_Credit>> _read(String path, String key) async {
    try {
      final Map<String, dynamic> decoded =
          json.decode(await rootBundle.loadString(path))
              as Map<String, dynamic>;
      final List<_Credit> credits = <_Credit>[
        for (final dynamic e in decoded[key] as List<dynamic>)
          _Credit(
            id: (e as Map<String, dynamic>)['id'] as String,
            author: e['author'] as String,
            licence: e['license'] as String,
          ),
      ]..sort((_Credit a, _Credit b) => a.id.compareTo(b.id));
      return credits;
    } on Object {
      // A missing credits file must never crash the app. It does mean the
      // licence condition is unmet, which is a build problem, not a runtime
      // one — the species data test catches it.
      return const <_Credit>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Credits and licences', style: AppText.title2),
        backgroundColor: AppColors.background,
      ),
      body: !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.sm,
                Space.screen,
                Space.xxl,
              ),
              children: <Widget>[
                Text(
                  'Wild Score is built on work other people gave away. Every '
                  'photograph and silhouette here is used under a licence that '
                  'permits it, and the people who made them are named below.',
                  style: AppText.body.copyWith(height: 1.55),
                ),
                const SizedBox(height: Space.xl),

                _Source(
                  title: 'Photographs',
                  subtitle: 'iNaturalist — inaturalist.org',
                  body:
                      'Used under Creative Commons CC0 and CC-BY only. '
                      'Non-commercial licences are deliberately excluded.',
                  count: _photos.length,
                ),
                const SizedBox(height: Space.md),
                for (final _Credit c in _photos) _CreditRow(credit: c),

                const SizedBox(height: Space.xl),
                _Source(
                  title: 'Silhouettes',
                  subtitle: 'PhyloPic — phylopic.org',
                  body:
                      'Used where no photograph could be confidently '
                      'identified. CC0 requires no attribution; these are '
                      'credited regardless.',
                  count: _silhouettes.length,
                ),
                const SizedBox(height: Space.md),
                for (final _Credit c in _silhouettes) _CreditRow(credit: c),

                const SizedBox(height: Space.xl),
                const _Source(
                  title: 'Typeface',
                  subtitle: 'Inter, by Rasmus Andersson',
                  body: 'SIL Open Font License 1.1.',
                  count: null,
                ),

                const SizedBox(height: Space.xl),
                const _Source(
                  title: 'Species information',
                  subtitle: 'Compiled for this app',
                  body:
                      'Conservation statuses follow the IUCN Red List. Rarity '
                      'tiers are our own judgement of how hard an animal is to '
                      'find in Kruger, and are reviewed as players tell us we '
                      'have them wrong.',
                  count: null,
                ),
              ],
            ),
    );
  }
}

class _Credit {
  const _Credit({
    required this.id,
    required this.author,
    required this.licence,
  });

  final String id;
  final String author;
  final String licence;

  /// `caracal` → `Caracal`, `black-backed-jackal` → `Black backed jackal`.
  /// Cheaper than threading the whole catalogue through this screen for a
  /// label nobody reads closely.
  String get name {
    final String spaced = id.replaceAll('-', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  /// `publicdomain/zero/1.0/` → `CC0`; `cc-by` → `CC BY`.
  String get licenceLabel {
    if (licence.contains('zero') || licence.toLowerCase() == 'cc0') {
      return 'CC0';
    }
    return licence.toUpperCase().replaceAll('-', ' ');
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.credit});

  final _Credit credit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              credit.name,
              style: AppText.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              credit.author,
              style: AppText.caption.copyWith(color: AppColors.textPrimary),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              credit.licenceLabel,
              textAlign: TextAlign.right,
              style: AppText.caption.copyWith(
                fontSize: 10.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.count,
  });

  final String title;
  final String subtitle;
  final String body;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(title, style: AppText.title3)),
              if (count != null)
                Text(
                  '$count',
                  style: AppText.label.copyWith(
                    color: AppColors.accent,
                    fontVariations: AppFonts.weight(800),
                    fontFeatures: AppText.tabular,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppText.caption.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: Space.sm),
          Text(body, style: AppText.caption.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
