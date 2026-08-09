/// Where a population figure came from, which is most of what it means.
///
/// The distinction is not pedantry. SANParks flies fixed-wing and helicopter
/// transects over the park and the numbers that come back carry a real
/// statistical range — 16,700 to 21,948 elephant is not somebody hedging, it is
/// the survey's own confidence interval. Nobody flies a plane over leopards, so
/// every leopard number in print is an educated guess and the published ones
/// differ by a factor of two. Showing both the same way would quietly lie about
/// the second kind.
enum PopulationBasis {
  /// Counted from the air. The range is the survey's.
  survey('Aerial survey'),

  /// Nobody counts these. The range spans what the published sources claim.
  estimate('Best published estimate'),

  /// Deliberately not published, or never counted at all.
  withheld('');

  const PopulationBasis(this.label);

  final String label;
}

/// Roughly how many of this animal are in the park.
///
/// **The most interesting number on the card**, and the one that turns a rarity
/// tier from a game mechanic into a fact. "Legendary, 2000 points" is a scoring
/// decision somebody made. "Forty to seventy-five left in the whole park" is
/// why.
///
/// Rhino is the case that shapes the type. SANParks stopped publishing rhino
/// numbers because a poacher can use them, so there is no honest figure to
/// print — and the *absence* is the story, not a gap to leave blank. Hence
/// [PopulationBasis.withheld] carrying a [note] instead of a range, which is
/// also how pangolin and aardvark are handled: never surveyed, and saying so is
/// better than inventing a number.
class Population {
  const Population({
    required this.basis,
    this.low,
    this.high,
    this.year,
    this.note,
  });

  factory Population.fromJson(Map<String, dynamic> json) {
    final String name = json['basis'] as String;
    return Population(
      basis: PopulationBasis.values.firstWhere(
        (PopulationBasis b) => b.name == name,
        orElse: () => throw FormatException('Unknown population basis "$name"'),
      ),
      low: json['low'] as int?,
      high: json['high'] as int?,
      year: json['year'] as int?,
      note: json['note'] as String?,
    );
  }

  final PopulationBasis basis;
  final int? low;
  final int? high;

  /// Survey year. Absent on estimates, which are not tied to one.
  final int? year;

  /// Why there is no number, on the withheld ones.
  final String? note;

  bool get isKnown => basis != PopulationBasis.withheld && low != null;

  /// "40 – 75", "5,889", "Not published".
  String get display {
    if (!isKnown) {
      return 'Not published';
    }
    final int lo = low!;
    final int hi = high ?? lo;
    return lo == hi ? _thousands(lo) : '${_thousands(lo)} – ${_thousands(hi)}';
  }

  /// "Aerial survey, 2023" · "Best published estimate".
  String get attribution =>
      year == null ? basis.label : '${basis.label}, $year';

  /// Grouping separators, without pulling in `intl` for one function.
  static String _thousands(int n) {
    final String digits = n.toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        out.write(' ');
      }
      out.write(digits[i]);
    }
    return out.toString();
  }
}
