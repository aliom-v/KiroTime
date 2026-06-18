import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/courses/data/course_meta.dart';
import 'package:kiro_time/features/courses/data/course_schedule.dart';
import 'package:kiro_time/features/import_export/domain/timetable_json_codec.dart';
import 'package:kiro_time/features/timetable/domain/semester_settings.dart';
import 'package:kiro_time/features/timetable/domain/section_time_settings.dart';

void main() {
  test('current semester export json round-trips course and semester data', () {
    final snapshot = TimetableExportSnapshot(
      scope: TimetableExportScope.currentSemester,
      exportedAt: DateTime(2026, 6, 17, 12),
      selectedSemesterId: '2026-1',
      semesters: <SemesterSettings>[
        SemesterSettings(
          id: '2026-1',
          schoolYearStart: 2026,
          semester: 1,
          semesterStart: DateTime(2026, 8, 31),
          totalWeeks: 19,
          sectionCount: 10,
          displayName: '大三上',
          sectionTimeSettings: SectionTimeSettings.defaultForSectionCount(10)
              .replaceSection(
                const SectionTime(
                  section: 1,
                  startMinutes: 7 * 60,
                  endMinutes: 465,
                ),
              ),
        ),
      ],
      metas: <CourseMeta>[
        CourseMeta.create(
          id: 'meta-os',
          name: '操作系统',
          teacher: '吕林涛',
          teachingClass: '操作系统-0011',
        ),
      ],
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-os',
          courseMetaId: 'meta-os',
          classroom: '南校区 3#504',
          dayOfWeek: 4,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1, 2, 3, 5, 7],
          semesterId: '2026-1',
        ),
      ],
      appSettings: const <String, String>{
        'appearance': '{"showWeekend":false}',
      },
    );

    final encoded = TimetableJsonCodec.encode(snapshot);
    final decoded = TimetableJsonCodec.decode(encoded);

    expect(decoded.scope, TimetableExportScope.currentSemester);
    expect(decoded.selectedSemesterId, '2026-1');
    expect(decoded.semesters.single.label, '大三上');
    expect(
      decoded.semesters.single.sectionTimeSettings.section(1).timeRangeText,
      '07:00-07:45',
    );
    expect(decoded.metas.single.teachingClass, '操作系统-0011');
    expect(decoded.schedules.single.weeks, <int>[1, 2, 3, 5, 7]);
    expect(decoded.schedules.single.semesterId, '2026-1');
    expect(decoded.appSettings['appearance'], '{"showWeekend":false}');
  });

  test('old json without section times falls back to defaults', () {
    const source = '''
{
  "format": "kiro_time_timetable",
  "version": 1,
  "scope": "currentSemester",
  "exportedAt": "2026-06-17T12:00:00.000",
  "selectedSemesterId": "2026-1",
  "semesters": [
    {
      "id": "2026-1",
      "schoolYearStart": 2026,
      "semester": 1,
      "semesterStart": "2026-08-31T00:00:00.000",
      "totalWeeks": 19,
      "sectionCount": 10,
      "displayName": "大三上"
    }
  ],
  "metas": [],
  "schedules": [],
  "appSettings": {}
}
''';

    final decoded = TimetableJsonCodec.decode(source);

    expect(
      decoded.semesters.single.sectionTimeSettings.sections,
      hasLength(10),
    );
    expect(
      decoded.semesters.single.sectionTimeSettings.section(1).timeRangeText,
      '08:10-08:55',
    );
  });

  test('preview reports courses, conflicts, and semester start date', () {
    final snapshot = TimetableExportSnapshot(
      scope: TimetableExportScope.currentSemester,
      exportedAt: DateTime(2026, 6, 17, 12),
      selectedSemesterId: '2026-1',
      semesters: <SemesterSettings>[
        SemesterSettings(
          id: '2026-1',
          schoolYearStart: 2026,
          semester: 1,
          semesterStart: DateTime(2026, 8, 31),
          totalWeeks: 19,
        ),
      ],
      metas: <CourseMeta>[
        CourseMeta.create(id: 'meta-a', name: 'A', teacher: 'TA'),
        CourseMeta.create(id: 'meta-b', name: 'B', teacher: 'TB'),
      ],
      schedules: <CourseSchedule>[
        CourseSchedule.create(
          id: 'schedule-a',
          courseMetaId: 'meta-a',
          classroom: '1#101',
          dayOfWeek: 2,
          startSection: 5,
          endSection: 6,
          weeks: <int>[3],
          semesterId: '2026-1',
        ),
        CourseSchedule.create(
          id: 'schedule-b',
          courseMetaId: 'meta-b',
          classroom: '1#102',
          dayOfWeek: 2,
          startSection: 6,
          endSection: 7,
          weeks: <int>[3],
          semesterId: '2026-1',
        ),
      ],
    );

    final preview = TimetableJsonCodec.preview(snapshot);

    expect(preview.courseCount, 2);
    expect(preview.scheduleCount, 2);
    expect(preview.conflictCount, 1);
    expect(preview.semesterStart, DateTime(2026, 8, 31));
  });
}
