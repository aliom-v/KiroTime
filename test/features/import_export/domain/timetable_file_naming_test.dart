import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/import_export/domain/timetable_file_naming.dart';
import 'package:kiro_time/features/import_export/domain/timetable_json_codec.dart';

void main() {
  group('TimetableFileNaming', () {
    test('builds default current-semester export filename', () {
      final name = TimetableFileNaming.defaultExportFileName(
        scope: TimetableExportScope.currentSemester,
        semesterLabel: '2026-2027第二学期',
        now: DateTime(2026, 6, 18, 12, 45),
      );

      expect(name, 'KiroTime_当前学期_2026-2027第二学期_2026-06-18_1245.json');
    });

    test('builds default all-semester export filename', () {
      final name = TimetableFileNaming.defaultExportFileName(
        scope: TimetableExportScope.allSemesters,
        semesterLabel: 'ignored',
        now: DateTime(2026, 6, 18, 12, 45),
      );

      expect(name, 'KiroTime_全部学期_2026-06-18_1245.json');
    });

    test('sanitizes invalid filename characters and keeps json extension', () {
      final name = TimetableFileNaming.sanitizeJsonFileName(
        '  Kiro/Time:*?"<>|备份  ',
      );

      expect(name, 'Kiro_Time_______备份.json');
    });

    test('falls back when sanitized filename is empty', () {
      final name = TimetableFileNaming.sanitizeJsonFileName(' /:*?"<>| ');

      expect(name, 'KiroTime_课表备份.json');
    });

    test('creates numbered copy names from existing filenames', () {
      final copy = TimetableFileNaming.copyNameFor(
        'KiroTime_全部学期.json',
        const <String>{'KiroTime_全部学期.json', 'KiroTime_全部学期_2.json'},
      );

      expect(copy, 'KiroTime_全部学期_3.json');
    });
  });
}
