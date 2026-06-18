import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/core/database/string_id_hash.dart';

void main() {
  test('stableStringIdHash returns a deterministic positive id', () {
    final first = stableStringIdHash('course-os');
    final second = stableStringIdHash('course-os');
    final different = stableStringIdHash('course-db');

    expect(first, second);
    expect(first, greaterThan(0));
    expect(first, isNot(different));
  });
}
