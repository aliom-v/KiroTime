import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/features/courses/data/course_meta.dart';
import 'package:kiro_time/features/courses/data/course_schedule.dart';
import 'package:kiro_time/features/import/domain/academic_timetable_api_probe.dart';
import 'package:kiro_time/features/import/domain/academic_timetable_html_parser.dart';

void main() {
  group('AcademicTimetableApiProbe.buildCandidatePaths', () {
    test('keeps configured path first and deduplicates candidates', () {
      final candidates = AcademicTimetableApiProbe.buildCandidatePaths(
        configuredPath: '/kbcx/xskbcx_cxXsKb.html',
        currentUrl:
            'https://example.edu.cn/kbcx/xskbcxMobile_cxXskbcxIndex.html',
        pageText: '''
          var url = "/kbcx/xskbcx_cxXsKb.html";
          \$.post('/kbcx/xskbcxMobile_cxXsKb.html');
        ''',
      );

      expect(candidates.first, '/kbcx/xskbcx_cxXsKb.html');
      expect(candidates, contains('/kbcx/xskbcxMobile_cxXsKb.html'));
      expect(candidates.toSet(), hasLength(candidates.length));
    });

    test('derives likely timetable JSON paths from current mobile page', () {
      final candidates = AcademicTimetableApiProbe.buildCandidatePaths(
        configuredPath: '',
        currentUrl:
            'https://example.edu.cn/kbcx/xskbcxMobile_cxXskbcxIndex.html',
        pageText: '',
      );

      expect(candidates, contains('/kbcx/xskbcxMobile_cxXsKb.html'));
      expect(candidates, contains('/kbcx/xskbcx_cxXsKb.html'));
    });

    test('extracts timetable-like paths from script text', () {
      final candidates = AcademicTimetableApiProbe.buildCandidatePaths(
        configuredPath: '',
        currentUrl: 'https://example.edu.cn/kbcx/index.html',
        pageText: '''
          fetch(window._path + '/kbcx/xskbcx_cxXsKb.html');
          var other = "/kbcx/ignoredOther.html";
          var mobile = '/kbcx/xskbcxMobile_cxXsKb.html';
        ''',
      );

      expect(candidates, contains('/kbcx/xskbcx_cxXsKb.html'));
      expect(candidates, contains('/kbcx/xskbcxMobile_cxXsKb.html'));
      expect(candidates, isNot(contains('/kbcx/ignoredOther.html')));
    });
  });

  group('ImportPreviewSummary.fromTimetable', () {
    test('marks crowded same-week same-slot schedules as suspicious', () {
      final timetable = ImportedTimetable(
        metas: <CourseMeta>[
          for (var index = 1; index <= 5; index++)
            CourseMeta.create(
              id: 'meta-$index',
              name: '课程$index',
              teacher: '教师$index',
            ),
        ],
        schedules: <CourseSchedule>[
          for (var index = 1; index <= 5; index++)
            CourseSchedule.create(
              id: 'schedule-$index',
              courseMetaId: 'meta-$index',
              classroom: '教室$index',
              dayOfWeek: 1,
              startSection: 1,
              endSection: 2,
              weeks: const <int>[1, 2, 3],
            ),
        ],
      );

      final summary = ImportPreviewSummary.fromTimetable(timetable);

      expect(summary.courseCount, 5);
      expect(summary.scheduleCount, 5);
      expect(summary.isSuspicious, isTrue);
      expect(
        summary.crowdedSlots.any(
          (slot) =>
              slot.dayOfWeek == 1 &&
              slot.startSection == 1 &&
              slot.endSection == 2 &&
              slot.week == 1 &&
              slot.count == 5,
        ),
        isTrue,
      );
    });

    test('does not flag same-slot courses when weeks do not overlap', () {
      final timetable = ImportedTimetable(
        metas: <CourseMeta>[
          for (var index = 1; index <= 4; index++)
            CourseMeta.create(
              id: 'meta-$index',
              name: '课程$index',
              teacher: '教师$index',
            ),
        ],
        schedules: <CourseSchedule>[
          for (var index = 1; index <= 4; index++)
            CourseSchedule.create(
              id: 'schedule-$index',
              courseMetaId: 'meta-$index',
              classroom: '教室$index',
              dayOfWeek: 2,
              startSection: 9,
              endSection: 10,
              weeks: <int>[index],
            ),
        ],
      );

      final summary = ImportPreviewSummary.fromTimetable(timetable);

      expect(summary.courseCount, 4);
      expect(summary.scheduleCount, 4);
      expect(summary.isSuspicious, isFalse);
      expect(summary.crowdedSlots, isEmpty);
    });

    test('does not flag normal two-course conflict as suspicious', () {
      final timetable = ImportedTimetable(
        metas: <CourseMeta>[
          CourseMeta.create(id: 'meta-a', name: '课程A', teacher: '教师A'),
          CourseMeta.create(id: 'meta-b', name: '课程B', teacher: '教师B'),
        ],
        schedules: <CourseSchedule>[
          CourseSchedule.create(
            id: 'schedule-a',
            courseMetaId: 'meta-a',
            classroom: '教室A',
            dayOfWeek: 3,
            startSection: 5,
            endSection: 6,
            weeks: const <int>[1, 2, 3],
          ),
          CourseSchedule.create(
            id: 'schedule-b',
            courseMetaId: 'meta-b',
            classroom: '教室B',
            dayOfWeek: 3,
            startSection: 5,
            endSection: 6,
            weeks: const <int>[4, 5],
          ),
        ],
      );

      final summary = ImportPreviewSummary.fromTimetable(timetable);

      expect(summary.courseCount, 2);
      expect(summary.scheduleCount, 2);
      expect(summary.isSuspicious, isFalse);
      expect(summary.crowdedSlots, isEmpty);
    });
  });

  group('AcademicTimetableApiProbe.selectBestCandidate', () {
    test('prefers a later candidate with more parsed schedules', () {
      final first = _candidate(path: '/first', scheduleCount: 1);
      final fuller = _candidate(path: '/fuller', scheduleCount: 3);

      final selected = AcademicTimetableApiProbe.selectBestCandidate(
        <TimetableProbeCandidate>[first, fuller],
      );

      expect(selected, same(fuller));
    });

    test('prefers a non-suspicious candidate over a crowded result', () {
      final crowded = _candidate(
        path: '/crowded',
        scheduleCount: 5,
        crowded: true,
      );
      final safe = _candidate(path: '/safe', scheduleCount: 2);

      final selected = AcademicTimetableApiProbe.selectBestCandidate(
        <TimetableProbeCandidate>[crowded, safe],
      );

      expect(selected, same(safe));
    });

    test('uses course count after schedule count', () {
      final sharedMeta = _candidate(
        path: '/shared-meta',
        scheduleCount: 3,
        courseCount: 1,
      );
      final richerMeta = _candidate(
        path: '/richer-meta',
        scheduleCount: 3,
        courseCount: 2,
      );

      final selected = AcademicTimetableApiProbe.selectBestCandidate(
        <TimetableProbeCandidate>[sharedMeta, richerMeta],
      );

      expect(selected, same(richerMeta));
    });

    test('preserves discovery order when candidate quality is equal', () {
      final first = _candidate(path: '/first', scheduleCount: 2);
      final second = _candidate(path: '/second', scheduleCount: 2);

      final selected = AcademicTimetableApiProbe.selectBestCandidate(
        <TimetableProbeCandidate>[first, second],
      );

      expect(selected, same(first));
    });
  });
}

TimetableProbeCandidate _candidate({
  required String path,
  required int scheduleCount,
  int? courseCount,
  bool crowded = false,
}) {
  final resolvedCourseCount = courseCount ?? scheduleCount;
  final metas = <CourseMeta>[
    for (var index = 0; index < resolvedCourseCount; index++)
      CourseMeta.create(
        id: '$path-meta-$index',
        name: '$path-course-$index',
        teacher: '$path-teacher-$index',
      ),
  ];
  final schedules = <CourseSchedule>[
    for (var index = 0; index < scheduleCount; index++)
      CourseSchedule.create(
        id: '$path-schedule-$index',
        courseMetaId: metas[index % metas.length].id,
        classroom: '$path-room-$index',
        dayOfWeek: crowded ? 1 : index % 7 + 1,
        startSection: crowded ? 1 : index % 8 + 1,
        endSection: crowded ? 2 : index % 8 + 2,
        weeks: crowded ? const <int>[1] : <int>[index + 1],
      ),
  ];
  return TimetableProbeCandidate(
    path: path,
    timetable: ImportedTimetable(metas: metas, schedules: schedules),
  );
}
