import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/courses/domain/course_week_text.dart';

void main() {
  group('CourseWeekText.parse', () {
    test('preserves labeled range and list expressions', () {
      expect(
        CourseWeekText.parse('周次: 1-5,7-9', minWeek: 1, maxWeek: 24),
        <int>[1, 2, 3, 4, 5, 7, 8, 9],
      );
    });

    test('ignores unrelated trailing notes', () {
      expect(
        CourseWeekText.parse('1-16周,共32学时', minWeek: 1, maxWeek: 24),
        List<int>.generate(16, (index) => index + 1),
      );
    });

    test('ignores unrelated trailing range notes', () {
      expect(
        CourseWeekText.parse('1-16周,32-48学时', minWeek: 1, maxWeek: 24),
        List<int>.generate(16, (index) => index + 1),
      );
    });

    test('rejects an out-of-range single token in mixed input', () {
      expect(
        CourseWeekText.parse('1-16周,25', minWeek: 1, maxWeek: 24),
        isEmpty,
      );
    });

    test('rejects an oversized range before expansion', () {
      expect(
        CourseWeekText.parse('1-16周,1-1000', minWeek: 1, maxWeek: 24),
        isEmpty,
      );
    });

    test('keeps the default unbounded API compatible', () {
      expect(CourseWeekText.parse('25周'), <int>[25]);
    });
  });
}
