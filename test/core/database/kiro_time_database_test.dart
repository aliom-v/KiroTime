import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:kiro_time/core/database/isar_database.dart';
import 'package:kiro_time/features/courses/data/course_meta.dart';
import 'package:kiro_time/features/courses/data/course_schedule.dart';
import 'package:kiro_time/features/courses/data/course_schedule_edit.dart';
import 'package:kiro_time/features/timetable/data/semester_record.dart';
import 'package:kiro_time/features/timetable/domain/semester_settings.dart';
import 'package:kiro_time/features/timetable/domain/section_time_settings.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(
      libraries: <Abi, String>{
        Abi.current(): 'third_party/isar_flutter_libs/linux/libisar.so',
      },
    );
  });

  late Directory tempDir;
  late Isar isar;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kiro_time_test_');
    isar = await Isar.open(
      KiroTimeDatabase.schemas,
      directory: tempDir.path,
      name: 'kiro_time_test',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('KiroTimeDatabase semester persistence', () {
    test('round-trips app settings by key', () async {
      await KiroTimeDatabase.saveAppSetting(
        isar,
        key: 'appearance',
        value: '{"showWeekend":false}',
      );
      await KiroTimeDatabase.saveAppSetting(
        isar,
        key: 'import_preferences',
        value: '{"userAgentMode":"desktop"}',
      );

      expect(
        await KiroTimeDatabase.readAppSetting(isar, key: 'appearance'),
        '{"showWeekend":false}',
      );
      expect(
        await KiroTimeDatabase.listAppSettings(isar),
        containsPair('import_preferences', '{"userAgentMode":"desktop"}'),
      );
    });

    test('round-trips semesters and selected semester id', () async {
      final fallback = SemesterSettings(
        id: '2025-2',
        schoolYearStart: 2025,
        semester: 2,
        semesterStart: DateTime(2026, 3, 2),
        totalWeeks: 20,
        sectionCount: 10,
      );
      final next = SemesterSettings(
        id: '2026-1',
        schoolYearStart: 2026,
        semester: 1,
        semesterStart: DateTime(2026, 8, 31),
        totalWeeks: 19,
        sectionCount: 12,
      );

      await KiroTimeDatabase.ensureSemesterState(isar, fallback: fallback);
      await KiroTimeDatabase.upsertSemester(isar, next);
      await KiroTimeDatabase.saveSelectedSemesterId(isar, next.id);

      final state = await KiroTimeDatabase.ensureSemesterState(
        isar,
        fallback: fallback,
      );

      expect(state.selectedSemesterId, next.id);
      expect(
        state.semesters.map((SemesterSettings settings) => settings.id),
        containsAll(<String>[fallback.id, next.id]),
      );
      expect(
        state.semesters
            .singleWhere((SemesterSettings settings) => settings.id == next.id)
            .sectionCount,
        12,
      );
    });

    test('round-trips custom display name', () async {
      final semester = SemesterSettings(
        id: '2026-1',
        schoolYearStart: 2026,
        semester: 1,
        semesterStart: DateTime(2026, 8, 31),
        totalWeeks: 19,
        sectionCount: 10,
        displayName: '大三上',
      );

      await KiroTimeDatabase.upsertSemester(isar, semester);

      final semesters = await KiroTimeDatabase.listSemesters(isar);

      expect(semesters.single.displayName, '大三上');
      expect(semesters.single.label, '大三上');
    });

    test('round-trips per-semester section times', () async {
      final semester = SemesterSettings(
        id: '2026-1',
        schoolYearStart: 2026,
        semester: 1,
        semesterStart: DateTime(2026, 8, 31),
        totalWeeks: 19,
        sectionCount: 10,
        sectionTimeSettings: SectionTimeSettings.defaultForSectionCount(10)
            .replaceSection(
              const SectionTime(
                section: 1,
                startMinutes: 7 * 60,
                endMinutes: 465,
              ),
            ),
      );

      await KiroTimeDatabase.upsertSemester(isar, semester);

      final saved = (await KiroTimeDatabase.listSemesters(isar)).single;

      expect(saved.sectionTimeSettings.section(1).timeRangeText, '07:00-07:45');
      expect(saved.sectionTimeSettings.section(2).timeRangeText, '09:05-09:50');
    });

    test('loads default section times for legacy semester records', () async {
      await isar.writeTxn(() async {
        await isar.semesterRecords.put(
          SemesterRecord()
            ..id = '2026-1'
            ..schoolYearStart = 2026
            ..semester = 1
            ..semesterStart = DateTime(2026, 8, 31)
            ..totalWeeks = 19
            ..sectionCount = 10
            ..displayName = ''
            ..sectionTimesJson = '',
        );
      });

      final saved = (await KiroTimeDatabase.listSemesters(isar)).single;

      expect(saved.sectionTimeSettings.section(1).timeRangeText, '08:10-08:55');
      expect(saved.sectionTimeSettings.sections, hasLength(10));
    });

    test('initial semester setup does not create mock courses', () async {
      final fallback = SemesterSettings(
        id: '2026-1',
        schoolYearStart: 2026,
        semester: 1,
        semesterStart: DateTime(2026, 8, 31),
        totalWeeks: 19,
      );

      await KiroTimeDatabase.ensureSemesterState(isar, fallback: fallback);

      expect(await isar.courseMetas.count(), 0);
      expect(await isar.courseSchedules.count(), 0);
    });

    test(
      'clears all local data and recreates a blank fallback semester',
      () async {
        final oldSemester = SemesterSettings(
          id: '2026-1',
          schoolYearStart: 2026,
          semester: 1,
          semesterStart: DateTime(2026, 8, 31),
          totalWeeks: 19,
        );
        final fallback = SemesterSettings(
          id: '2026-2',
          schoolYearStart: 2026,
          semester: 2,
          semesterStart: DateTime(2027, 3, 1),
          totalWeeks: 20,
        );
        await KiroTimeDatabase.upsertSemester(isar, oldSemester);
        await KiroTimeDatabase.saveAppSetting(
          isar,
          key: 'appearance',
          value: '{"showWeekend":false}',
        );
        await KiroTimeDatabase.replaceWithImportedData(
          isar,
          semesterId: oldSemester.id,
          metas: <CourseMeta>[
            CourseMeta.create(id: 'meta-a', name: 'A', teacher: 'Teacher A'),
          ],
          schedules: <CourseSchedule>[
            CourseSchedule.create(
              id: 'schedule-a',
              courseMetaId: 'meta-a',
              classroom: 'Room A',
              dayOfWeek: 1,
              startSection: 1,
              endSection: 2,
              weeks: <int>[1],
            ),
          ],
        );

        final cleared = await KiroTimeDatabase.clearAllData(
          isar,
          fallback: fallback,
        );

        expect(cleared.id, fallback.id);
        expect(await isar.courseMetas.count(), 0);
        expect(await isar.courseSchedules.count(), 0);
        expect(
          (await KiroTimeDatabase.listSemesters(isar)).map((item) => item.id),
          <String>[fallback.id],
        );
        expect(
          await KiroTimeDatabase.readSelectedSemesterId(isar),
          fallback.id,
        );
        expect(
          await KiroTimeDatabase.readAppSetting(isar, key: 'appearance'),
          isNull,
        );
      },
    );
  });

  group('KiroTimeDatabase semester course scope', () {
    test(
      'replacing one semester leaves other semester schedules intact',
      () async {
        await KiroTimeDatabase.replaceWithImportedData(
          isar,
          semesterId: '2025-2',
          metas: <CourseMeta>[
            CourseMeta.create(id: 'meta-a', name: 'A', teacher: 'Teacher A'),
          ],
          schedules: <CourseSchedule>[
            CourseSchedule.create(
              id: 'schedule-a',
              courseMetaId: 'meta-a',
              classroom: 'Room A',
              dayOfWeek: 1,
              startSection: 1,
              endSection: 2,
              weeks: <int>[1],
            ),
          ],
        );
        await KiroTimeDatabase.replaceWithImportedData(
          isar,
          semesterId: '2026-1',
          metas: <CourseMeta>[
            CourseMeta.create(id: 'meta-b', name: 'B', teacher: 'Teacher B'),
          ],
          schedules: <CourseSchedule>[
            CourseSchedule.create(
              id: 'schedule-b',
              courseMetaId: 'meta-b',
              classroom: 'Room B',
              dayOfWeek: 2,
              startSection: 3,
              endSection: 4,
              weeks: <int>[2],
            ),
          ],
        );

        final semesterA = await KiroTimeDatabase.findSchedulesForSemester(
          isar,
          '2025-2',
        );
        final semesterB = await KiroTimeDatabase.findSchedulesForSemester(
          isar,
          '2026-1',
        );

        expect(
          semesterA.map((CourseSchedule schedule) => schedule.id),
          <String>['schedule-a'],
        );
        expect(
          semesterB.map((CourseSchedule schedule) => schedule.id),
          <String>['schedule-b'],
        );
      },
    );

    test(
      'creates a schedule in the selected semester with teaching class',
      () async {
        const edit = CourseScheduleEdit(
          courseMetaId: '',
          scheduleId: '',
          name: '软件工程',
          teacher: '王老师',
          teachingClass: '软工2301',
          classroom: '南校区 1#101',
          dayOfWeek: 2,
          startSection: 3,
          endSection: 4,
          weeks: <int>[1, 2, 3],
        );

        final created = await KiroTimeDatabase.createScheduleAndMeta(
          isar,
          semesterId: '2026-1',
          edit: edit,
        );
        final meta = await isar.courseMetas
            .where()
            .idEqualTo(created.courseMetaId)
            .findFirst();

        expect(created.semesterId, '2026-1');
        expect(created.classroom, '南校区 1#101');
        expect(meta?.name, '软件工程');
        expect(meta?.teacher, '王老师');
        expect(meta?.teachingClass, '软工2301');
      },
    );

    test('updates teaching class when editing a schedule', () async {
      await isar.writeTxn(() async {
        await isar.courseMetas.put(
          CourseMeta.create(
            id: 'meta-a',
            name: 'A',
            teacher: 'Teacher A',
            teachingClass: '旧班级',
          ),
        );
        await isar.courseSchedules.put(
          CourseSchedule.create(
            id: 'schedule-a',
            courseMetaId: 'meta-a',
            classroom: 'Room A',
            dayOfWeek: 1,
            startSection: 1,
            endSection: 2,
            weeks: <int>[1],
            semesterId: '2026-1',
          ),
        );
      });

      await KiroTimeDatabase.updateScheduleAndMeta(
        isar,
        edit: const CourseScheduleEdit(
          courseMetaId: 'meta-a',
          scheduleId: 'schedule-a',
          name: 'A+',
          teacher: 'Teacher B',
          teachingClass: '新班级',
          classroom: 'Room B',
          dayOfWeek: 3,
          startSection: 5,
          endSection: 6,
          weeks: <int>[4, 5],
        ),
      );

      final meta = await isar.courseMetas
          .where()
          .idEqualTo('meta-a')
          .findFirst();
      final schedule = await isar.courseSchedules
          .where()
          .idEqualTo('schedule-a')
          .findFirst();

      expect(meta?.teachingClass, '新班级');
      expect(schedule?.classroom, 'Room B');
      expect(schedule?.semesterId, '2026-1');
    });

    test('deletes one schedule and cleans orphan meta', () async {
      await isar.writeTxn(() async {
        await isar.courseMetas.put(
          CourseMeta.create(id: 'meta-a', name: 'A', teacher: 'Teacher A'),
        );
        await isar.courseSchedules.put(
          CourseSchedule.create(
            id: 'schedule-a',
            courseMetaId: 'meta-a',
            classroom: 'Room A',
            dayOfWeek: 1,
            startSection: 1,
            endSection: 2,
            weeks: <int>[1],
            semesterId: '2026-1',
          ),
        );
      });

      await KiroTimeDatabase.deleteSchedule(isar, scheduleId: 'schedule-a');

      expect(await isar.courseSchedules.count(), 0);
      expect(await isar.courseMetas.count(), 0);
    });

    test('copies a schedule into another semester', () async {
      await isar.writeTxn(() async {
        await isar.courseMetas.put(
          CourseMeta.create(
            id: 'meta-a',
            name: 'A',
            teacher: 'Teacher A',
            teachingClass: '软工2301',
          ),
        );
        await isar.courseSchedules.put(
          CourseSchedule.create(
            id: 'schedule-a',
            courseMetaId: 'meta-a',
            classroom: 'Room A',
            dayOfWeek: 1,
            startSection: 1,
            endSection: 2,
            weeks: <int>[1],
            semesterId: '2026-1',
          ),
        );
      });

      final copied = await KiroTimeDatabase.copyScheduleToSemester(
        isar,
        scheduleId: 'schedule-a',
        targetSemesterId: '2026-2',
      );

      expect(copied.id, isNot('schedule-a'));
      expect(copied.courseMetaId, isNot('meta-a'));
      expect(copied.semesterId, '2026-2');
      expect(await isar.courseSchedules.count(), 2);
      final copiedMeta = await isar.courseMetas
          .where()
          .idEqualTo(copied.courseMetaId)
          .findFirst();
      expect(copiedMeta?.name, 'A');
      expect(copiedMeta?.teacher, 'Teacher A');
      expect(copiedMeta?.teachingClass, '软工2301');
    });

    test(
      'deletes a semester with schedules and blocks deleting the last one',
      () async {
        final first = SemesterSettings(
          id: '2026-1',
          schoolYearStart: 2026,
          semester: 1,
          semesterStart: DateTime(2026, 8, 31),
          totalWeeks: 19,
        );
        final second = first.copyWith(id: '2026-2', semester: 2);
        await KiroTimeDatabase.upsertSemester(isar, first);
        await KiroTimeDatabase.upsertSemester(isar, second);
        await KiroTimeDatabase.saveSelectedSemesterId(isar, first.id);
        await KiroTimeDatabase.replaceWithImportedData(
          isar,
          semesterId: second.id,
          metas: <CourseMeta>[
            CourseMeta.create(id: 'meta-b', name: 'B', teacher: 'Teacher B'),
          ],
          schedules: <CourseSchedule>[
            CourseSchedule.create(
              id: 'schedule-b',
              courseMetaId: 'meta-b',
              classroom: 'Room B',
              dayOfWeek: 1,
              startSection: 1,
              endSection: 2,
              weeks: <int>[1],
            ),
          ],
        );

        final selected = await KiroTimeDatabase.deleteSemester(
          isar,
          semesterId: first.id,
        );

        expect(selected, second.id);
        expect(await KiroTimeDatabase.readSelectedSemesterId(isar), second.id);
        expect(
          (await KiroTimeDatabase.listSemesters(isar)).map((item) => item.id),
          <String>[second.id],
        );

        expect(
          () => KiroTimeDatabase.deleteSemester(isar, semesterId: second.id),
          throwsStateError,
        );
      },
    );

    test(
      'imports schedules into a newly created semester without replacing existing data',
      () async {
        final existing = SemesterSettings(
          id: '2026-1',
          schoolYearStart: 2026,
          semester: 1,
          semesterStart: DateTime(2026, 8, 31),
          totalWeeks: 19,
        );
        final importedSettings = existing.copyWith(displayName: '导入备份');
        await KiroTimeDatabase.upsertSemester(isar, existing);
        await KiroTimeDatabase.saveSelectedSemesterId(isar, existing.id);
        await KiroTimeDatabase.replaceWithImportedData(
          isar,
          semesterId: existing.id,
          metas: <CourseMeta>[
            CourseMeta.create(
              id: 'meta-existing',
              name: 'Existing',
              teacher: 'T',
            ),
          ],
          schedules: <CourseSchedule>[
            CourseSchedule.create(
              id: 'schedule-existing',
              courseMetaId: 'meta-existing',
              classroom: 'Room Existing',
              dayOfWeek: 1,
              startSection: 1,
              endSection: 2,
              weeks: <int>[1],
            ),
          ],
        );

        final created = await KiroTimeDatabase.importSemesterAsNew(
          isar,
          baseSemester: importedSettings,
          metas: <CourseMeta>[
            CourseMeta.create(
              id: 'meta-existing',
              name: 'Imported',
              teacher: 'Imported T',
              teachingClass: 'Imported Class',
            ),
          ],
          schedules: <CourseSchedule>[
            CourseSchedule.create(
              id: 'schedule-existing',
              courseMetaId: 'meta-existing',
              classroom: 'Room Imported',
              dayOfWeek: 2,
              startSection: 3,
              endSection: 4,
              weeks: <int>[2, 3],
              semesterId: importedSettings.id,
            ),
          ],
        );

        expect(created.id, '2026-1-2');
        expect(await KiroTimeDatabase.readSelectedSemesterId(isar), created.id);
        expect(await isar.courseSchedules.count(), 2);

        final existingSchedules =
            await KiroTimeDatabase.findSchedulesForSemester(isar, existing.id);
        expect(existingSchedules.single.id, 'schedule-existing');
        expect(existingSchedules.single.courseMetaId, 'meta-existing');

        final importedSchedules =
            await KiroTimeDatabase.findSchedulesForSemester(isar, created.id);
        expect(importedSchedules.single.id, isNot('schedule-existing'));
        expect(importedSchedules.single.courseMetaId, isNot('meta-existing'));
        expect(importedSchedules.single.semesterId, created.id);
        expect(importedSchedules.single.classroom, 'Room Imported');

        final importedMeta = await isar.courseMetas
            .where()
            .idEqualTo(importedSchedules.single.courseMetaId)
            .findFirst();
        expect(importedMeta?.name, 'Imported');
        expect(importedMeta?.teachingClass, 'Imported Class');
      },
    );
  });
}
