import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Photo credits for the Codex reference images.
///
/// Not optional politeness: the images are CC-BY licensed, and attribution is a
/// condition of that licence. Shipping them without credit would be a copyright
/// violation, so this loads alongside the species catalogue and the credit is
/// shown on the photograph itself rather than buried in a settings screen.
///
/// Missing entries are fine — a species with no sourced photo shows the
/// generated monogram plate and needs no credit.
class AttributionRepository {
  const AttributionRepository();

  static const String _assetPath = 'assets/data/attributions.json';

  Future<Map<String, String>> loadAll() async {
    late final String raw;
    try {
      raw = await rootBundle.loadString(_assetPath);
    } catch (_) {
      // No attributions file bundled yet. The app is perfectly usable with
      // placeholder art, so a missing credits file must never be fatal.
      return const <String, String>{};
    }

    final Map<String, dynamic> decoded =
        json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> entries = decoded['photos'] as List<dynamic>;

    return <String, String>{
      for (final dynamic entry in entries)
        (entry as Map<String, dynamic>)['id'] as String: _format(entry),
    };
  }

  static String _format(Map<String, dynamic> entry) {
    final String author = entry['author'] as String;
    final String licence = (entry['license'] as String).toUpperCase();
    return 'Photo © $author — $licence, via iNaturalist';
  }
}
