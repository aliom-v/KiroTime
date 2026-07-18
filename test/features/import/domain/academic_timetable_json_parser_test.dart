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

    test('keeps non-theory course marker in imported course name', () {
      const source = '''
      {
        "kbList": [
          {
            "kcmc": "计算机网络原理■",
            "jxbmc": "计算机网络原理-0001A",
            "xqmc": "示例校区",
            "cdmc": "3#315机房",
            "xm": "教师A",
            "zcd": "15周",
            "xqj": "2",
            "jcs": "5-8"
          }
        ],
        "sjkList": []
      }
      ''';

      final timetable = AcademicTimetableJsonParser.parse(source);

      expect(timetable.metas.single.name, '计算机网络原理■');
      expect(timetable.metas.single.teachingClass, '计算机网络原理-0001A');
      expect(timetable.schedules.single.dayOfWeek, 2);
      expect(timetable.schedules.single.startSection, 5);
      expect(timetable.schedules.single.endSection, 8);
      expect(timetable.schedules.single.weeks, <int>[15]);
    });

    test('skips schedules outside supported section and week bounds', () {
      const source = '''
      {
        "kbList": [
          {
            "kcmc": "边界有效课程",
            "jxbmc": "边界有效课程-0001",
            "xqmc": "示例校区",
            "cdmc": "教学楼101",
            "xm": "教师A",
            "zcd": "24周",
            "xqj": "7",
            "jcs": "15-16"
          },
          {
            "kcmc": "无效起始节次课程",
            "zcd": "1周",
            "xqj": "1",
            "jcs": "0-2"
          },
          {
            "kcmc": "无效结束节次课程",
            "zcd": "1周",
            "xqj": "1",
            "jcs": "15-17"
          },
          {
            "kcmc": "无效第零周课程",
            "zcd": "0周",
            "xqj": "1",
            "jcs": "1-2"
          },
          {
            "kcmc": "无效超界周课程",
            "zcd": "25周",
            "xqj": "1",
            "jcs": "1-2"
          },
          {
            "kcmc": "无效超大周范围课程",
            "zcd": "1-1000周",
            "xqj": "1",
            "jcs": "1-2"
          }
        ],
        "sjkList": []
      }
      ''';

      final timetable = AcademicTimetableJsonParser.parse(source);

      expect(timetable.metas, hasLength(1));
      expect(timetable.schedules, hasLength(1));

      final meta = timetable.metas.single;
      final schedule = timetable.schedules.single;
      expect(meta.name, '边界有效课程');
      expect(schedule.courseMetaId, meta.id);
      expect(schedule.dayOfWeek, 7);
      expect(schedule.startSection, 15);
      expect(schedule.endSection, 16);
      expect(schedule.weeks, <int>[24]);
    });
  });
}
