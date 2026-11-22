import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/problems/browse.dart';
import 'package:spraywall/utils/grades.dart';

/// The wall screen's filters and sorts, and the photo each row shows.
void main() {
  Problem problem(String name, String? grade, String setOn) => Problem(
      id: newId(), layoutId: 'l', name: name, grade: grade,
      description: '', setOn: setOn);

  final problems = [
    problem('crimps',  '6B',  '2026-11-02'),
    problem('Arête',   '7A',  '2026-11-20'),
    problem('Project', null,  '2026-11-21'),
    problem('Bulge',   '6B',  '2026-11-20'),
    problem('Kicker',  '6A+', '2026-10-01'),
  ];
  List<String> names(ProblemQuery q, [List<String> scale = fontGrades]) =>
      browse(problems, scale, q).map((p) => p.name).toList();

  group('sort', () {
    test('by grade: by position in the scale, not as text; ungraded last; '
        'ties by name ignoring case', () {
      expect(names(const ProblemQuery()),
          ['Kicker', 'Bulge', 'crimps', 'Arête', 'Project']);
    });

    test('V grades order by the scale: V10 after V9', () {
      final vs = [problem('Ten', 'V10', '2026-11-01'),
                  problem('Nine', 'V9', '2026-11-01'),
                  problem('Two', 'V2', '2026-11-01')];
      expect(browse(vs, vGrades, const ProblemQuery()).map((p) => p.name),
          ['Two', 'Nine', 'Ten']);
    });

    test('newest set date first, ties by name', () {
      expect(names(const ProblemQuery(sort: ProblemSort.newest)),
          ['Project', 'Arête', 'Bulge', 'crimps', 'Kicker']);
    });

    test('a grade off the scale sorts as ungraded', () {
      final odd = [problem('Odd', 'V3', '2026-11-01'),
                   problem('Easy', '4', '2026-11-01')];
      expect(browse(odd, fontGrades, const ProblemQuery()).map((p) => p.name),
          ['Easy', 'Odd']);
    });
  });

  group('filter', () {
    test('a grade range includes both ends and hides ungraded', () {
      expect(names(const ProblemQuery(minGrade: '6A+', maxGrade: '6B')),
          ['Kicker', 'Bulge', 'crimps']);
    });

    test('an open end runs to the end of the scale', () {
      expect(names(const ProblemQuery(minGrade: '6B')),
          ['Bulge', 'crimps', 'Arête']);
      expect(names(const ProblemQuery(maxGrade: '6A+')), ['Kicker']);
    });

    test('name: part of it, ignoring case, beyond ASCII too; blank is '
        'no filter', () {
      expect(names(const ProblemQuery(name: 'RI')), ['crimps']);
      expect(names(const ProblemQuery(name: ' ARÊ ')), ['Arête']);
      expect(names(const ProblemQuery(name: '  ')), hasLength(5));
    });

    test('filters combine', () {
      expect(names(const ProblemQuery(minGrade: '6B', name: 'u')), ['Bulge']);
    });

    test('clearing keeps the sort', () {
      const q = ProblemQuery(
          minGrade: '6B', name: 'x', sort: ProblemSort.newest);
      expect(q.cleared(), const ProblemQuery(sort: ProblemSort.newest));
      expect(q.cleared().filters, isFalse);
    });
  });

  test("a row's photo is the first in the layout's order with a mark", () {
    WallPhoto photo(String id, int order) => WallPhoto(
        id: id, layoutId: 'l', sortOrder: order, width: 4, height: 3,
        addedOn: '2026-11-22');
    Mark mark(String photoId, Role role) => Mark(
        id: newId(), problemId: 'p', photoId: photoId, role: role,
        cx: 0.5, cy: 0.5, r: 0.02);
    final photos = [photo('wall', 0), photo('left', 1), photo('kicker', 2)];

    expect(firstMarkedPhoto(photos, [mark('kicker', Role.start),
                                     mark('left', Role.hand)])!.id, 'left',
        reason: 'layout order, not the start photo or mark order');
    expect(firstMarkedPhoto(photos, []), isNull);
  });
}
