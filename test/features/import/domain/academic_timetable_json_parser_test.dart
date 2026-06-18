import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/import/domain/academic_timetable_json_parser.dart';

void main() {
  group('AcademicTimetableJsonParser.parse', () {
    test('extracts evening and weekend courses from school semester JSON', () {
      const source = '''
      {
        "kblx": "2",
        "xsxx": {"XM": "示例学生"},
        "kbList": [
          {
            "kcmc": "课程设计A",
            "jxbmc": "课程设计A-0003",
            "xqmc": "示例校区",
            "cdmc": "3#215",
            "xm": "教师A",
            "zcd": "6周",
            "xqj": "2",
            "jcs": "9-10"
          },
          {
            "kcmc": "实践课程B",
            "jxbmc": "实践课程B-0001",
            "xqmc": "示例校区",
            "cdmc": "教学楼401",
            "xm": "教师B",
            "zcd": "8周",
            "xqj": "2",
            "jcs": "9-10"
          },
          {
            "kcmc": "基础课程C",
            "jxbmc": "基础课程C-0023（示例班）",
            "xqmc": "示例校区",
            "cdmc": "9#502",
            "xm": "教师C",
            "zcd": "12-15周",
            "xqj": "4",
            "jcs": "9-10"
          },
          {
            "kcmc": "课程设计A",
            "jxbmc": "课程设计A-0003",
            "xqmc": "示例校区",
            "cdmc": "3#215",
            "xm": "教师A",
            "zcd": "6周",
            "xqj": "7",
            "jcs": "1-10"
          },
          {
            "kcmc": "课程设计D",
            "jxbmc": "课程设计D-0005",
            "xqmc": "示例校区",
            "cdmc": "3#415",
            "xm": "教师D",
            "zcd": "13-14周",
            "xqj": "7",
            "jcs": "1-10"
          }
        ],
        "sjkList": []
      }
      ''';

      final timetable = AcademicTimetableJsonParser.parse(source);

      expect(timetable.schedules, hasLength(5));

      final courseDesign = timetable.metas.singleWhere(
        (meta) => meta.name == '课程设计A',
      );
      expect(courseDesign.teacher, '教师A');
      expect(courseDesign.teachingClass, '课程设计A-0003');
      final courseDesignSchedules =
          timetable.schedules
              .where((schedule) => schedule.courseMetaId == courseDesign.id)
              .toList()
            ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
      expect(courseDesignSchedules, hasLength(2));
      expect(courseDesignSchedules.first.dayOfWeek, 2);
      expect(courseDesignSchedules.first.startSection, 9);
      expect(courseDesignSchedules.first.endSection, 10);
      expect(courseDesignSchedules.first.classroom, '示例校区 3#215');
      expect(courseDesignSchedules.first.weeks, <int>[6]);
      expect(courseDesignSchedules.last.dayOfWeek, 7);
      expect(courseDesignSchedules.last.startSection, 1);
      expect(courseDesignSchedules.last.endSection, 10);

      final math = timetable.metas.singleWhere((meta) => meta.name == '基础课程C');
      final mathSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == math.id,
      );
      expect(math.teacher, '教师C');
      expect(math.teachingClass, '基础课程C-0023（示例班）');
      expect(mathSchedule.dayOfWeek, 4);
      expect(mathSchedule.startSection, 9);
      expect(mathSchedule.endSection, 10);
      expect(mathSchedule.weeks, <int>[12, 13, 14, 15]);

      final webDesign = timetable.metas.singleWhere(
        (meta) => meta.name == '课程设计D',
      );
      final webDesignSchedule = timetable.schedules.singleWhere(
        (schedule) => schedule.courseMetaId == webDesign.id,
      );
      expect(webDesignSchedule.dayOfWeek, 7);
      expect(webDesignSchedule.startSection, 1);
      expect(webDesignSchedule.endSection, 10);
      expect(webDesignSchedule.weeks, <int>[13, 14]);
    });

    test('also reads practice course list when kbList is empty', () {
      const source = '''
      {
        "kblx": "2",
        "kbList": [],
        "sjkList": [
          {
            "kcmc": "课程设计D",
            "jxbmc": "课程设计D-0005",
            "xqmc": "示例校区",
            "cdmc": "3#415",
            "xm": "教师D",
            "zcd": "13-14周",
            "xqj": "7",
            "jcs": "1-10"
          }
        ]
      }
      ''';

      final timetable = AcademicTimetableJsonParser.parse(source);

      expect(timetable.metas.single.name, '课程设计D');
      expect(timetable.schedules.single.dayOfWeek, 7);
      expect(timetable.schedules.single.startSection, 1);
      expect(timetable.schedules.single.endSection, 10);
    });
  });
}
