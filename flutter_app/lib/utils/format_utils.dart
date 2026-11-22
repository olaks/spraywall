/// `yyyy-MM-dd`, the form every date is stored in.
String dateStrFrom(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';

/// Parses a `yyyy-MM-dd` date as local midnight.
DateTime dateFromStr(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}
