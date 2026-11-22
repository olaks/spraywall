import 'package:flutter/foundation.dart';
import '../database/database.dart';

/// How the wall screen orders its problems.
enum ProblemSort {
  /// Easiest first by position in the wall's scale, ungraded last, ties by
  /// name.
  grade,

  /// Newest set date first, ties by name.
  newest,
}

/// The wall screen's filters and sort. Kept in memory for the app run, never
/// in the URL.
@immutable
class ProblemQuery {
  /// The easiest and hardest grade shown, both included; null is open. While
  /// either is set, ungraded problems are hidden: they have no place in a
  /// range.
  final String?     minGrade;
  final String?     maxGrade;

  /// Part of the name, ignoring case; blank shows everything.
  final String      name;
  final ProblemSort sort;

  /// Retired problems are hidden unless this is on. It widens the list
  /// rather than narrowing it, so it is no filter: clearing keeps it.
  final bool        showRetired;

  const ProblemQuery({
    this.minGrade,
    this.maxGrade,
    this.name        = '',
    this.sort        = ProblemSort.grade,
    this.showRetired = false,
  });

  bool get hasGradeRange => minGrade != null || maxGrade != null;
  bool get filters       => hasGradeRange || name.trim().isNotEmpty;

  ProblemQuery _with({
    String?      minGrade,
    String?      maxGrade,
    bool         grades = false,
    String?      name,
    ProblemSort? sort,
    bool?        showRetired,
  }) =>
      ProblemQuery(
        minGrade:    grades ? minGrade : this.minGrade,
        maxGrade:    grades ? maxGrade : this.maxGrade,
        name:        name        ?? this.name,
        sort:        sort        ?? this.sort,
        showRetired: showRetired ?? this.showRetired,
      );

  ProblemQuery withGrades(String? min, String? max) =>
      _with(minGrade: min, maxGrade: max, grades: true);
  ProblemQuery withName(String name)       => _with(name: name);
  ProblemQuery withSort(ProblemSort sort)  => _with(sort: sort);
  ProblemQuery withShowRetired(bool show)  => _with(showRetired: show);

  /// The same sort and "Show retired", with no filters.
  ProblemQuery cleared() => ProblemQuery(sort: sort, showRetired: showRetired);

  @override
  bool operator ==(Object other) =>
      other is ProblemQuery && other.minGrade == minGrade &&
      other.maxGrade == maxGrade && other.name == name &&
      other.sort == sort && other.showRetired == showRetired;

  @override
  int get hashCode => Object.hash(minGrade, maxGrade, name, sort, showRetired);
}

/// [problems] filtered and sorted by [query], with grades ordered by their
/// position in [scale] (easiest first). A grade not on the scale counts as
/// ungraded. Retired problems sort among the others.
List<Problem> browse(
    List<Problem> problems, List<String> scale, ProblemQuery query) {
  int? rank(String? grade) {
    if (grade == null) return null;
    final i = scale.indexOf(grade);
    return i < 0 ? null : i;
  }

  final lo     = rank(query.minGrade) ?? 0;
  final hi     = rank(query.maxGrade) ?? scale.length - 1;
  final needle = query.name.trim().toLowerCase();

  bool keep(Problem p) {
    if (p.retiredOn != null && !query.showRetired) return false;
    if (needle.isNotEmpty && !p.name.toLowerCase().contains(needle)) {
      return false;
    }
    if (!query.hasGradeRange) return true;
    final r = rank(p.grade);
    return r != null && r >= lo && r <= hi;
  }

  int byName(Problem a, Problem b) {
    final c = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return c != 0 ? c : a.name.compareTo(b.name);
  }

  int byGrade(Problem a, Problem b) {
    final ra = rank(a.grade), rb = rank(b.grade);
    if (ra != rb) {
      if (ra == null) return 1;
      if (rb == null) return -1;
      return ra.compareTo(rb);
    }
    return byName(a, b);
  }

  // Dates are yyyy-MM-dd, so the text sorts like the date.
  int byNewest(Problem a, Problem b) {
    final c = b.setOn.compareTo(a.setOn);
    return c != 0 ? c : byName(a, b);
  }

  return problems.where(keep).toList()
    ..sort(query.sort == ProblemSort.grade ? byGrade : byNewest);
}

/// The photo a problem's list row shows: the first in [photos] (the layout's
/// order) carrying any of [marks], which are this problem's. Null for a
/// problem with no marks, which saving never allows.
WallPhoto? firstMarkedPhoto(List<WallPhoto> photos, Iterable<Mark> marks) {
  final used = {for (final m in marks) m.photoId};
  return photos.where((p) => used.contains(p.id)).firstOrNull;
}
