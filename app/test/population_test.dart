import 'package:flutter_test/flutter_test.dart';
import 'package:wildscore/data/species_repository.dart';
import 'package:wildscore/domain/population.dart';
import 'package:wildscore/domain/species.dart';

/// How many are left, on the card.
///
/// The reason this file exists is the rhino. The app already refuses to say
/// *where* a rhino was seen; printing "there are N rhino in Kruger" would give
/// away the other half of the same information, and SANParks withholds the
/// figure for exactly that reason. So the rule is asserted here rather than
/// left to whoever adds the next species.
late final List<Species> _all;

Species _byId(String id) => _all.firstWhere((Species s) => s.id == id);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _all = await const SpeciesRepository().loadAll();
  });

  group('the sensitive species never carry a number', () {
    test('rhino and pangolin are withheld, not merely absent', () {
      // Absent would be a bug that looks like data nobody got round to.
      // Withheld is a decision, and the card says so.
      for (final Species s in _all.where((Species s) => s.isSensitive)) {
        expect(s.population, isNotNull, reason: s.id);
        expect(
          s.population!.basis,
          PopulationBasis.withheld,
          reason: '${s.id} would print a number',
        );
        expect(s.population!.low, isNull);
        expect(s.population!.high, isNull);
        expect(s.population!.note, isNotNull, reason: '${s.id} explains why');
      }
    });

    test('a withheld population renders as words, never as a count', () {
      final Population p = _byId('white-rhinoceros').population!;

      expect(p.isKnown, isFalse);
      expect(p.display, 'Not published');
      expect(p.display, isNot(matches(RegExp(r'\d'))));
    });
  });

  group('the figures that are shown', () {
    test('every range runs low to high', () {
      for (final Species s in _all) {
        final Population? p = s.population;
        if (p == null || !p.isKnown) {
          continue;
        }
        expect(p.high, isNotNull, reason: s.id);
        expect(
          p.low!,
          lessThanOrEqualTo(p.high!),
          reason: '${s.id} is back to front',
        );
        expect(p.low!, greaterThan(0), reason: s.id);
      }
    });

    test('a survey figure says which year, an estimate does not', () {
      // The year is what makes a survey number checkable. An estimate is not
      // tied to one and pretending otherwise would be inventing precision.
      for (final Species s in _all) {
        final Population? p = s.population;
        if (p == null) {
          continue;
        }
        if (p.basis == PopulationBasis.survey) {
          expect(p.year, isNotNull, reason: s.id);
          expect(p.attribution, contains('${p.year}'), reason: s.id);
        }
        if (p.basis == PopulationBasis.estimate) {
          expect(p.year, isNull, reason: s.id);
        }
      }
    });

    test('the rarest antelope reads the way the tier claims', () {
      // Lichtenstein's hartebeest is the reason the field was added: Legendary
      // is a scoring decision, and this is the fact underneath it.
      final Species h = _byId('lichtensteins-hartebeest');

      expect(h.population!.display, '40 – 75');
      expect(h.population!.attribution, 'Aerial survey, 2023');
    });

    test('big numbers get separators, so 168451 is readable at a glance', () {
      expect(_byId('impala').population!.display, '123 998 – 168 451');
    });

    test('a single figure is shown once, not as a range of itself', () {
      expect(_byId('hippopotamus').population!.display, '5 889');
    });
  });

  test('nothing common enough to be uncounted claims a figure', () {
    // Sanity on the other end: a number on a blue waxbill would be invented,
    // and one invented figure discredits the forty real ones beside it.
    final Iterable<Species> withFigures = _all.where(
      (Species s) => s.population != null,
    );

    expect(withFigures.length, lessThan(40));
    for (final Species s in withFigures) {
      expect(
        s.category.name,
        anyOf('mammal', 'bird'),
        reason: '${s.id} — no published census covers this',
      );
    }
  });
}
