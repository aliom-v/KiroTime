import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_time/core/database/mock_course_seed.dart';
import 'package:kiro_time/features/courses/data/course_meta.dart';
import 'package:kiro_time/features/courses/data/course_schedule.dart';
import 'package:kiro_time/features/timetable/domain/timetable_layout.dart';

void main() {
  group('TimetableLayout.filterSchedulesForWeek', () {
    test(
      'keeps only schedules whose explicit weeks contain the current week',
      () {
        final weekSixSchedules = TimetableLayout.filterSchedulesForWeek(
          MockCourseSeed.schedules,
          6,
        );

        expect(
          weekSixSchedules.map((CourseSchedule schedule) => schedule.id),
          containsAll(<String>[
            'schedule-db-1',
            'schedule-db-2',
            'schedule-english-1',
            'schedule-physics-1',
          ]),
        );
        expect(
          weekSixSchedules.map((CourseSchedule schedule) => schedule.id),
          isNot(contains('schedule-os-1')),
        );
      },
    );
  });

  group('TimetableLayout.buildPlacements', () {
    test('keeps one course with multiple schedules as multiple placements', () {
      final weekOneSchedules = TimetableLayout.filterSchedulesForWeek(
        MockCourseSeed.schedules,
        1,
      );

      final placements = TimetableLayout.buildPlacements(
        schedules: weekOneSchedules,
        courseMetas: MockCourseSeed.metas,
      );

      expect(
        placements
            .where((placement) => placement.courseMeta.id == 'course-db')
            .map((placement) => placement.schedule.id),
        <String>['schedule-db-2'],
      );
    });

    test('assigns separate lanes to overlapping schedules on the same day', () {
      final courseMetas = <CourseMeta>[
        CourseMeta.create(id: 'meta-a', name: 'A', teacher: 'Teacher A'),
        CourseMeta.create(id: 'meta-b', name: 'B', teacher: 'Teacher B'),
        CourseMeta.create(id: 'meta-c', name: 'C', teacher: 'Teacher C'),
      ];
      final schedules = <CourseSchedule>[
        CourseSchedule.create(
          id: 'a',
          courseMetaId: 'meta-a',
          classroom: 'Room A',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1],
        ),
        CourseSchedule.create(
          id: 'b',
          courseMetaId: 'meta-b',
          classroom: 'Room B',
          dayOfWeek: 1,
          startSection: 2,
          endSection: 3,
          weeks: <int>[1],
        ),
        CourseSchedule.create(
          id: 'c',
          courseMetaId: 'meta-c',
          classroom: 'Room C',
          dayOfWeek: 1,
          startSection: 4,
          endSection: 5,
          weeks: <int>[1],
        ),
      ];

      final placements = TimetableLayout.buildPlacements(
        schedules: schedules,
        courseMetas: courseMetas,
      );

      final placementA = placements.singleWhere(
        (placement) => placement.schedule.id == 'a',
      );
      final placementB = placements.singleWhere(
        (placement) => placement.schedule.id == 'b',
      );
      final placementC = placements.singleWhere(
        (placement) => placement.schedule.id == 'c',
      );

      expect(placementA.laneCount, 2);
      expect(placementB.laneCount, 2);
      expect(placementA.laneIndex, isNot(placementB.laneIndex));
      expect(placementC.laneCount, 1);
      expect(placementC.laneIndex, 0);
    });

    test('builds one normal visible item for a single visible course', () {
      final courseMetas = <CourseMeta>[
        CourseMeta.create(id: 'meta-a', name: 'A', teacher: 'Teacher A'),
      ];
      final schedules = <CourseSchedule>[
        CourseSchedule.create(
          id: 'a',
          courseMetaId: 'meta-a',
          classroom: 'Room A',
          dayOfWeek: 1,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1],
        ),
      ];

      final items = TimetableLayout.buildVisibleItems(
        schedules: schedules,
        courseMetas: courseMetas,
      );

      expect(items, hasLength(1));
      expect(items.single.isConflict, isFalse);
      expect(items.single.placements.single.schedule.id, 'a');
      expect(items.single.dayColumn, 0);
      expect(items.single.startSlot, 0);
      expect(items.single.slotSpan, 2);
    });

    test(
      'builds a conflict visible item for overlapping current-week courses',
      () {
        final courseMetas = <CourseMeta>[
          CourseMeta.create(id: 'meta-a', name: 'A', teacher: 'Teacher A'),
          CourseMeta.create(id: 'meta-b', name: 'B', teacher: 'Teacher B'),
        ];
        final schedules = <CourseSchedule>[
          CourseSchedule.create(
            id: 'a',
            courseMetaId: 'meta-a',
            classroom: 'Room A',
            dayOfWeek: 3,
            startSection: 1,
            endSection: 4,
            weeks: <int>[10],
          ),
          CourseSchedule.create(
            id: 'b',
            courseMetaId: 'meta-b',
            classroom: 'Room B',
            dayOfWeek: 3,
            startSection: 3,
            endSection: 4,
            weeks: <int>[10],
          ),
        ];

        final visibleSchedules = TimetableLayout.filterSchedulesForWeek(
          schedules,
          10,
        );
        final items = TimetableLayout.buildVisibleItems(
          schedules: visibleSchedules,
          courseMetas: courseMetas,
        );

        expect(items, hasLength(1));
        expect(items.single.isConflict, isTrue);
        expect(
          items.single.placements.map((placement) => placement.schedule.id),
          <String>['a', 'b'],
        );
        expect(items.single.dayColumn, 2);
        expect(items.single.startSlot, 0);
        expect(items.single.slotSpan, 4);
      },
    );

    test('does not conflict schedules in the same slot on different weeks', () {
      final courseMetas = <CourseMeta>[
        CourseMeta.create(id: 'meta-a', name: 'A', teacher: 'Teacher A'),
        CourseMeta.create(id: 'meta-b', name: 'B', teacher: 'Teacher B'),
      ];
      final schedules = <CourseSchedule>[
        CourseSchedule.create(
          id: 'a',
          courseMetaId: 'meta-a',
          classroom: 'Room A',
          dayOfWeek: 4,
          startSection: 1,
          endSection: 2,
          weeks: <int>[1, 2, 3],
        ),
        CourseSchedule.create(
          id: 'b',
          courseMetaId: 'meta-b',
          classroom: 'Room B',
          dayOfWeek: 4,
          startSection: 1,
          endSection: 2,
          weeks: <int>[10, 11, 12],
        ),
      ];

      final visibleSchedules = TimetableLayout.filterSchedulesForWeek(
        schedules,
        10,
      );
      final items = TimetableLayout.buildVisibleItems(
        schedules: visibleSchedules,
        courseMetas: courseMetas,
      );

      expect(items, hasLength(1));
      expect(items.single.isConflict, isFalse);
      expect(items.single.placements.single.schedule.id, 'b');
    });
  });
}
