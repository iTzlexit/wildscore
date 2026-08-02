/// Dates, formatted by hand.
///
/// `intl` is around 600 KB for what amounts to two lookup tables here, and the
/// app is English-only for now. When a second language arrives this is the file
/// that gets deleted.
const List<String> _months = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "2 August 2026"
String formatLongDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// "2 Aug" — for sitting beside a label where the year is obvious.
String formatShortDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1].substring(0, 3)}';

/// "August"
String monthName(int month) => _months[month - 1];

/// True when both fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
